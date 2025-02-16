#!/bin/ash

# --------------------------------
# Enable web access and ssh
# --------------------------------
{
    config rule
            option src          wan
            option dest_port    80
            option proto        tcp
            option target       ACCEPT
            option name         'Enable Web Access'

    config rule
            list proto          tcp
            option src          wan
            option dest_port    22
            option target       ACCEPT
            option name         'Enable SSH'
} >> /etc/config/firewall
# --------------------------------

# --------------------------------
# Migrate network: Replace "ifname" with "device"
# --------------------------------
sed -i 's/ifname/device/g' /etc/config/network
# --------------------------------

# --------------------------------
# Restart network
# --------------------------------
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Enable LAN interface
# --------------------------------
{
    config interface 'lan'
            option proto 'static'
            option device 'eth1'
            option ipaddr '10.0.0.1'
            option netmask '255.255.255.0'
            option delegate '0'
} >> /etc/config/network
# --------------------------------

# --------------------------------
# Disable IPv6
# --------------------------------
uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
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
uci -q delete network.globals.ula_prefix
uci commit network
sed -i '/globals/d' /etc/config/network
/etc/init.d/network restart
uci -q delete network.wan6
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Reboot the system
# --------------------------------
reboot
# --------------------------------