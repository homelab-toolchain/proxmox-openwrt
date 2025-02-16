# General

> [!NOTE]  
> At the moment the script installs Openwrt 24.10. The possibility to provide input parameters comes in the next days/weeks. 

The Proxmox-Openwrt automates installation of OpenWrt on Proxmox and several OpenWRT configuration steps. Below is a detailed description of the actions performed by the script:

**1. Enabling Web and SSH Access** <br>
Opens port `80` (HTTP) and port `22` (SSH) for WAN access.
Updates the OpenWRT firewall configuration to allow web and SSH connections.

**2. Migrating Network Configuration** <br>
Replaces all occurrences of `ifname` with `device` in the /etc/config/network file to support the new OpenWRT naming convention.

**3. Configuring the LAN Interface** <br>
Sets up a static `lan` interface with:
* Device: `eth1`
* IP Address: `10.0.0.1`
* Subnet Mask: `255.255.255.0`
* Disables IPv6 delegation for the LAN.

**4. Disabling IPv6** <br>
Sets various UCI options to disable IPv6 for `lan` and `wan`.<br>
Deletes the ula_prefix option and removes the globals block from the network configuration.<br>
Disables and stops the odhcpd service, responsible for IPv6.<br>

**5. Rebooting the System** <br>
Automatically reboots the router after successfully applying all configurations.

# Prerequsites

1. Internet connection.
2. Log in as root.
3. The network bridge `vmbr0` to be used as `wan` interface.
4. The network bridge `vmbr1` to be used as `lan` interface.
5. Install `curl` or just call the following command:
```
apt-get update -y && apt-get install curl -y
```

# How to Execute

Call the following command on your Proxmox:

```
curl -sSL https://raw.githubusercontent.com/homelab-toolchain/proxmox-openwrt/refs/heads/main/install.sh | bash
```

