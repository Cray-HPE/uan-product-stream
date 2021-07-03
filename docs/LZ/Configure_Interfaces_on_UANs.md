
# Configure Interfaces on UANs

Set arbitrary network interfaces on UANs by editing a configuration file.

- **OBJECTIVE**

    The Customer Access Network \(CAN\) is no longer setup by default as the networking connection to the site user access network. The default is now for sites to directly connect their user network to the User Access Node \(UAN\) or Application nodes, and to define that network configuration in the Configuration Framework Service \(CFS\) host\_vars/<xname\>/customer\_net.yml file.

    Admins must create the host\_vars/<xname\>/customer\_net.yml file and use the variables described in this procedure to define the interfaces and routes.

    If the HPE Cray EX CAN is required, customers must set uan\_can\_setup: yes in host\_vars/<xname\>/customer\_net.yml for each node they wish to use CAN, or in group\_vars/all/customer\_net.yml if they want the HPE Cray EX CAN on all UANs and Application nodes.

1. Obtain the password for the `crayvcs` user.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \\
    --template=\{\{.data.vcs\_password\}\} \| base64 --decode
    ```

2. Log in to ncn-w001.

3. Create a copy of the Git configuration. Enter the credentials for the `crayvcs` user when prompted.

    ```bash
    ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    ```

4. Change to the config-management directory.

    ```bash
    ncn-w001# cd config-management
    ```

5. Edit the host\_vars/<xname\>/customer\_net.yml file and configure the values as needed.

    To set up CAN:

    ```bash
    ## uan_can_setup
    # Set uan_can_setup to 'yes' if the site will
    # use the Shasta CAN network for user access to
    # UAN/Application nodes.
    uan_can_setup: no
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

Verify that the desired networking configuration is correct on each UAN after completed the steps in this procedure.
