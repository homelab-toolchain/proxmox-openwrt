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

pct create $LXC_ID ./$CONTAINER_FILE --unprivileged 1 --ostype unmanaged --hostname "$HOSTNAME" --storage $STORAGE

sleep 10

sed -i '/net0:/d' $CONFIG_FILE
sed -i '/net1:/d' $CONFIG_FILE

pct set $LXC_ID -net0 name=eth0,bridge=vmbr0,ip=dhcp,type=veth
pct set $LXC_ID -net1 name=eth1,bridge=vmbr2,type=veth

# Clean Up
cd "$HOME"
rm -rf /homelab-toolchain/proxmox-openwrt