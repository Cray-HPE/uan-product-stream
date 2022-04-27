
# Configure Interfaces on UANs

Perform this procedure to set network interfaces on UANs by editing a configuration file.

Interface configuration is performed by the `uan_interfaces` Ansible role. For details on the variables referred to in this procedure, see [UAN Ansible Roles](UAN_Ansible_Roles.md).

In the command examples in this procedure, `PRODUCT_VERSION` refers to the current installed version of the UAN product. Replace `PRODUCT_VERSION` with the UAN version number string when executing the commands.  

User access may be configured to use either a direct connection to the UANs from the sites user network, or one of two optional user access networks implemented within the HPE Cray EX system.  The two optional networks are the Customer Access Network \(CAN\) or Customer High Speed Network \(CHN\).  The CAN is a VLAN on the Node Management Network \(NMN\), whereas the CHN is over the High Speed Network \(HSN\).

By default, a direct connection to the sites user network is assumed and the Admin must define the interface and default route using the `customer_uan_interfaces` and `customer_uan_routes` structures. When CAN or CHN are selected, the interfaces and default route are setup automatically.

Network configuration settings are defined in the `uan-config-management` VCS repo under the `group_vars/ROLE_SUBROLE/` or `host_vars/XNAME/` directories, where `ROLE_SUBROLE` must be replaced by the role and subrole assigned for the node in HSM, and `XNAME` with the xname of the node. Values under `group_vars/ROLE_SUBROLE/` apply to all nodes with the given role and subrole.  Values under the `host_vars/XNAME/` apply to the specific node with the xname and will override any values set in `group_vars/ROLE_SUBROLE/`.  A yaml file is used by the Configuration Framwork Service \(CFS\).  The examples in this procedure use `customer_net.yml`, but any filename may be used.  Admins must create this yaml file and use the variables described in this procedure.

If the HPE Cray EX CAN or CHN is desired, set the `uan_can_setup` variable to `yes` in the yaml file.  The UAN will be configured to use the CAN or CHN based on what the BICAN System Default Route is set to in SLS.

1. Obtain the password for the `crayvcs` user.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

2. Log in to ncn-w001.

3. Create a copy of the Git configuration. Enter the credentials for the `crayvcs` user when prompted.

    ```bash
    ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    ```

4. Change to the `uan-config-management` directory.

    ```bash
    ncn-w001# cd uan-config-management
    ```

5. Edit the yaml file, \(`customer_net.yml`, for example\), in either the `group_vars/ROLE_SUBROLE/` or `host_vars/XNAME` directory and configure the values as needed.

    To set up CAN or CHN:

    ```bash
    ## uan_can_setup
    # Set uan_can_setup to 'yes' if the site will
    # use the Shasta CAN or CHN network for user access.
    # By default, uan_can_setup is set to 'no'.
    uan_can_setup: yes
    ```

    To allow a custom default route when CAN or CHN is selected:

    ```bash
    ## uan_customer_default_route
    # Allow a custom default route when CAN or CHN is selected.
    uan_customer_default_route: no
    ```

    To define interfaces:

    ```bash
    ## Customer defined networks ifcfg-X
    # customer_uan_interfaces is as list of interface names used for constructing
    # ifcfg-<customer_uan_interfaces.name> files.  The setting dictionary is where
    # any desired ifcfg fields are defined.  The field name will be converted to 
    # uppercase in the generated ifcfg-<name> file.
    #
    # NOTE: Interfaces should be defined in order of dependency.
    #
    ## Example ifcfg fields, not exhaustive:
    #  bootproto: ''
    #  device: ''
    #  dhcp_hostname: ''
    #  ethtool_opts: ''
    #  gateway: ''
    #  hwaddr: ''
    #  ipaddr: ''
    #  master: ''
    #  mtu: ''
    #  peerdns: ''
    #  prefixlen: ''
    #  slave: ''
    #  srcaddr: ''
    #  startmode: ''
    #  userctl: ''
    #  bonding_master: ''
    #  bonding_module_opts: ''
    #  bonding_slave0: ''
    #  bonding_slave1: ''
    # 
    # customer_uan_interfaces:
    #   - name: "net1"
    #     settings:
    #       bootproto: "static"
    #       device: "net1"
    #       ipaddr: "1.2.3.4"
    #       startmode: "auto"
    #   - name: "net2"
    #     settings:
    #       bootproto: "static"
    #       device: "net2"
    #       ipaddr: "5.6.7.8"
    #       startmode: "auto"
    customer_uan_interfaces: []
    
    ```

    To define interface static routes:

    ```bash
    ## Customer defined networks ifroute-X
    # customer_uan_routes is as list of interface routes used for constructing
    # ifroute-<customer_uan_routes.name> files.  
    # 
    # customer_uan_routes:
    #   - name: "net1"
    #     routes:
    #       - "10.92.100.0 10.252.0.1 255.255.255.0 -"
    #       - "10.100.0.0 10.252.0.1 255.255.128.0 -"
    #   - name: "net2"
    #     routes:
    #       - "default 10.103.8.20 255.255.255.255 - table 3"
    #       - "10.103.8.128/25 10.103.8.20 255.255.255.255 net2"
    customer_uan_routes: []
    ```

    To define the rules:

    ```bash
    ## Customer defined networks ifrule-X
    # customer_uan_rules is as list of interface rules used for constructing
    # ifrule-<customer_uan_routes.name> files.  
    # 
    # customer_uan_rules:
    #   - name: "net1"
    #     rules:
    #       - "from 10.1.0.0/16 lookup 1"
    #   - name: "net2"
    #     rules:
    #       - "from 10.103.8.0/24 lookup 3"
    customer_uan_rules: []
    ```

    To define the global static routes:

    ```bash
    ## Customer defined networks global routes
    # customer_uan_global_routes is as list of global routes used for constructing
    # the "routes" file.  
    # 
    # customer_uan_global_routes:
    #   - routes: 
    #       - "10.92.100.0 10.252.0.1 255.255.255.0 -"
    #       - "10.100.0.0 10.252.0.1 255.255.128.0 -"
    customer_uan_global_routes: []
    ```

6. Add the change from the working directory to the staging area.

    ```bash
    ncn-w001# git add -A
    ```

7. Commit the file to the master branch.

    ```bash
    ncn-w001# git commit -am 'Added UAN interfaces'
    ```

8. Push the commit.

    ```bash
    ncn-w001# git push
    ```

9. Obtain the commit ID for the commit pushed in the previous step.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    ```

10. Update any CFS configurations used by the UANs with the commit ID from the previous step.

    a. Download the JSON of the current UAN CFS configuration to a file.

       This file will be named `uan-config-PRODUCT_VERSION.json`. Replace `PRODUCT_VERSION` with the current installed UAN version.
       ```bash
           ncn-m001#  cray cfs configurations describe uan-config-PRODUCT_VERSION \
            --format=json >uan-config-PRODUCT_VERSION.json
       ```

    b. Remove the unneeded lines from the JSON file.

        The lines to remove are:

           - the `lastUpdated` line
           - the last `name` line 
        
        These must be removed before uploading the modified JSON file back into CFS to update the UAN configuration.

        ```bash
        ncn-m001# cat uan-config-PRODUCT_VERSION.json
        {
          "lastUpdated": "2021-03-27T02:32:10Z",      
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
              "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
              "name": "uan-integration-PRODUCT_VERSION",
              "playbook": "site.yml"
            },
          "name": "uan-config-2.0.1-full"            
        } 
        ```

    c. Replace the `commit` value in the JSON file with the commit ID obtained in the previous Step.

        The name value after the commit line may also be updated to match the new UAN product version, if desired. This is not necessary as CFS does not use this value for the configuration name.

        ```bash
        {
         "layers": [
         {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-configmanagement.git",
         "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
         "name": "uan-integration-PRODUCT_VERSION",
         "playbook": "site.yml"
         }
         ]
        }
        ```

    d. Create a new UAN CFS configuration with the updated JSON file.

       The following example uses `uan-config-PRODUCT_VERSION` for the name of the new CFS configuration, to match the JSON file name.

        ```bash
        ncn-m001# cray cfs configurations update uan-config-PRODUCT_VERSION \
         --file uan-config-PRODUCT_VERSION.json
        ```

    e. Tell CFS to apply the new configuration to UANs by repeating the following command for each UAN. Replace `UAN_XNAME` in the command below with the name of a different UAN each time the command is run.

        ```bash
        ncn-m001# cray cfs components update --desired-config uan-config-PRODUCT_VERSION \
        --enabled true --format json UAN_XNAME
        ```


9. Reboot the UAN with the Boot Orchestration Service \(BOS\).

    The new interfaces will be available when the UAN is rebooted. Replace the `UAN_SESSION_TEMPLATE` value with the BOS session template name for the UANs.

    ```bash
    ncn-w001# cray bos v1 session create \
     --template-uuid UAN_SESSION_TEMPLATE --operation reboot
    ```

10. Verify that the desired networking configuration is correct on each UAN.

