# Cray EX User Access Nodes Boot Debugging

> version: @product_version@
>
> build date: @date@

This section describes how to debug User Access Nodes (UAN) booting issues.

---

## Contents

* [Debugging UAN Booting Issues](#overview)
* [PXE Issues](#pxe)
* [Initrd/Dracut Issues](#dracut)
* [Image Boot Issues](#image_boot)

---

<a name="overview"></a>
## Debugging UAN Booting Issues

Booting UAN nodes is performed by the *Boot Orchestration Service (BOS)* which makes use of BOS session
templates to define various parameters such as which nodes to boot, which image to boot, kernel parameters,
whether or not to perform post-boot configuration of the nodes by the *Configuration Framework Service (CFS)*,
and which configuration data set to use if post-boot configuration is enabled.

Booting is performed in three phases:

1. **PXE** boot an iPXE binary that will load the initrd of the desired UAN image to boot.

1. Boot the **initrd (dracut)** image which configures the UAN for booting the UAN image.  This consists of
several phases.

    1. Configure the UAN node to use the *Content Projection Service (CPS)* and
    *Data Virtualization Service (DVS)* which is how the UAN image rootfs is mounted and made
    available to the UAN nodes.

    1. Mount the rootfs.

1. Boot the **UAN image** rootfs.

The following sections provide insights into troubleshooting problems in the phases mentioned above.

It is **highly recommended** to configure a `root` user in the UAN image for use in debugging.  Add the
root user's password information from `/etc/shadow` on a worker node to `group_vars/Application/passwd.yml`
in the `uan-config-management.git` repository using the `UAN Image Pre-boot Configuration` procedure.
The contents of `group_vars/Application/passwd.yml` should look similar to the following:

```bash
---
root_passwd: $6$LmQ/PlWlKixK$VL4ueaZ8YoKOV6yYMA9iH0gCl8F4C/3yC.jMIGfOK6F61h6d.iZ6/QB0NLyex1J7AtOsYvqeycmLj2fQcLjfE1
```

<a name="pxe"></a>
## PXE Issues

Most failures to PXE are the result of misconfigured network switches and/or BIOS settings.

The UAN should PXE boot over the Node Management Network (NMN) and the switches must be configured to allow
connectivity to the NMN.  Cabling of the NMN must be to the first port of the OCP card on HPE DL325 and DL385
hardware or the first port of the built-in LAN-On-Motherboard (LOM) on Gigabyte hardware.  See
[UAN Installation Prerequisites](../prereqs/index.md) for details on the switch and BIOS settings required
to configure the UAN for PXE booting.

<a name="dracut"></a>
## Initrd/Dracut Issues

Failures in dracut are often related to the wrong interface being named `nmn0`, or to multiple entries
for the UAN xname in DNS as a result of multiple interfaces making DHCP requests.  This can lead to IP
address mismatches in the dvs_node_map.  DNS will setup entries based on DHCP leases.

When dracut starts, it renames the network device named by the `ifmap=net<x>:nmn0` kernel parameter to `nmn0`.
This interface is the only one dracut will DHCP.  The `ip=nmn0:dhcp` kernel parameter limits dracut to
DHCP only `nmn0`.  It is important to have `ifmap` set correctly in the `kernel_parameters` field of the
BOS session template.

See [UAN Operational Tasks](../operations/index.md) for details on how to configure the BOS session template.
For UAN nodes that have more than one PCI card installed, `ifmap=net2:nmn0` is the correct setting.  If only
one PCI card is install, `ifmap=net0:nmn0` is normally the correct setting.

CPS and DVS are required for image boot.  These are configured in dracut to retrieve the rootfs and mount
it.  If the image fails to download, check that DVS and CPS are both healthy, and DVS is running on all
worker nodes.

<a name="image_boot"></a>
## Image Boot Issues

Once dracut exits, the rootfs will be booted.  Failures seen in this phase tend to be failure of `spire-agent`
and/or `cfs-state-reporter` to start.  The `cfs-state-reporter` tells BOA that the node is ready and
allows BOA to start CFS for post-boot configuration.  If `cfs-state-reporter` does not start, check if the
`spire-agent` has started.  The `cfs-state-reporter` depends on the `spire-agent`.

```bash
--- spire-agant should report enabled and running ---
uan01:~ # systemctl status spire-agent
● spire-agent.service - SPIRE Agent
   Loaded: loaded (/usr/lib/systemd/system/spire-agent.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-02-24 14:27:33 CST; 19h ago
 Main PID: 3581 (spire-agent)
    Tasks: 57
   CGroup: /system.slice/spire-agent.service
           └─3581 /usr/bin/spire-agent run -expandEnv -config /root/spire/conf/spire-agent.conf

--- cfs-state-reporter should report success ---
uan01:~ # systemctl status cfs-state-reporter
● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
   Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Wed 2021-02-24 14:29:51 CST; 19h ago
 Main PID: 3827 (code=exited, status=0/SUCCESS)
```
