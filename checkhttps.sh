#!/bin/bash
#Script for SSL certificate date expire and send notification

# Check functions

if [ $# -gt 0 ]; then
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -s|--site)
      SITE="$2"
      shift # past argument
      shift # past value
      ;;
#      -m|--mode)
#      MODE="$2"
#      shift # past argument
#      shift # past value
#      ;;
      -n|--notify)
      NOTIFY="$2"
      shift # past argument
      shift # past value
      ;;
      -m|--messenger)
      MESSENGER="$2"
      shift # past argument
      shift # past value
      ;;
      -p|--proxy)
      PROXY="$2"
      shift # past argument
      shift # past value
      ;;
      --tapi)
      TELEGRAM_APITOKEN="$2"
      shift # past argument
      shift # past value
      ;;
      --tid)
      TELEGRAM_CHATID="$2"
      shift # past argument
      shift # past value
      ;;
      -c|--channel)
      SLACK_CHANNEL="$2"
      shift # past argument
      shift # past value
      ;;
      -u|--user)
      SLACK_USERNAME="$2"
      shift # past argument
      shift # past value
      ;;
      -w|--webhookurl)
      SLACK_WEBHOOKURL="$2"
      shift # past argument
      shift # past value
      ;;
#      *)    # unknown option
#      POSITIONAL+=("$1") # save it in an array for later
#      shift # past argument
#      ;;
    esac
  done
else
  . /etc/checkhttps.conf
fi

[[ $SITEPORT == '' ]] && SITEPORT=443
[[ $NOTIFY == '' ]] && NOTIFY=5

#function check-inet {
#  if [ `ping -c2 > /dev/null 8.8.8.8 && ping=ok || ping=critical` == "ok" ]; then echo 0; else echo 1; fi
#}

function check-cron {
  if [ ! -f /etc/cron.d/$cronfilename ]; then echo "0 * * * *     root   $script_dir/checksslexpire.sh" > /etc/cron.d/$cronfilename; fi
}

function check-command {
  os=`lsb_release -d | gawk -F"\t" '{print $2}' | cut -d" " -f1`
  for I in "curl openssl"; do
    case "$os" in
      Ubuntu ) if [ ! `command -v $I > /dev/null; echo $?` ]; then echo "I need to install $I"; apt -y install $I; fi;;
      Centos ) if [ ! `command -v $I > /dev/null; echo $?` ]; then echo "I need to install $I"; yum -y install $I; fi;;
    esac
  done
}

#function check-system {
#  if [ `grep docker /proc/1/cgroup > /dev/null; echo $?` -eq 0 ]
#    then rid=1; if [ $MODE == "h" ]; then echo "I'm running inside of docker, but your config for host. Set MODE=d please."; exit; fi;
#    else rid=0; if [ $MODE == "d" ]; then echo "I'm running on host, but your config for docker. Set MODE=h please."; exit; fi;
#  fi
#}

function check-cert-date {
  for I in $SITE; do
    curmon=`LANG=en_en.UTF-8; date +%b`
    curday=`date +%d`
    curyear=`date +%Y`
    certexp=`echo | openssl s_client -servername $I -connect $I:$SITEPORT 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d'=' -f'2'`
    cermon=`echo $certexp | cut -d' ' -f1`
    cerday=`echo $certexp | cut -d' ' -f2`
    ceryear=`echo $certexp | cut -d' ' -f4`
    daydif=$((10#$cerday-10#$curday))
    yeardif=$((10#$ceryear-10#$curyear))
    text="Cerificate of $I will expired over $daydif days"
    telegram
    if [ $curyear == $ceryear ] && [ $curmon == $cermon ] && [ $daydif -lt $NOTIFY ]; then
      case "$MESSENGER" in
        s ) slack;;
        t ) telegram;;
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
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"channel\": \"$SLACK_CHANNEL\", \"icon_emoji\":\":${slack_icon}:\", \"username\":\"$SLACK_USERNAME\", \"text\": \"$text\"}" $SLACK_WEBHOOKURL
}

function telegram {
  curl -s -X POST https://api.telegram.org/bot$TELEGRAM_APITOKEN/sendMessage \
    --socks5 tg.airpush.com:1883
    -d text="$text" \
    -d chat_id=$TELEGRAM_CHATID
}

# Action functions

#function letsencrypt {
#
#}

#function fdock {
#  while true; do
#    check-cert-date
#    sleep $PERIOD
#  done
#}

#function fhost {
#  check-cron
#  check-command
#  check-cert-date
#}

#function testsite {
#  check-command
#  check-cert-date
#}

# General functions

function main {
#  check-system
  check-cron
  check-command
  check-cert-date
#  case "$MODE" in
#    d ) fdock;;
#    h ) fhost;;
#    t ) testsite;;
#  esac
}

main