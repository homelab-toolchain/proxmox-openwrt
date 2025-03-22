#!/bin/ash

# --------------------------------
# Based on:
# https://openwrt.org/docs/guide-user/services/vpn/wireguard/client
# --------------------------------

# --------------------------------
# Install Necessary Packages
# --------------------------------
opkg update
opkg install luci-proto-wireguard wireguard-tools
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Configure LAN Interface
# --------------------------------
# Remove "Router Advertisements: Stateless Address Autoconfiguration" if exists
uci del dhcp.lan.ra_slaac > /dev/null 2>&1
# Remove "Router Advertisements (RA)" if exists
uci del dhcp.lan.ra_flags > /dev/null 2>&1
# enable "Force DHCP on this network even if another server is detected"
uci set dhcp.lan.force='1'
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Configure WAN Interface
# --------------------------------
# disable "Use DNS servers advertised by peer"
uci set network.wan.peerdns='0'
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Create and Configure Wireguard Interface
# --------------------------------
uci set network.wg0=interface
uci set network.wg0.proto='wireguard'
uci set network.wg0.private_key='<your private key>'
uci add_list network.wg0.addresses='10.72.130.131/32'
uci add_list network.wg0.addresses='fc00:bbbb:bbbb:bb01::9:8282/128'
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Configure DHCP
# --------------------------------
uci del dhcp.@dnsmasq[0].nonwildcard > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].boguspriv > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filterwin2k > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filter_aaaa > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filter_a > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].nonegcache > /dev/null 2>&1
uci add_list dhcp.@dnsmasq[0].server='10.64.0.1'
uci set dhcp.@dnsmasq[0].strictorder='1'
uci commit dhcp
/etc/init.d/odhcpd restart
# --------------------------------

# --------------------------------
# Configure Firewall
# --------------------------------
uci add firewall zone
uci set firewall.@zone[2].name='wireguard'
uci set firewall.@zone[2].input='REJECT'
uci set firewall.@zone[2].output='ACCEPT'
uci set firewall.@zone[2].forward='REJECT'
uci set firewall.@zone[2].masq='1'
uci set firewall.@zone[2].mtu_fix='1'
uci add_list firewall.@zone[2].network='wg0'
for i in $(uci show firewall | grep '=forwarding' | cut -d'[' -f2 | cut -d']' -f1 | sort -nr); do uci delete firewall.@forwarding[$i]; done
uci add firewall forwarding
uci set firewall.@forwarding[0].src='lan'
uci set firewall.@forwarding[0].dest='wireguard'
uci commit firewall
service firewall restart
# --------------------------------

# --------------------------------
# Configure Wireguard Peer
# --------------------------------
for i in $(uci show network | grep '=wireguard_wg0' | cut -d'[' -f2 | cut -d']' -f1 | sort -nr); do uci delete network.@wireguard_wg0[$i]; done
uci add network wireguard_wg0
uci set network.@wireguard_wg0[0].description='wg-001'
uci set network.@wireguard_wg0[0].public_key='UrQiI9ISdPPzd4ARw1NHOPKKvKvxUhjwRjaI0JpJFgM='
uci add_list network.@wireguard_wg0[0].allowed_ips='0.0.0.0/0'
uci add_list network.@wireguard_wg0[0].allowed_ips='::0/0'
uci set network.@wireguard_wg0[0].route_allowed_ips='1'
uci set network.@wireguard_wg0[0].endpoint_host='193.32.249.66'
uci set network.@wireguard_wg0[0].endpoint_port='443'
uci commit network
/etc/init.d/network reload
ifdown wg0 && ifup wg0
# --------------------------------

# --------------------------------
# Reboot the system
# --------------------------------
echo "Rebooting the system..."
reboot
# --------------------------------