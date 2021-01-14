#!/bin/bash

IPADDR=$(uci get network.lan.ipaddr 2>&1 | awk -F. '{print $1 "." $2 "." $3}')
LAN_DEV=$(ip route | grep -v 'default' | grep -i $IPADDR | awk '{print $3}')
ULA_PREFIX=$(uci get network.globals.ula_prefix 2>/dev/null)
DEFAULT_SH=$(ip -6 route show default 2>&1 | grep -v `echo $ULA_PREFIX | cut -d ':' -f 1` | sed -n -e 's/default from //' -e 's/ via .*$//g' -e '/64$/p' | awk 'END {print}')
DEFAULT_BR=$(ip -6 route list dev $LAN_DEV 2>&1 | grep -v 'default' | grep -v `echo $ULA_PREFIX | cut -d ':' -f 1` | grep :: -m 1 | awk '{print $1}' | awk 'END {print}')
if [[ "$DEFAULT_SH" != "$DEFAULT_BR" ]];then
     echo '自动创建ipv6路由'
     ip -6 route del $DEFAULT_BR dev br-lan > /dev/null 2>&1
     ip -6 route add $DEFAULT_SH dev br-lan metric 1 > /dev/null 2>&1
     ip -6 route add fe80::/64 dev br-lan metric 2 > /dev/null 2>&1
     ip -6 route add da66::/64 dev br-lan metric 3 > /dev/null 2>&1
     /etc/init.d/firewall restart > /dev/null 2>&1
     /etc/init.d/dnsmasq restart > /dev/null 2>&1
fi
