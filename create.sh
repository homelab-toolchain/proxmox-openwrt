#!/bin/bash

set -e

get_value() {
    local parameter=$1
    shift
    for arg in "$@"; do
        if [[ "$arg" == $parameter=* ]]; then
            echo "${arg#*=}"
            return 0
        elif [[ "$arg" == "$parameter" ]]; then
            echo ""
            return 0
        fi
    done
    return 1
}

get_parameter_value(){
    local parameter=$1
    local default_value=$2
    shift 2

    result=$(get_value "$parameter" "$@")

    if [ -z "$result" ]; then
        if [ -z "$default_value" ]; then
            echo "Error: Parameter '$parameter' is required." >&2
            exit 1
        else
            result=$default_value
        fi
    fi

    echo "${result}"
    return 0
}

# ----------------------------------------------------------------------------------------------------------------------
# Use Input Parameters. Otherwise, if not present, use default values
OPENWRT_VERSION=$(get_parameter_value "openWrtVersion" "24.10" "$@")
LXC_ID=$(get_parameter_value "lxcId" "10000" "$@")
HOSTNAME=$(get_parameter_value "hostname" "openwrt-${OPENWRT_VERSION}" "$@")
STORAGE=$(get_parameter_value "storage" "local-lvm" "$@")
OPENWRT_WAN_INTERFACE=$(get_parameter_value "wanInterface" "vmbr0" "$@")
OPENWRT_LAN_INTERFACE=$(get_parameter_value "lanInterface" "" "$@")
# ----------------------------------------------------------------------------------------------------------------------

# LXC
INSTALL_FOLDER="/tmp/homelab-toolchain/install/${HOSTNAME}"
CONFIG_FILE="/etc/pve/lxc/${LXC_ID}.conf"

# Download OpenWrt
BASE_URL="https://images.linuxcontainers.org/images/openwrt/$OPENWRT_VERSION/amd64/default/"
LATEST_BUILD=$(curl -sSL "$BASE_URL" | grep -oP '(?<=href=")[^"]+' | sort -r | head -n 1)
CONTAINER_FILE="rootfs.tar.xz"
OPENWRT_DOWNLOAD_LINK="${BASE_URL}${LATEST_BUILD}${CONTAINER_FILE}"
rm -rf "$INSTALL_FOLDER" && mkdir -p "$INSTALL_FOLDER"
cd "$INSTALL_FOLDER" || exit 1
wget "$OPENWRT_DOWNLOAD_LINK"

pct create "$LXC_ID" ./$CONTAINER_FILE --unprivileged 1 --ostype unmanaged --arch amd64 --hostname "$HOSTNAME" --storage "$STORAGE"

echo "Wait until OpenWrt container has been created..."
sleep 30

sed -i '/net0:/d' "$CONFIG_FILE"
sed -i '/net1:/d' "$CONFIG_FILE"

pct set "$LXC_ID" -net0 name=eth0,bridge="$OPENWRT_WAN_INTERFACE",ip=dhcp,type=veth
pct set "$LXC_ID" -net1 name=eth1,bridge="$OPENWRT_LAN_INTERFACE",type=veth

{
    echo "onboot: 1"
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm"
    echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir"
} >> "$CONFIG_FILE"

# Clean Up
cd "$HOME" || exit 1
rm -rf "$INSTALL_FOLDER"

# Start container
pct start "$LXC_ID"
echo "Wait until OpenWrt container has been started..."
sleep 30s

if pct exec "$LXC_ID" -- ping -c 1 -W 10 1.1.1.1 > /dev/null 2>&1; then
    pct exec "$LXC_ID" -- sh -c "wget -qO- https://raw.githubusercontent.com/homelab-toolchain/proxmox-openwrt/refs/heads/main/setup.sh | ash"
else
    echo "Check internet connection in container!"
    exit 1
fi

# Finish
echo "Done."