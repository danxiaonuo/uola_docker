#!/bin/bash
#==============================================#
# 设置 network
uci -q delete network.lan.type > /dev/null 2>&1
uci set network.lan.ip6assign='64'
uci set network.lan.ip6hint='0'
uci set network.lan.ipaddr=${ipv4_ipaddr}
uci set network.lan.netmask=${ipv4_netmask}
uci set network.lan.gateway=${ipv4_gateway}
uci set network.lan_ipv6=interface
uci set network.lan_ipv6.device='@lan'
uci set network.lan_ipv6.proto='dhcpv6'
uci set network.lan_ipv6.reqaddress='try'
uci set network.lan_ipv6.reqprefix='auto'
uci -q delete network.lan.dns
uci set network.lan.device='eth0'
uci add_list network.lan.ip6class='local'
uci -q delete network.@device[0].ports
uci commit network
/etc/init.d/network restart
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
uci -q delete dhcp.lan.force > /dev/null 2>&1
uci set dhcp.lan.ignore='1' > /dev/null 2>&1
uci -q delete dhcp.lan.ra_slaac
uci set dhcp.lan.start='0'
uci set dhcp.lan.limit='255'
uci set dhcp.lan.leasetime='12h'
uci set dhcp.lan.dynamicdhcp='0'
uci add_list dhcp.lan.ra_flags='none'
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
# sed -i '/ipv6_check_route/a\/tools/ddns/dnspod_dns_ipv6.sh' /etc/hotplug.d/iface/20-firewall
# sed -i '/ipv6_check_route/a\/tools/ddns/aly_dns_ipv6.sh' /etc/hotplug.d/iface/20-firewall
# 禁用odhcpd
/etc/init.d/odhcpd stop
/etc/init.d/odhcpd disable
# 关闭提示
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci commit dropbear
# 删除相关依赖
sed -i -e '/ipv6自动检测/d' -e '/ipv6_check.sh/d' /etc/rc.local
# 重启clash
# /bin/bash /tools/clash/clash_update.sh
