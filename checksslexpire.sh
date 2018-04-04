#!/bin/bash
#Script for SSL certificate date expire and send notification

app="curlapp"
cronname=sslcheck
notifyback=5
script_dir="/usr/bin"
messenger=slack
# SITE VARS
site=SITE
siteport=443
# SLACK VARS
slack_channel="#monitoring"
slack_icon="slack"
slack_username="commandname-bot"
slack_webhookurl=https://hooks.slack.com/services/XXXX
# TELEGRAM VARS
telegram_apitoken=XXXX:XXXxxXXXxxxXXX
telegram_chatid=XXXXXX

function check-inet {
  ping -c2 > /dev/null 8.8.8.8 && ping=ok || ping=critical
  if [ $ping == ok ]
  then
    echo 0
  else
    echo 1
  fi
}

function check-cron {
  system=`lsb_release -d | gawk -F"\t" '{print $2}' | cut -d" " -f1`
  if [ ! -f /etc/cron.d/$cronname ]; then echo "0 * * * *     root   $script_dir/checksslexpire.sh" > /etc/cron.d/$cronname; fi
}

function check-command {
  if [ ! `command -v http; echo $?` ]; then apt -y install httpie; fi
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
    if [ $curmon == $cermon ] && [ $daydif -lt $notifyback ]; then
      case "$messenger" in
        slack ) `slack`;;
        telegram ) `telegram`;;
      esac
    fi
  done
}

function slack {
  case "$app" in
    httpapp ) echo "{\"channel\": \"$slack_channel\", \"icon_emoji\":\":${slack_icon}:\", \"username\":\"$slack_username\", \"text\": \"$text\"}" | http POST $slack_webhookurl > /dev/null;;
    curlapp ) curl -X POST -H 'Content-type: application/json' --data "{\"channel\": \"$slack_channel\", \"icon_emoji\":\":${slack_icon}:\", \"username\":\"$slack_username\", \"text\": \"$text\"}" $slack_webhookurl;;
  esac
}

function telegram {
  curl -s -X POST https://api.telegram.org/bot$apitoken/sendMessage -d text="$text" -d chat_id=$chatid
}

check-cron
check-command
check-cert-date
