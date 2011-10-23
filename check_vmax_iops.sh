#!/bin/sh
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt

warn=18000
crit=20000
lun=0041
invalid=200000
FILE=`ls -tr /var/log/symstat/symstat.log.* | tail -1`
perfdata=`cat $FILE | tail -2 | grep Total`
iops_read=`echo $perfdata | grep Total | awk '{print $2}'`
iops_write=`echo $perfdata | grep Total | awk '{print $3}'`
KBps_read=`echo $perfdata | grep Total | awk '{print $4}'`
KBps_write=`echo $perfdata | grep Total | awk '{print $5}'`

if [ $iops_read -lt $invalid ] && [ $iops_write -lt $invalid ]; then

  if [ $iops_read -ge $iops_write ]; then

    if [ $iops_read -ge $crit ]; then
       nagios_code=2
    elif [ $iops_read -ge $warn ]; then
       nagios_code=1
    else
       nagios_code=0
    fi
    nagios_str="IOPS Read of VMAX ${lun} is $iops_read, IOPS Write of VMAX ${lun} is $iops_write | iops_read=$iops_read ; iops_write=$iops_write ; KBps_read=$KBps_read ; KBps_write=$KBps_write"

  else
    if [ $iops_write -ge $crit ]; then
       nagios_code=2
    elif [ $iops_write -ge $warn ]; then
       nagios_code=1
    else
       nagios_code=0
    fi
    nagios_str="IOPS Read of VMAX ${lun} is $iops_read, IOPS Write of VMAX ${lun} is $iops_write | iops_read=$iops_read ; iops_write=$iops_write ; KBps_read=$KBps_read ; KBps_write=$KBps_write"

  fi
else
    nagios_code=0
    nagios_str="OK | iops_read=$iops_read ; iops_write=$iops_write ; KBps_read=$KBps_read ; KBps_write=$KBps_write"
fi

echo $nagios_str
exit $nagios_code

