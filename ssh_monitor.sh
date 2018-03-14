#!/bin/bash
BASEPATH="/root/Documents/JIDS"
QIO="$BASEPATH/questionable_ips_occurances"
QI="$BASEPATH/questionable_ips"
DI="$BASEPATH/deny_ips"
CMD="tail -n 100 /var/log/secure"
MAXATTEMPTS=$(cat $BASEPATH/ssh_monitor_config | grep 'maxattempts' | sed 's/maxattempts: //')
TIMEOUT_YEAR=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_year' | sed 's/timeout_year: //')
TIMEOUT_MONTH=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_month' | sed 's/timeout_month: //')
TIMEOUT_DAY=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_day' | sed 's/timeout_day: //')
TIMEOUT_HOUR=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_hour' | sed 's/timeout_hour: //')
TIMEOUT_MINUTE=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_minute' | sed 's/timeout_minute: //')
TIMEOUT_SECOND=$(cat $BASEPATH/ssh_monitor_config | grep 'timeout_second' | sed 's/timeout_second: //')
#journalctl -n 20 -r /usr/sbin/sshd | grep "Failed password" | grep -v "invalid user" \
#| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | uniq > $QI
$CMD | grep "Failed password" | grep -v "invalid user" \
| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | uniq > $QI

> $QIO
while read ip
do
  #OCC=$(journalctl -n 20 -r /usr/sbin/sshd | grep "Failed password" | grep -v "invalid user" | grep -o $ip | wc -l)
  OCC=$( $CMD | grep "Failed password" | grep -v "invalid user" | grep -o $ip | wc -l)
  if [ $OCC -ge $MAXATTEMPTS ]
  then
    PREVBAN=$(sudo iptables -L INPUT -v -n | grep $ip | grep DROP | grep all | wc -l)
    if [ $PREVBAN -eq 0 ]
    then
      echo $PREVBAN
      echo $OCC >> $QIO
      sudo iptables -A INPUT -s $ip -j DROP
      #BANDATE=$(journalctl -n 20 -r /usr/sbin/sshd | grep "Failed password" | grep -v "invalid user" | cut -c 1-16 | head -n 1)
      BANDATE=$( $CMD | grep "Failed password" | grep -v "invalid user" | cut -c 1-16 | tac | head -n 1)
      echo $ip: $BANDATE >> $DI
      echo $BANDATE
    fi
  fi
done < $QI

while read denyentry
do
  BANNEDIP=$(echo $denyentry | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
  BANNEDDATE=$(echo $denyentry | sed "s/$BANNEDIP: //")
  echo $BANNEDIP
  echo $BANNEDDATE
  BANNEDDATE=$(date -d " $BANNEDDATE " )
  UNBANDATE=$(date -d " $BANNEDDATE + $TIMEOUT_YEAR years + $TIMEOUT_DAY days + $TIMEOUT_HOUR hours + $TIMEOUT_MINUTE minutes + $TIMEOUT_SECOND seconds + $TIMEOUT_MONTH months")
  echo $UNBANDATE
  if [[ $(date -d "$UNBANDATE" +%Y:%m:%d:%H:%M:%S) < $(date +%Y:%m:%d:%H:%M:%S) ]]
  then
    echo "UNBAN"
    sudo iptables -D INPUT -s $BANNEDIP -j DROP
    sed -i "/$BANNEDIP/d" $DI
  else
    echo "NO UNBAN"
  fi
  date
done < $DI
