#!/bin/bash

IPADDR=$(uci get network.lan.ipaddr 2>&1 | awk -F. '{print $1 "." $2 "." $3}')
LAN_DEV=$(ip route | grep -v 'default' | grep -i $IPADDR | awk '{print $3}')
ULA_PREFIX=$(uci get network.globals.ula_prefix 2>&1 | cut -d ':' -f 1 2>&1)
DEFAULT_SH=$(ip -6 route show default 2>&1 | grep -v $ULA_PREFIX 2>&1 | sed -n -e 's/default from //' -e 's/ via .*$//g' -e '/64$/p' | awk 'END {print}')
DEFAULT_BR=$(ip -6 route list dev $LAN_DEV 2>&1 | grep -v 'default' | grep -v $ULA_PREFIX 2>&1 | grep :: -m 1 | awk '{print $1}' | awk 'END {print}')
FROM_ROUTE=$(echo "$DEFAULT_BR" dev br-lan metric 1 pref medium 2>&1)
BR_ROUTE=$(ip -6 route | grep -i "$FROM_ROUTE" 2>&1)
if [[ "$DEFAULT_SH" != "$DEFAULT_BR" ]];then
     echo '自动创建ipv6路由'
     ip -6 route del $DEFAULT_BR dev $LAN_DEV > /dev/null 2>&1
     ip -6 route add $DEFAULT_SH dev $LAN_DEV metric 1 > /dev/null 2>&1
     ip -6 route add fe80::/64 dev $LAN_DEV metric 2 > /dev/null 2>&1
     ip -6 route add $ULA_PREFIX::/64 dev $LAN_DEV metric 3 > /dev/null 2>&1
     /etc/init.d/mwan3 restart > /dev/null 2>&1
     /etc/init.d/smartdns restart > /dev/null 2>&1
     /etc/init.d/dnsmasq restart > /dev/null 2>&1
elif [[ "$FROM_ROUTE" != "$BR_ROUTE" ]];then
     echo '自动创建ipv6路由'
     ip -6 route del $DEFAULT_BR dev $LAN_DEV > /dev/null 2>&1
     ip -6 route add $DEFAULT_SH dev $LAN_DEV metric 1 > /dev/null 2>&1
     ip -6 route add fe80::/64 dev $LAN_DEV metric 2 > /dev/null 2>&1
     ip -6 route add $ULA_PREFIX::/64 dev $LAN_DEV metric 3 > /dev/null 2>&1
     /etc/init.d/mwan3 restart > /dev/null 2>&1
     /etc/init.d/smartdns restart > /dev/null 2>&1
     /etc/init.d/dnsmasq restart > /dev/null 2>&1
fi
