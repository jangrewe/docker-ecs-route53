#!/bin/bash

ACTION="add"
TTL="60"
DELETE_OLD=false

while [[ $# -gt 1 ]]; do
key="$1"

case $key in
    -a|--action)
    ACTION="$2"
    shift
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift
    ;;
    -r|--record)
    RECORD="$2"
    shift
    ;;
    -i|--ip)
    IP="$2"
    shift
    ;;
    -t|--ttl)
    TTL="$2"
    shift
    ;;
    *)
    ;;
esac
shift
done

if [ -z $DOMAIN ] || [ -z $RECORD ] || [ -z $IP ] ; then
  echo "Usage: --action <add|remove> --domain example.com --record myhostname --ip 192.168.0.1"
  exit 1
fi

RECORDS=()
if [ $ACTION == "add" ]; then
  RECORDS=("${RECORD} ${TTL} A ${IP}")
fi

for OLD_IP in $(cli53 export ${DOMAIN} | sed -ne "s/${RECORD}\s*${TTL}\s*IN\s*A\s*\(.*\)/\1/p" | grep -v "${IP}"); do
  DELETE_OLD=true
  RECORDS+=("${RECORD} ${TTL} A ${OLD_IP}")
done

if [ $ACTION != "add" ] || [ $DELETE_OLD == true ]; then
  cli53 rrdelete ${DOMAIN} ${RECORD} A
fi

if [ $ACTION == "add" ] || [ $DELETE_OLD == true ]; then
  cli53 rrcreate ${DOMAIN} "${RECORDS[@]}"
fi
