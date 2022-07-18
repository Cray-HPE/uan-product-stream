# Enabling the Customer Access Network (CAN) or the Customer High Speed Network (CHN)

The UAN product provides a role, `uan_interfaces` in the Configuration Framework Service (CFS). This role is suitable for Application type nodes, and in some circumstancs, configuring the CHN, on Compute type nodes.

1. Enable CAN or CHN by setting the following in the UAN CFS repo (the filename may be modified to whatever is appropriate):

    ```bash
    ncn-m001:~/ $ cat group_vars/Application_UAN/can.yml
    uan_can_setup: true
    ```
    
1. SLS will be configured with either CAN or CHN, `uan_interfaces` will use this setting to determine if a default route should be established over the nmn (CAN) or the hsn (CHN). To see how the site is configured, query SLS:

   ```bash
   ncn-m001:~/ $ cray sls search networks list --name CHN --format json | jq -r '.[] | .Name'
   CHN
   ```

1. (Optional) If the compute nodes are going to use the UAN CFS role `uan_interfaces` to set a default route on the CHN, make sure there is an appopriate ansible setting for the compute nodes in addition to the UANs:

    ```bash
    ncn-m001:~/ $ cat group_vars/Compute/can.yml
    uan_can_setup: true
    ```

1. Once `uan_can_setup` has been enabled, update the CFS configuration used for the nodes to initate a reconfiguration (see the Configuration Management section of the CSM documentation for more information)

1. The CSM documenation provides additional resources to validate the configuration of CAN and CHN for UANs and Computes. Consult the section titled "Enabling Customer High Speed Network Routing" in the CSM documentation for more information.
