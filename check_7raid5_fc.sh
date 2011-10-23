#!/bin/sh

warn=$1
crit=$2
lun=$3
FILE=`ls -tr /var/log/EMCcapacity*.log | tail -1`
shostname=`/usr/bin/hostname`
line=`grep "${shostname}:SID=$lun " $FILE | tail -1`
cap_lable=`echo $line | awk '{print $39}' | awk -F"=" '{print $1}'`
capacity=`echo $line | awk '{print $39}' | awk -F"=" '{print $2}'`
if [ $? -eq 0 -a $capacity -ne 0 ]; then
  used_lable=`echo $line | awk '{print $40}' | awk -F"=" '{print $1}'`
  used=`echo $line | awk '{print $40}' | awk -F"=" '{print $2}'` 
  percetage=`echo "$used * 100 / $capacity" | bc`
  if [ $percetage -ge $crit ]; then
    RETVAL=2
  elif [ $percetage -ge $warn ]; then
    RETVAL=1
  else
    RETVAL=0
  fi
  RETSTR="The usage is ${used}/${capacity} = ${percetage}% used"
else
  RETVAL=3
  RETSTR="There is an error, please investigate."
fi

echo $RETSTR
exit $RETVAL
