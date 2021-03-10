# Cray EX User Access Nodes Configuration Debugging

> version: @product_version@
>
> build date: @date@

This section describes debugging configuration issues with User Access Nodes (UAN).

---

## Contents

* [Debugging UAN Configuration Issues](#overview)
* [Configuration Framework Service](#cfs)
* [Debugging UAN Configuration Roles](#debug)

---

<a name="Debugging UAN Configuration Issues"></a>
## Debugging UAN Configuration Issues

Configuration of UAN nodes is performed by the *Configuration Framework Service (CFS)*.  The Ansible
roles involved in UAN configuration are listed in the `site.yml` file in the uan-config-management git
repository in gitea.

The UAN specific roles involved in post-boot UAN node configuration are:
1. uan_disk_config

    1. Configures the first disk with a scratch and swap partition mounted at /scratch and /swap.
    Each partition is 50% of the disk.

1. uan_packages

    1. Installs any rpm packages listed in the uan-config-management repo.

1. uan_interfaces

    1. Sets up the networking configuration for the UAN nodes.

        1. Default is not to setup a CAN connnection or default route.  If CAN is enabled, the
        default route will be on the CAN.  Otherwise, a default route will need to be setup in 
        the customer interfaces definitions.

1. uan_motd

    1. Provides a default message of the day that can be customized by the admin.

1. uan_ldap

    1. Optionally will configure the connection to LDAP servers.

<a name="cfs"></a>
## Configuration Framework Service

The Configuration Framework Service (CFS) can apply configuration data to both images and nodes.  
When the configuration is being applied to nodes, the nodes must be booted and accessible via ssh over
the Node Management Network.

The best way to debug CFS failures is to look at the CFS log file for the session that failed.  To get
a list of CFS sessions sorted so the latest is at the bottom of the list, run the following command on
a management or worker node:

```bash
### Find the CFS session:
# kubectl -n services get pods --sort-by=.metadata.creationTimestamp | grep ^cfs

### View the Ansible log of the CFS session found in the previous command:
# kubectl -n services logs -f -c ansible-0 <session-from-previous-step>
```

### Image Configuration

Most of the roles that are specific to image configuration are required for the operation as a UAN and
should not be removed from `site.yml`.

### Node Configuration

The UAN roles in `site.yml` are required and should not be removed, with exception of `uan_ldap` if the
site is using some other method of user authentication.  The `uan_ldap` may also be skipped by setting the
value of `uan_ldap_setup` to `no` in a group_vars or host_vars configuration file.

The most common failures in the UAN roles and their solutions are discussed here.


<a name="debug"></a>
## Debugging UAN Configuration Roles

### Disk Configuration (uan_disk_config)

The most common cause of failure in the `uan_disk_config` is the disk having been previously configured 
without a /scratch and /swap partition.  The prevents the `parted` command from being able to
divide the disk in 2 and create those partitions.  The solution is to log into the node, run `parted` and
remove the existing partitions on that disk.

1. Take note of the failed disk device in the CFS log.

1. Login to the UAN.  Run the following commands to remove the existing partitions:

    **NOTE**: This example uses `/dev/sdb` as the disk device.  Also, as partitions are removed, their
              numbering moves up.  So we use `rm 1` twice here to remove both partitions.

    ```bash
    uan01:~ # parted
    GNU Parted 3.2
    Using /dev/sda
    Welcome to GNU Parted! Type 'help' to view a list of commands.
    (parted) select /dev/sdb
    Using /dev/sdb
    (parted) print
    Model: ATA VK000480GWSRR (scsi)
    Disk /dev/sdb: 480GB
    Sector size (logical/physical): 512B/4096B
    Partition Table: msdos
    Disk Flags:

    Number  Start   End    Size   Type     File system  Flags
     1      1049kB  240GB  240GB  primary  ext4         type=83
     2      240GB   480GB  240GB  primary  ext4         type=83

    (parted) rm 1
    (parted) rm 1
    (parted) print
    Model: ATA VK000480GWSRR (scsi)
    Disk /dev/sdb: 480GB
    Sector size (logical/physical): 512B/4096B
    Partition Table: msdos
    Disk Flags:
    (parted) quit
    uan01:~ #
    ```

1. Reboot the node or launch a CFS session against the UAN to see if the failure is fixed.

### Network Configuration (uan_interfaces)

This is often the most common area for issues as it is setting up the networking on the node.
There are three phases to the configuration of UAN interfaces on the UAN nodes.

1. Setup and configure the Node Management Network

    1. Gather information from SLS for the NMN

    1. Setup /etc/resolv.conf

    1. The nmn0 interface is the first OCP port on HPE DL hardware or the first LOM port on Gigabyte hardware

1. Setup the Customer Access Network (CAN), if desired

    1. Gather information from SLS for the CAN

    1. The default route will be to the CAN gateway

    1. CAN is implemented as a bonded pair of interfaces

        1. Uses the second port of the 25Gb OCP card and a second 25Gb card on HPE DL hardware

        1. Uses both ports of the 40Gb card on Gigabyte hardware

1. Setup Customer-defined Networks

The debugging process for uan_interfaces is to look for errors in the CFS session log for the nodes then
log into the node (usually via the conman console) and debug networking using standard network debug techniques.

***NOTE***: There is also the off-node part of networking to be considered.  Most errors with NMN and CAN network
setup have been related to switch configuration and cabling to the proper set of switches.


### User Authentication Configuration (LDAP)

The configuration of LDAP is dependent on having either the Customer Access Network configured or having 
a customer provided network configured that can route to the LDAP servers.  If the UAN only has the nmn0
interface active, there is no routing to networks outside the Cray EX system.

### External Filesystem Configuration

Most external filesystem configuration issues are related to network routing, assuming the necessary drivers
(Lustre, GPFS, etc.) are in the UAN image.
