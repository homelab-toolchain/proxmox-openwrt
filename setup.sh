#!/bin/ash

# --------------------------------
# Install first packages
# --------------------------------
opkg update && opkg install nano curl ca-certificates
# --------------------------------

# --------------------------------
# Enable web access and ssh
# --------------------------------
uci add firewall rule
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='80'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci set firewall.@rule[-1].name='Enable Web Access'

uci add firewall rule
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='22'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci set firewall.@rule[-1].name='Enable SSH'

uci commit firewall
/etc/init.d/firewall restart
# --------------------------------

# --------------------------------
# Migrate network: Replace "ifname" with "device"
# --------------------------------
sed -i 's/ifname/device/g' /etc/config/network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Enable LAN interface
# --------------------------------
uci set network.lan=interface
uci set network.lan.proto='static'
uci set network.lan.device='eth1'
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.delegate='0'
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Disable IPv6
# --------------------------------
uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set 'network.loopback.ipv6=0'
uci set 'dhcp.lan.dhcpv6=disabled'
/etc/init.d/odhcpd disable
uci commit
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci commit dhcp
/etc/init.d/odhcpd restart
uci set network.lan.delegate="0"
uci commit network
/etc/init.d/network restart
/etc/init.d/odhcpd disable
/etc/init.d/odhcpd stop
uci delete network.wan6
uci delete network.globals
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Reboot the system
# --------------------------------
echo "Rebooting the system..."
reboot
# --------------------------------