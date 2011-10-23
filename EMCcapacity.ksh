#!/usr/bin/ksh

# *
# *  Script Name      : EMCcapacity.ksh
# *  Author           : Chad Singleton
# *  Creation Date    : 22-Dec-2009
# *
# *  Info             : Add all hypers and generate summary for cacti/monthly
# *                     report
# *
# * Displayed format is compatible for splunk injestion
# *
# ***************************************************************************
# *             M O D I F I C A T I O N    H I S T O R Y                    *
# ***************************************************************************
# *  DATE        | Author          | Ver   | Description                    *
# ***************************************************************************
# * 22-Dec-2009    Chad Singleton    2009122200     Created
# ###########################################################################
# Version: 2009122200
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
LOGFILE=/var/log/EMCcapacity.${LOGDATE}.log

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

exec >> ${LOGFILE} 2>&1

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
        for SID in 41 42 4785 4208
        do
            print -n ${LOGDATE} `${LOGTIME}` $HOST":"
            print -n SID=$SID" "

            #
            # Display mapped and unmapped VDEV capacity
            #
            MAPPEDCOUNT=0
            MAPPEDCAPACITY=0
            /usr/symcli/bin/symdev list -multiport -sid $SID 2>&1 | grep VDEV | while read ONE TWO THREE FOUR FIVE SIX SEVEN
            do
                let MAPPEDCOUNT='MAPPEDCOUNT+1'
                if [ -z "$SEVEN" ]
                then
                    let MAPPEDCAPACITY='MAPPEDCAPACITY+SIX'
                else
                    let MAPPEDCAPACITY='MAPPEDCAPACITY+SEVEN'
                fi
            done
            print -n VDEVMAPPEDCOUNT=$MAPPEDCOUNT" "VDEVMAPPEDCAPACITY=$MAPPEDCAPACITY" "

            UNMAPPEDCOUNT=0
            UNMAPPEDCAPACITY=0
            /usr/symcli/bin/symdev list -noport -sid $SID 2>&1 | grep VDEV | while read ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE TEN
            do
                let UNMAPPEDCOUNT='UNMAPPEDCOUNT+1'
                if [ -z "$TEN" ]
                then
                    let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+NINE'
                else
                    let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+TEN'
                fi
            done
            print -n VDEVUNMAPPEDCOUNT=$UNMAPPEDCOUNT" "VDEVUNMAPPEDCAPACITY=$UNMAPPEDCAPACITY" "

            #
            # Display mapped and unmapped TDEV capacity
            #
            MAPPEDCOUNT=0
            MAPPEDCAPACITY=0
            /usr/symcli/bin/symdev list -multiport -sid $SID 2>&1 | grep TDEV | while read ONE TWO THREE FOUR FIVE SIX SEVEN
            do
                let MAPPEDCOUNT='MAPPEDCOUNT+1'
                if [ -z "$SEVEN" ]
                then
                    let MAPPEDCAPACITY='MAPPEDCAPACITY+SIX'
                else
                    let MAPPEDCAPACITY='MAPPEDCAPACITY+SEVEN'
                fi
            done
            print -n TDEVMAPPEDCOUNT=$MAPPEDCOUNT" "TDEVMAPPEDCAPACITY=$MAPPEDCAPACITY" "

            UNMAPPEDCOUNT=0
            UNMAPPEDCAPACITY=0
            /usr/symcli/bin/symdev list -noport -sid $SID 2>&1 | grep TDEV | while read ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE TEN
            do
                let UNMAPPEDCOUNT='UNMAPPEDCOUNT+1'
                if [ -z "$TEN" ]
                then
                    let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+NINE'
                else
                    let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+TEN'
                fi
            done
            print -n TDEVUNMAPPEDCOUNT=$UNMAPPEDCOUNT" "TDEVUNMAPPEDCAPACITY=$UNMAPPEDCAPACITY" "

            #
            # Display total DRV capacity
            #
            DRVCOUNT=0
            DRVCAPACITY=0
            for DEV in `/usr/symcli/bin/symdev list -sid $SID -drv 2>&1 | grep DRV | awk '{print $9}'`
            do
                let DRVCOUNT='DRVCOUNT+1'
                let DRVCAPACITY='DRVCAPACITY+DEV'
            done 
            print -n DRVCOUNT=$DRVCOUNT" "DRVCAPACITY=$DRVCAPACITY" "
    
            #
            # Display total SAVEVOL capacity
            #
            SAVEVOLCOUNT=0
            SAVEVOLCAPACITY=0
            for DEV in `/usr/symcli/bin/symdev list -sid $SID -savedev 2>&1 | grep RAID | awk '{print $10}'`
            do
                let SAVEVOLCOUNT='SAVEVOLCOUNT+1'
                let SAVEVOLCAPACITY='SAVEVOLCAPACITY+DEV'
            done 
            for DEV in `/usr/symcli/bin/symdev list -sid $SID -savedev 2>&1 | grep Mir | awk '{print $11}'`
            do
                let SAVEVOLCOUNT='SAVEVOLCOUNT+1'
                let SAVEVOLCAPACITY='SAVEVOLCAPACITY+DEV'
            done 
            SAVEVOLUSED=`/usr/symcli/bin/symsnap monitor -sid $SID | tail -2 | grep MB | awk '{print $3}'`
            print -n SAVEVOLCOUNT=$SAVEVOLCOUNT" "SAVEVOLCAPACITY=$SAVEVOLCAPACITY" "SAVEVOLUSED=$SAVEVOLUSED" "

            #
            # Display total DATADEV capacity
            #
            DATADEVCOUNT=0
            DATADEVCAPACITY=0
            for DEV in `/usr/symcli/bin/symdev list -sid $SID -datadev 2>&1 | grep RAID | awk '{print $10}'`
            do
                let DATADEVCOUNT='DATADEVCOUNT+1'
                let DATADEVCAPACITY='DATADEVCAPACITY+DEV'
            done 
            print -n DATADEVCOUNT=$DATADEVCOUNT" "DATADEVCAPACITY=$DATADEVCAPACITY" "

            DATADEVCOUNT=0
            DATADEVCAPACITY=0
            for DEV in `/usr/symcli/bin/symdev list -sid $SID -datadev -nonpooled 2>&1 | grep RAID | awk '{print $10}'`
            do
                let DATADEVCOUNT='DATADEVCOUNT+1'
                let DATADEVCAPACITY='DATADEVCAPACITY+DEV'
            done 
            print -n NONPOOLEDDATADEVCOUNT=$DATADEVCOUNT" "NONPOOLEDDATADEVCAPACITY=$DATADEVCAPACITY" "

            #
            # Display capacity
            #
            for TIER in T1 T2 T3
            do
                DISKGROUP=99
                POOLNAME=BLANK
                case $TIER in
                    T1)
                        case $SID in
                            4208)
                                DISKGROUP=3
                                ;;
                            41 | 42)
                                POOLNAME=3RAID5_EFD
                                ;;
                        esac
                    ;;
                    T2)
                        case $SID in
                            4208 | 4785)
                                DISKGROUP=1
                                ;;
                            41 | 42)
                                POOLNAME=7RAID5_FC
                                ;;
                        esac
                    ;;
                    T3)
                        case $SID in
                            4208 | 4785)
                                DISKGROUP=2
                                ;;
                            41)
                                POOLNAME=6RAID6_SATA
                                ;;
                            42)
                                POOLNAME=14RAID6_SATA
                                ;;
                        esac
                    ;;
                esac
                MAPPEDCOUNT=0
                MAPPEDCAPACITY=0
                RDFMAPPEDCOUNT=0
                RDFMAPPEDCAPACITY=0
                /usr/symcli/bin/symdev list -multiport -sid $SID -disk_group $DISKGROUP 2>&1 | egrep "RAID|RDF" | while read ONE TWO THREE FOUR FIVE SIX SEVEN
                do
                    let MAPPEDCOUNT='MAPPEDCOUNT+1'
                    if [ -z "$SEVEN" ]
                    then
                        let MAPPEDCAPACITY='MAPPEDCAPACITY+SIX'
                        if [ $THREE = "RDF1+R-5" -o $THREE = "RDF2+R-5" ]
                        then
                            let RDFMAPPEDCOUNT='RDFMAPPEDCOUNT+1'
                            let RDFMAPPEDCAPACITY='RDFMAPPEDCAPACITY+SIX'
                        fi
                    else
                        let MAPPEDCAPACITY='MAPPEDCAPACITY+SEVEN'
                        if [ $THREE = "RDF1+R-5" -o $THREE = "RDF2+R-5" ]
                        then
                            let RDFMAPPEDCOUNT='RDFMAPPEDCOUNT+1'
                            let RDFMAPPEDCAPACITY='RDFMAPPEDCAPACITY+SEVEN'
                        fi
                    fi
                done
                print -n ${TIER}MAPPEDCOUNT=$MAPPEDCOUNT" "${TIER}MAPPEDCAPACITY=$MAPPEDCAPACITY" "${TIER}RDFMAPPEDCOUNT=$RDFMAPPEDCOUNT" "${TIER}RDFMAPPEDCAPACITY=$RDFMAPPEDCAPACITY" "

                UNMAPPEDCOUNT=0
                UNMAPPEDCAPACITY=0
                RDFUNMAPPEDCOUNT=0
                RDFUNMAPPEDCAPACITY=0
                /usr/symcli/bin/symdev list -noport -sid $SID -disk_group $DISKGROUP 2>&1 | egrep "RAID|RDF" | while read ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE TEN
                do
                    let UNMAPPEDCOUNT='UNMAPPEDCOUNT+1'
                    if [ -z "$TEN" ]
                    then
                        let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+NINE'
                        if [ $THREE = "RDF1+R-5" -o $THREE = "RDF2+R-5" ]
                        then
                            let RDFUNMAPPEDCOUNT='RDFUNMAPPEDCOUNT+1'
                            let RDFUNMAPPEDCAPACITY='RDFUNMAPPEDCAPACITY+NINE'
                        fi
                    else
                        let UNMAPPEDCAPACITY='UNMAPPEDCAPACITY+TEN'
                        if [ $THREE = "RDF1+R-5" -o $THREE = "RDF2+R-5" ]
                        then
                            let RDFUNMAPPEDCOUNT='RDFUNMAPPEDCOUNT+1'
                            let RDFUNMAPPEDCAPACITY='RDFUNMAPPEDCAPACITY+TEN'
                        fi
                    fi
                done
                print -n ${TIER}UNMAPPEDCOUNT=$UNMAPPEDCOUNT" "${TIER}UNMAPPEDCAPACITY=$UNMAPPEDCAPACITY" "${TIER}RDFUNMAPPEDCOUNT=$RDFUNMAPPEDCOUNT" "${TIER}RDFUNMAPPEDCAPACITY=$RDFUNMAPPEDCAPACITY" "

                /usr/symcli/bin/symcfg -sid $SID show -pool $POOLNAME -thin -gb 2>&1 | tail -2 | grep GB | read ONE TWO THREE FOUR FIVE
                if [ $? -eq 0 ]
                then 
                    print -n ${POOLNAME}CAPACITY=$TWO" "${POOLNAME}USED=$THREE" "
                fi

            done
            print ""
        done
    else
        die $CRITICAL "$NAGIOS_CFG not found"
    fi
else
    die $CRITICAL "$NAGIOS_EXE not found or not executable"
fi

# End the script gracefully
die $INFO "Ending \"$0 $*\" ..."
