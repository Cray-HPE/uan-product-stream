# Cray EX User Access Nodes Configuration Debugging

> version: @product_version@
>
> build date: @date@

This section describes debugging configuration issues with User Access Nodes (UAN).

---

## Contents

* [Debugging UAN Configuration Issues](#overview)
* [CFS](#cfs)
* [Debugging UAN Configuration Roles](#debug)

---

<a name="Debugging UAN Configuration Issues"></a>
## Debugging UAN Configuration Issues

<a name="CFS"></a>
## Customization Framework Service

<a name="debug"></a>
## Debugging UAN Configuration Roles

### FAILURE: UAN Configuration Task: Create swap partition 
To configure the UAN, a swap partition is created on the UAN's disk.
If the UAN's disk already had a pre-existing partition, then the
swap partition task may fail to create an additional partition. In that case,
remove the pre-existing partition using the 'parted' software.

Start parted.
``` bash
# parted

GNU Parted 3.2
Using /dev/sda
Welcome to GNU Parted! Type 'help' to view a list of commands.
```

Inside the parted interpreter list all of the partitions
```bash
(parted) print all

Model: ATA VK000480GWTHA (scsi)
Disk /dev/sdb: 480GB
Sector size (logical/physical): 512B/4096B
Partition Table: msdos
Disk Flags:

Number  Start   End    Size   Type     File system  Flags
 1      1049kB  240GB  240GB  primary  ext4         type=83
 2      240GB   480GB  240GB  primary  ext4         type=83
```

Select the device from which you want to remove the partition.
```bash
The partitions are numbered in the 'print all' output.
(parted) select <path to device>
Example:
(parted) select /dev/sdb
```

Select the partion you want to remove
```bash
(parted) rm <existing partition number>
Example:
(parted) rm 2
```

Verify the partition has been removed.
```bash
(parted) print all

Model: ATA VK000480GWTHA (scsi)
Disk /dev/sdb: 480GB
Sector size (logical/physical): 512B/4096B
Partition Table: msdos
Disk Flags:

Number  Start   End    Size   Type     File system  Flags
 1      1049kB  240GB  240GB  primary  ext4         type=83
```


### FAILURE: UAN Configuration Task: Create scratch partition 
See UAN Configuration Task: Create swap partition.
