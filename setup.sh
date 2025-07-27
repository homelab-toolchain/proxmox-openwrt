#!/bin/ash
# shellcheck shell=dash

# -----------------------------------------------------------------------------------
# Check internet connection
# -----------------------------------------------------------------------------------
echo "Checking internet connection..."
if ! ping -c 1 -W 10 1.1.1.1 > /dev/null 2>&1; then
    echo "Check the internet connection and try again!"
    exit 1
fi
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Install first packages
# -----------------------------------------------------------------------------------
opkg update && opkg install nano curl ca-certificates
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Extend firewall rules
# -----------------------------------------------------------------------------------
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

uci add firewall rule
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest='lan'
uci set firewall.@rule[-1].target='ACCEPT'
uci set firewall.@rule[-1].name='Allow parent network access to local devices'

uci commit firewall
/etc/init.d/firewall restart
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Migrate network: Replace "ifname" with "device"
# -----------------------------------------------------------------------------------
sed -i 's/ifname/device/g' /etc/config/network
/etc/init.d/network restart
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Enable LAN interface
# -----------------------------------------------------------------------------------
uci set network.lan=interface
uci set network.lan.proto='static'
uci set network.lan.device='eth1'
uci set network.lan.ipaddr='10.0.0.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.delegate='0'
uci commit network
/etc/init.d/network restart
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Disable IPv6
# -----------------------------------------------------------------------------------
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
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Upgrade the system.
# -----------------------------------------------------------------------------------
# opkg update && opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Reboot the system
# -----------------------------------------------------------------------------------
echo "Rebooting the system..."
reboot
# -----------------------------------------------------------------------------------