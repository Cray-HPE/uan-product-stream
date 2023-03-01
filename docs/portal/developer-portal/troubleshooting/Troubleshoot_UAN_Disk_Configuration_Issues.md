
# Troubleshoot UAN Disk Configuration Issues

Perform this procedure to enable `uan_disk_config` to run successfully by erasing existing disk partitions. UAN disk configuration will fail if the disk on the node is already partitioned. Manually erase any existing partitions to fix the issue.

This procedure currently only addresses `uan_disk_config` errors due to existing disk partitions.

Refer to [About UAN Configuration](../operations/About_UAN_Configuration.md#about-uan-configuration) for an explanation of UAN disk configuration.

The most common cause of failure in the `uan_disk_config` role is the disk having been previously configured without a `/scratch` and `/swap` partition. Existing partitions prevent the `parted` command from dividing the disk into those two equal partitions. The solution is to log into the node and run `parted` manually to remove the existing partitions on that disk.

1. Examine the CFS log and identify the failed disk device.

2. Log into the affected UAN as root.

3. Use parted to manually remove any existing partitions.

    The following example uses `/dev/sdb` as the disk device. Also, as partitions are removed, the remaining partitions are renumbered. Therefore, `rm 1` is issued twice to remove both partitions.

    ```bash
    uan# parted
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

4. Either reboot the affected UAN or launch a CFS session against it to rerun the `uan_disk_config` role.
