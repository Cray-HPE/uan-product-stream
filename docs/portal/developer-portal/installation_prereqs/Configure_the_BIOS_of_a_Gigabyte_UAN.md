## Configure the BIOS of a Gigabyte UAN

Configure the network interface and boot settings required by Gigabyte UANs.

Before the UAN product can be installed on Gigabyte UANs, specific network interface and boot settings must be configured in the BIOS.

1. Press the **Delete** key to enter the setup utility when prompted to do so in the console.

2. Navigate to the boot menu.

3. Set the **Boot Option \#1** field to `Network:UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection`.

4. Set all other **Boot Option** fields to `Disabled`.

5. Ensure that the Boot mode select is set to `[UEFI]`.

6. Select **Save & Exit** to save the settings.

7. Select **Yes** to confirm and press the **Enter** key.

    The UAN will reboot.

8. **Optional:**Run the following IPMI commands if the BIOS settings do not persist.

    In these example commands, the BMC of the UAN is x3000c0s27b0. Replace USERNAME and PASSWORD with username and password of the BMC of the UAN. These commands do the following:

    1. Power off the node
    2. Perform a reset.
    3. Set the PXE boot in the options.
    4. Power on the node

    ```bash
    ncn-m001# ipmitool -I lanplus -U *** -P *** -H x3000c0s27b0 power off
    ncn-m001# ipmitool -I lanplus -U *** -P *** -H x3000c0s27b0 mc reset cold
    ncn-m001# ipmitool -I lanplus -U *** -P *** -H x3000c0s27b0 chassis bootdev pxe options=efiboot,persistent
    ncn-m001# ipmitool -I lanplus -U *** -P *** -H x3000c0s27b0 power on
    ```
