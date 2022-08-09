# Repurposing a Compute Node as a UAN

This section describes how to repurpose a compute node to be used as a User Access Node (UAN).  This is typically done when the processor type of the compute node is not yet available in a UAN server.

## Overview

The following steps outline the process of repurposing a compute node to be used as a UAN.

  1. Verify the System Default Route is set to `CHN`.
    
  1. Change the role of the compute node in the Hardware State Manager from `Compute` to `Application` and set the sub-role to `UAN`.

  1. Ensure that IPs on the CHN exist for the computes nodes in SLS.

  1. Boot the repurposed compute node as a UAN.

  1. Verify the repurposed compute node functions as a UAN.

## Prerequisites

There are no changes needed in hardware, network cabling, or UEFI/BIOS/BMC configuration to repurpose a compute node for use as a UAN.  However, compute nodes do not have the necessary network interface cards to support user access over the Customer Access Network (CAN). Additionally, the network configuration of Mountain Cabinets do not support the CAN network. Therefore, repurposing a compute node as a UAN requires the system to be configured to use the Customer High-Speed Network (CHN) and that the compute nodes have a CHN IP address in SLS.

* The SLS Networks setting for the `SystemDefaultRoute` must be `CHN`
* The repurposed compute nodes must have CHN IP addresses in SLS
* `uan_can_setup` must be set to `true` in the uan-config-management repo

## Procedure

Perform the following steps to repurpose a compute node for use as a UAN.

1. Log in to the master node `ncn-m001`. All commands in this procedure are run from the master node.

1. Verify the system is configured to use the `CHN` as the System Default Route. If the `SystemDefaultRoute` is not `CHN`, the compute nodes may not be repurposed as UAN.

    ```bash
    ncn-m001# cray sls networks describe BICAN  --format json | jq -r '.ExtraProperties.SystemDefaultRoute'
    ```

1. Verify a CHN IP address exists in SLS for each repurposed compute node. Repeat the following command and replace `<XNAME>` with the xname of each repurposed compute node. The compute node must have a CHN IP address in SLS or it cannot be repurposed as a UAN.  See `Add Compute IP addresses to CHN SLS data` section of the Cray System Management documentation for information on adding compute nodes to the CHN.

    ```bash
    ncn-m001# cray sls networks describe CHN | q -r '.ExtraProperties.Subnets[] | select(.FullName == "CHN Bootstrap DHCP Subnet") | .IPReservations[] | select(.Comment == "<XNAME>")'
    ```

1. Verify that `uan_can_setup: true` is set in the `uan-config-management` CFS repo.  See [Enabling the Customer Access Network (CAN) or the Customer High Speed Network (CHN)](../advanced/Enabling_CAN_CHN.md) for more information.

1. Change the role and sub-role in HSM of the compute node(s) being repurposed as UANs to `Application` and `UAN`, respectively.  Repeat the following command and replace `<XNAME>` with the xname of each repurposed compute node.

    ```bash
    ncn-m001# cray hsm state components role update --role Application --sub-role UAN <XNAME>
    ```

1. Verify the role and sub-role in HSM of the repurposed compute node(s) has been changed to 'Application` and 'UAN`, respectively.  Repeat the following command and replace `<XNAME>` with the xname of each repurposed compute node.

    ```bash
    ncn-m001# cray hsm state components describe <XNAME>
    ```

1. Run the BOS session template used to boot the UAN nodes. See [Boot UAN Nodes](../operations/Boot_UANs.md) for more information on booting UAN nodes with BOS.  Replace `<UAN_SESSIONTEMPLATE>` with the name of the BOS session template used to boot the UAN nodes and `<XNAME>` with the xname of the repurposed compute node.

    ```bash
    ncn-m001# cray bos session create --template-uuid <UAN_SESSIONTEMPLATE> --operation reboot --limit <XNAME>
    ```

## Verification as a UAN

Once the repurposed compute node is booted as a UAN, the following steps will verify it is configured as a UAN. These steps may vary dependent upon how the site has configured the UAN nodes.

### Basic UAN Configuration Checks

1. Verify the repurposed compute node has finished the configuration phase. The output should "configured".

    ```bash
    ncn-m001# cray cfs components describe <XNAME> --format json | jq -r .configurationStatus
    ```

1. Login to the repurposed compute node from the master node `ncn-m001` as the root user.

1. Verify that the `hsn0` interface has the CHN IP address assigned to it in SLS.

    ```bash
    uan# ip a | grep hsn0
    ```

1. Verify the default route is via `hsn0`

   ```bash
   uan# ip r | grep default
   ```

1. Verify that all site UAN filesystems are mounted.

### Common UAN Configuration Checks

1. If LDAP is used for user authentication, verify the LDAP service is reachable.

    ```bash
    uan# ping <ldap_service_ip>
    ```

1. If SLURM is used, test `sinfo` and `srun` commands.  This example `srun` command should return the hostname of 4 compute nodes.

    ```bash
    uan# sinfo

    uan# srun -N4 hostname
    ```
### Verify Users can Login

1. Login to the repurposed compute node as an authorized non-root user from any host that should have UAN access.

1. If SLURM is used, test `sinfo` and `srun` commands.  This example `srun` command should return the hostname of 4 compute nodes.

    ```bash
    uan# sinfo

    uan# srun -N4 hostname
    ```
