
## Configure Interfaces on UANs

Perform this procedure to set network interfaces on UANs by editing a configuration file.

User access is configurable to use either a direct connection to the UANs from the sites user network, or to use one of two optional user access networks implemented within the HPE Cray EX system.  The two optional networks are the Customer Access Network \(CAN\) or Customer High Speed Network \(CHN\).  CAN is a VLAN on the Node Management Network \(NMN\), whereas CHN is over the High Speed Network \(HSN\).  The default setting is to use a direct connection to the sites user network and the admin must define the interface and default route to use. When CAN or CHN are selected, the interfaces and default route setup will be configured automatically.

Network configuration settings are defined in a `customer_net.yml` file which is used by the Configuration Framework Service \CFS\).  The path to the `customer_net.yml` file in the `uan-config-management` VCS repo will be `group_vars/NODE_GROUP/customer_net.yml` for settings common to all nodes in a given `NODE_GROUP`. `NODE_GROUP` should be replaced by the role and subrole defined in HSM for the nodes - such as `Application_UAN` if the nodes role is `Application` and subrole is `UAN`. Network configuration settings may be defined per node in `host_vars/XNAME/customer.yml`, where `XNAME` is the xname of the node.  These settings would override any settings in the `group_vars/NODE_GROUP/customer.yml` for the node with the given xname.

Admins must create the `customer_net.yml` file and use the variables described in this procedure to define the interfaces and routes.

If the HPE Cray EX CAN or CHN is required, set `uan_user_access_cfg` to `CAN` or `CHN` in `customer_net.yml`, depending on whether the CAN or CHN user access network is desired.

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

5. Edit the `host_vars/XNAME/customer_net.yml` file and configure the values as needed.

    To set up CAN or CHN:

    ```bash
    ## uan_user_access_cfg
    # Set uan_user_access_cfg to 'CAN' if the site will
    # use the Shasta CAN network or to 'CHN' if the site
    # will use the Shasta CHN network for user access.
    uan_user_access_cfg: CHN
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

9. Reboot the UAN with the Boot Orchestration Service \(BOS\).

    The new interfaces will be available when the UAN is rebooted. Replace the UAN\_SESSION\_TEMPLATE value with the BOS session template name for the UANs.

    ```bash
    ncn-w001# cray bos v1 session create \
     --template-uuid UAN_SESSION_TEMPLATE --operation reboot
    ```

10. Verify that the desired networking configuration is correct on each UAN.

