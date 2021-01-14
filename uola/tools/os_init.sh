#!/bin/bash
#==============================================#
# 关闭dhcp
uci -q delete dhcp.lan.leasetime > /dev/null 2>&1
uci -q delete dhcp.lan.limit > /dev/null 2>&1
uci -q delete dhcp.lan.start > /dev/null 2>&1
uci -q delete dhcp.lan.dhcp_option > /dev/null 2>&1
uci -q delete dhcp.lan.ra_flags > /dev/null 2>&1
uci -q delete dhcp.lan.ra > /dev/null 2>&1
uci -q delete dhcp.lan.dhcpv6 > /dev/null 2>&1
uci -q delete dhcp.lan.ndp > /dev/null 2>&1
uci -q delete dhcp.lan.ra_management > /dev/null 2>&1
uci -q delete dhcp.lan.ra_default > /dev/null 2>&1
uci -q delete dhcp.lan.master > /dev/null 2>&1
uci -q delete dhcp.lan.dns > /dev/null 2>&1
uci set dhcp.lan.ignore='1' > /dev/null 2>&1
uci commit dhcp
/etc/init.d/dnsmasq restart
#=====================================================#
# 防火墙
# 启用FullCone-NAT
uci set firewall.@defaults[0].fullcone='1' > /dev/null 2>&1
# lan_ipv6接口
uci set firewall.@zone[0].network='lan lan_ipv6'
uci commit firewall
/etc/init.d/firewall restart
#=======================================================#
# 增加DDNS
sed -i '/ipv6_check_route/a\/tools/ddns/dnspod_dns_ipv6.sh' /etc/hotplug.d/iface/20-firewall
sed -i '/ipv6_check_route/a\/tools/ddns/aly_dns_ipv6.sh' /etc/hotplug.d/iface/20-firewall
# 禁用odhcpd
/etc/init.d/odhcpd stop
/etc/init.d/odhcpd disable
# 关闭提示
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci commit dropbear
# 重启clash
/bin/bash /tools/clash/clash_update.sh
# 关闭nft-qos
uci set nft-qos.default.limit_enable=0
uci commit nft-qos
/etc/init.d/nft-qos restart
