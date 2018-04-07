#!/bin/bash
#Script for SSL certificate date expire and send notification

. /etc/checkhttps.conf

# Check functions

function check-inet {
  ping -c2 > /dev/null 8.8.8.8 && ping=ok || ping=critical
  if [ $ping == ok ]; then echo 0; else echo 1; fi
}

function check-cron {
  if [ ! -f /etc/cron.d/$cronfilename ]; then echo "0 * * * *     root   $script_dir/checksslexpire.sh" > /etc/cron.d/$cronfilename; fi
}

function check-command {
  system=`lsb_release -d | gawk -F"\t" '{print $2}' | cut -d" " -f1`
  for I in "curl openssl"; do
    case "$system" in
      Ubuntu ) if [ ! `command -v $I > /dev/null; echo $?` ]; then echo "I need to install $I"; apt -y install $I; fi;;
      Centos ) if [ ! `command -v $I > /dev/null; echo $?` ]; then echo "I need to install $I"; yum -y install $I; fi;;
    esac
  done
}

function check-runindocker {
  if [ `grep docker /proc/1/cgroup; echo $?` -eq 0 ]
    then rid=1; if [ $mode == "h" ]; then echo "I'm running inside of docker, but your config for host. Set mode=d please."; exit; fi;
    else rid=0; if [ $mode == "d" ]; then echo "I'm running on host, but your config for docker. Set mode=h please."; exit; fi;
  fi
}

function check-cert-date {
  for I in $site; do
    curmon=`LANG=en_en.UTF-8; date +%b`
    curday=`date +%d`
    certexp=`echo | openssl s_client -servername $I -connect $I:$siteport 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d'=' -f'2'`
    cermon=`echo $certexp | cut -d' ' -f1`
    cerday=`echo $certexp | cut -d' ' -f2`
    daydif=$(($cerday-$curday))
    text="Cerificate of $I will expired over $daydif days"
#    telegram
    if [ $curmon == $cermon ] && [ $daydif -lt $notifyback ]; then
      case "$messenger" in
        slack ) slack;;
        telegram ) telegram;;
      esac
    fi
  done
}

# Notification functions

#function email {
#
#}

function slack {
#  echo "{\"channel\": \"$slack_channel\", \"icon_emoji\":\":${slack_icon}:\", \"username\":\"$slack_username\", \"text\": \"$text\"}" | http POST $slack_webhookurl > /dev/null;;
  curl -X POST -H 'Content-type: application/json' --data "{\"channel\": \"$slack_channel\", \"icon_emoji\":\":${slack_icon}:\", \"username\":\"$slack_username\", \"text\": \"$text\"}" $slack_webhookurl
}

function telegram {
  curl -s -X POST https://api.telegram.org/bot$telegram_apitoken/sendMessage -d text="$text" -d chat_id=$telegram_chatid
}

# Action functions

#function letsencrypt {
#
#}

function fdock {
  while true; do
    check-cert-date
    sleep $period
  done
}

function fhost {
  check-cron
  check-command
  check-cert-date
}

# General functions

function main {
  check-runindocker
  case "$mode" in
    d ) fdock;;
    h ) fhost;;
  esac
  check-cert-date
}

main