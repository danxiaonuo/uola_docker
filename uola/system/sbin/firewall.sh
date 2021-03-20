#!/bin/bash

cat /dev/null > /etc/firewall.user
ipaddr=$(uci get network.lan.ipaddr 2>&1 | awk -F. '{print $1 "." $2 "." $3}');for ifname in $(ip route | grep -v 'default' | grep -i $ipaddr | awk '{print $3}');do echo "iptables -t nat -I POSTROUTING -o $ifname -j MASQUERADE" >> /etc/firewall.user;done
ipaddr=$(uci get network.lan.ipaddr 2>&1 | awk -F. '{print $1 "." $2 "." $3}');for ifname in $(ip route | grep -v 'default' | grep -i $ipaddr | awk '{print $3}');do echo "ip6tables -t nat -I POSTROUTING -o $ifname -j MASQUERADE" >> /etc/firewall.user;done