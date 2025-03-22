#!/bin/bash

# Version
OPENWRT_VERSION="24.10"

# URL
BASE_URL="https://images.linuxcontainers.org/images/openwrt/$OPENWRT_VERSION/amd64/default/"
LATEST_BUILD=$(curl -s $BASE_URL | grep -oP '(?<=href=")[^"]+' | sort -r | head -n 1)
CONTAINER_FILE="rootfs.tar.xz"
OPENWRT_DOWNLOAD_LINK="${BASE_URL}${LATEST_BUILD}${CONTAINER_FILE}"

# LXC
LXC_ID=1001
RANDOM_NUMBER=$(shuf -i1000-10000 -n1)
HOSTNAME="openwrt-${OPENWRT_VERSION}-${RANDOM_NUMBER}"
STORAGE="HDD-Storage"
CONFIG_FILE="/etc/pve/lxc/${LXC_ID}.conf"

mkdir -p /homelab-toolchain/proxmox-openwrt
cd /homelab-toolchain/proxmox-openwrt

wget "$OPENWRT_DOWNLOAD_LINK"

pct create $LXC_ID ./$CONTAINER_FILE --unprivileged 1 --ostype unmanaged --arch amd64 --hostname "$HOSTNAME" --storage $STORAGE

sleep 10

sed -i '/net0:/d' $CONFIG_FILE
sed -i '/net1:/d' $CONFIG_FILE

pct set $LXC_ID -net0 name=eth0,bridge=vmbr0,ip=dhcp,type=veth
pct set $LXC_ID -net1 name=eth1,bridge=vmbr2,type=veth

{
    echo "onboot: 1"
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm"
    echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir"
} >> $CONFIG_FILE

# Clean Up
cd "$HOME"
rm -rf /homelab-toolchain/proxmox-openwrt

# Start container
pct start $LXC_ID

if pct exec $LXC_ID -- ping -c 1 -W 10 1.1.1.1 > /dev/null 2>&1; then    
    pct exec $LXC_ID -- sh -c "wget -qO- https://raw.githubusercontent.com/homelab-toolchain/proxmox-openwrt/refs/heads/main/setup.sh | ash"
else
    echo "Check internet connection in container!"
    exit 1
fi

# Finish
echo "Done."