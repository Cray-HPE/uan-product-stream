# Configure the BIOS of an HPE UAN

Perform this procedure to configure the network interface and boot settings required by HPE UANs.

Before the UAN product can be installed on HPE UANs, specific network interface and boot settings must be configured in the BIOS.

Perform [Configure the BMC for UANs with iLO](Configure_the_BMC_for_UANs_with_iLO.md#configure-the-bmc-for-uans-with-ilo) before performing this procedure.

1. Force a UAN to reboot into the BIOS.

    In the following command, `UAN_BMC_XNAME` is the xname of the BMC of the UAN to configure. Replace `USER` and `PASSWORD` with the BMC username and password, respectively.

    ```bash
    ncn-m001# ipmitool -U USER -P PASSWORD -H UAN_BMC_XNAME -I lanplus \
    chassis bootdev pxe options=efiboot,persistent
    ```

2. Monitor the console of the UAN using either ConMan or the following command:

    ```bash
    ncn-m001# ipmitool -U USER -P PASSWORD -H UAN_BMC_XNAME -I \
    lanplus sol activate
    ```

    Refer to the section "About the ConMan Containerized Service" in the CSM documentation for more information about ConMan.

3. Press the **ESC** and **9** keys to access the BIOS System Utilities when the option appears.

4. Ensure that OCP Slot 10 Port 1 is the only port with **`Boot Mode`** set to Network Boot. All other ports must have **`Boot Mode`** set to Disabled.

    The settings must match the following example.

    ```bash
        --------------------
        System Configuration
    
        BIOS Platform Configuration (RBSU) > Network Options > Network Boot Options > PCIe Slot Network Boot
    
        Slot 1 Port 1 : Marvell FastLinQ 41000 Series -   [Disabled]        
        2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC
            
        Slot 1 Port 2 : Marvell FastLinQ 41000 Series -   [Disabled]        
        2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC
            
        Slot 2 Port 1 : Network Controller                [Disabled]       
        OCP Slot 10 Port 1 : Marvell FastLinQ 41000       [Network Boot]    
        Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3
        Adapter - NIC
            
        OCP Slot 10 Port 2 : Marvell FastLinQ 41000       [Disabled]        
        Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3
        Adapter - NIC
        --------------------
    ```

5. Set the **`Link Speed`** to `SmartAN` for all ports.

    ```bash
        --------------------
        System Utilities
    
        System Configuration > Main Configuration Page > Port Level Configuration
    
        Link Speed                                        [SmartAN]  
        FEC Mode                                          [None]
        Boot Mode                                         [PXE]
        DCBX Protocol                                     [Dynamic]
        RoCE Priority                                     [0]
        PXE VLAN Mode                                     [Disabled]
        Link Up Delay                                     [30]
        Wake On LAN Mode                                  [Enabled]
        RDMA Protocol Support                             [iWARP + RoCE]
        BAR-2 Size                                        [8M]
        VF BAR-2 Size                                     [256K]
        ---------------------
    ```

6. Set the boot options to match the following example.

    ```bash
     ----------------------
    System Utilities
    
    System Configuration > BIOS/Platform Configuration (RBSU) > Boot Options
    
    Boot Mode                                         [UEFI Mode]                    
    UEFI Optimized Boot                               [Enabled]                      
    Boot Order Policy                                 [Retry Boot Order Indefinitely]
    
    UEFI Boot Settings
    Legacy BIOS Boot Order
    -----------------------
    ```

7. Set the UEFI Boot Order settings to match the following example.

    The order must be:

    1. USB
    2. Local disks
    3. OCP Slot 10 Port 1 IPv4
    4. OCP Slot 10 Port 1 IPv6

    ```bash
    -----------------------
    System Utilities
    
    System Configuration > BIOS/Platform Configuration (RBSU) > Boot Options > UEFI Boot Settings > UEFI Boot Order
    
    Press the '+' key to move an entry higher in the boot list and the '-' key to move an entry lower
    in the boot list. Use the arrow keys to navigate through the Boot Order list.
    
    Generic USB Boot
    SATA Drive  Box 1 Bay 1 : VK000480GWTHA
    SATA Drive  Box 1 Bay 2 : VK000480GWTHA
    SATA Drive  Box 1 Bay 3 : VK001920GWTTC
    SATA Drive  Box 1 Bay 4 : VK001920GWTTC
    OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter -
    NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
    OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter -
    NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv6)
    ------------------------- 
    ```

8. Refer to this [Setting the Date and Time](https://support.hpe.com/hpesc/public/docDisplay?docLocale=en_US&docId=a00112581en_us&page=s_date_time.html) in the HPE UEFI documentation to set the correct date and time.

   If the time is not set correctly, then PXE network booting issues may occur.

