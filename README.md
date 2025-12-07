<h1 align="center">Proxmox OpenWrt</h1>
<h3 align="center">Automated OpenWrt LXC deployment for Proxmox VE</h3>
<p align="center">
<a href="#">
<img src="https://img.shields.io/github/last-commit/homelab-toolchain/proxmox-openwrt/main?style=for-the-badge&label=last%20update&display_timestamp=committer"/>
</a>
</p>

---

## Overview

This project contains two companion scripts that provision a ready-to-use OpenWrt appliance on a Proxmox VE host:

- `create.sh` creates an OpenWrt LXC container, downloads the requested release directly from [images.linuxcontainers.org](https://images.linuxcontainers.org/), attaches the WAN/LAN bridges, and injects the LXC configuration required for networking.
- `setup.sh` is executed inside the container to install base packages, open management access from the WAN side, harden IPv4, disable IPv6, and reboot the router once all changes are applied.

Run the scripts directly from GitHub and you will have a clean OpenWrt instance a few moments later—no web clicks or manual configuration required.

## Features

- Targets any published OpenWrt release (defaults to `24.10`) and automatically pulls the newest build for that release.
- Creates a Proxmox LXC with predictable naming, storage placement, and ID ranges that can be overridden via parameters.
- Configures dual veth interfaces so you can map independent WAN/LAN bridges such as `vmbr0` and `vmbr1`.
- Opens HTTP/SSH management ports on the WAN zone and copies firewall rules that let your upstream network reach devices on the LAN.
- Migrates the OpenWrt network config to the modern `device` syntax, pins the LAN interface to `eth1`, and sets 10.0.0.0/24 as the default LAN.
- Disables IPv6 support (including odhcpd) to keep deployments predictable in dual-stack environments.

## Requirements

1. Proxmox VE host with shell access as `root` and the `pct` command available.
2. Internet access from the Proxmox host (scripts download container images and packages).
3. At least two configured Linux bridges (e.g., `vmbr0` for WAN and `vmbr1` for LAN).
4. Available storage on the chosen Proxmox datastore (default `local-lvm`).
5. Optional but recommended: create dedicated LXC ID ranges so they do not collide with existing guests.

## Quick Start

```bash
wget -qO- https://raw.githubusercontent.com/homelab-toolchain/proxmox-openwrt/refs/heads/main/create.sh \
| bash -s lanInterface=vmbr10000
```

### Full Example with Custom Parameters

```bash
wget -qO- https://raw.githubusercontent.com/homelab-toolchain/proxmox-openwrt/refs/heads/main/create.sh \
| bash -s openWrtVersion=24.10 \
        lxcId=1000 \
        hostname=openwrt-24.10 \
        storage=local-lvm \
        wanInterface=vmbr0 \
        lanInterface=vmbr1
```

### Argument Reference

| Parameter       | Default              | Required | Description |
|-----------------|----------------------|----------|-------------|
| `openWrtVersion`| `24.10`              | No       | OpenWrt release to download from linuxcontainers.org. |
| `lxcId`         | `10000`              | No       | Proxmox LXC numeric ID. Must be unique on the host. |
| `hostname`      | `openwrt-<version>`  | No       | Hostname assigned to the new container. |
| `storage`       | `local-lvm`          | No       | Proxmox storage backend used for the container root disk. |
| `wanInterface`  | `vmbr0`              | No       | Bridge mapped to `eth0` inside the container (WAN). |
| `lanInterface`  | _(none)_             | Yes      | Bridge mapped to `eth1` inside the container (LAN). |

All parameters can be chained after `bash -s` as `key=value` pairs in any order.

## What the Scripts Configure

Once the container is running, `setup.sh` completes the following tasks automatically:

1. **Connectivity check** – Ensures the container can reach the internet before proceeding.
2. **Base packages** – Installs `nano`, `curl`, and `ca-certificates` so the image is ready for troubleshooting and HTTPS requests.
3. **Firewall rules** – Adds explicit WAN rules for HTTP (80) and SSH (22) and a rule that allows traffic from the upstream (WAN) network back into the LAN zone.
4. **Network migration** – Replaces legacy `ifname` syntax with `device` entries in `/etc/config/network`.
5. **LAN definition** – Configures `eth1` as a static LAN interface on `10.0.0.1/24` with IPv6 delegation disabled.
6. **IPv6 shutdown** – Disables IPv6 on `lan`, `wan`, and `loopback`, removes `network.globals`, stops and disables `odhcpd`, and deletes the default `wan6` interface.
7. **Final reboot** – Reboots the container so all kernel/network changes are active.

These opinionated defaults keep the deployment deterministic. Adjust the scripts if you require IPv6, alternate addressing, or different firewall behavior.

## Post-Install Checklist

- **Set an admin password**: OpenWrt ships without one. Log in via SSH or LuCI on `10.0.0.1` and create a secure password immediately.
- **Double-check bridge wiring**: Confirm that `vmbr0` (WAN) and `vmbr1` (LAN) connect to the networks you expect in Proxmox.
- **Optional updates**: Uncomment the upgrade block in `setup.sh` if you want the script to update all packages automatically after provisioning.

## Troubleshooting Tips

- Container cannot reach the internet: verify the WAN bridge has upstream connectivity and that the Proxmox host can resolve DNS.
- No access to `10.0.0.1`: ensure your LAN bridge is attached to the correct physical or virtual network and that your workstation is on the same segment.

---

**Reminder:** Always finish by defining an admin password. Without it, OpenWrt will continue to allow passwordless root access over SSH and LuCI.
