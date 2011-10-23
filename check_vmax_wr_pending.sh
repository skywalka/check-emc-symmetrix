#!/bin/sh
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt

warn=150000
crit=250000
lun=0041
FILE=`ls -tr /var/log/symstat/symstat.log.* | tail -1`
wp=`cat $FILE | tail -2 | grep Total | awk '{print $10}'`
if [ $? -eq 0 ]; then
  if [ $wp -ge $crit ]; then
     nagios_code=2
  elif [ $wp -ge $warn ]; then
     nagios_code=1
  else
     nagios_code=0
  fi
  nagios_str="Write pending of VMAX ${lun} is $wp | write_pending=$wp"
else
  nagios_code=3
  nagios_str="There is an error, please investigate."
fi

echo $nagios_str
exit $nagios_code
