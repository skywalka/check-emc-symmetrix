#!/usr/bin/ksh
# *
# *  Script Name      : EMCsg.ksh
# *  Author           : Chad Singleton
# *  Creation Date    : 22-Dec-2009
# *
# *  Info             : Reports on all storage groups and the devices
# *                     contained within
# *
# * Displayed format is compatible for splunk injestion
# *
# ***************************************************************************
# *             M O D I F I C A T I O N    H I S T O R Y                    *
# ***************************************************************************
# *  DATE        | Author          | Ver   | Description                    *
# ***************************************************************************
# * 03-Aug-2011    Chad Singleton    2011080300     Created
# ###########################################################################
# Version: 2011080300
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt

#############################################################################
#############################################################################
##
##   Variables
##
#############################################################################
#############################################################################

#############################################################################
#    GLOBAL
#############################################################################

PROGRAM=${0##*/}
EXECDIR=${0%/*}
HOST=`uname -n`

ER_SEQUENCE=$1
EN_CLASS=$2
EN_TYPE=$3

LOGDATE=`date +%Y-%m-%d`
LOGTIME='date +%H:%M:%S'

INFO=0
WARNING=1
CRITICAL=2

DISKGROUP=0
VIRTUALPOOL=1

NAGIOS_EXE=/usr/local/nagios/bin/send_nsca
NAGIOS_CFG=/usr/local/nagios/etc/send_nsca.cfg
NAGIOS_HOST=nagios.ce.corp
NAGIOS_PORT=5667

MAILTO="chad.singleton@ce.com.au"
MAILCC=

# Handle being run from PATH when in the current directory. $0 doesn't have a /
if [ $EXECDIR = $PROGRAM ]; then
    EXECDIR="."
fi

BASENAME=${PROGRAM%%.*}
PREFIX=${BASENAME%%_*}

#############################################################################
##
##   Subroutines
##
#############################################################################


#############################################################################
#
#    logger()
#
#  This will format and echo the string based on the severity
#
#############################################################################

logger()
{

    case $1 in
        $INFO)
            shift
            echo "$HOST ${LOGDATE} `${LOGTIME}` INFO: $*"
        ;;
        $WARNING)
            shift
            echo "$HOST ${LOGDATE} `${LOGTIME}` WARN: $*"
        ;;
        $CRITICAL)
            shift
            echo "$HOST ${LOGDATE} `${LOGTIME}` CRIT: $*"
        ;;
    esac

}

#############################################################################
#
#    die()
#
#  This will stop the execution of the script and record the exit code
#
#############################################################################

die()
{

    EXITRC=${1:?};
    shift
    EXITMSG=$*

    case $EXITRC in
        $CRITICAL)
            mail -s "$HOST ${LOGDATE} `${LOGTIME}` - FAILED" -c "${MAILCC}" "${MAILTO}" < ${LOGFILE}
            ;;
    esac

    exit $EXITRC

}

#############################################################################
##
##   Main
##
#############################################################################

for SID in 0041 0042
do

    LOGFILE=/var/log/EMCsg_${SID}.${LOGDATE}.log
    exec >> ${LOGFILE} 2>&1
    # Gay splunk requirement
    echo "device,storage_group"

    # Ensure the Nagios server is available
    ping -c 1 -w 2 $NAGIOS_HOST > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        die $CRITICAL "$NAGIOS_HOST not PINGable"
    fi

    # Based on the severity, send an alert
    if [ -x $NAGIOS_EXE ]
    then
        if [ -f $NAGIOS_CFG ]
        then
            for SG in `/usr/symcli/bin/symsg -sid $SID list -v |grep Name: | awk '{print $2}'`
            do
                for DEV in `/usr/symcli/bin/symsg -sid $SID show $SG | grep TDEV | awk '{print $1}'`
                do
                    META=`/usr/symcli/bin/symdev -sid $SID list 2>&1 | grep $DEV |awk '{print $8}' | grep -c M` 
                    if [ $META -eq 1 ]
                    then
                        print $DEV","$SG
                        for HYPER in `/usr/symcli/bin/symdev -sid $SID show $DEV |grep -p "Meta Device Members" |grep "N\/A" | grep -v "\-\-\>" | awk '{print $1}'`
                        do
                            print $HYPER","$SG
                        done
                    else
                        print $DEV","$SG
                    fi
                done
            done
        else
            die $CRITICAL "$NAGIOS_CFG not found"
        fi
    else
        die $CRITICAL "$NAGIOS_EXE not found or not executable"
    fi
done

# End the script gracefully
die $INFO "Ending \"$0 $*\" ..."
