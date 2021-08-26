## UAN Ansible Roles

### uan_disk_config


The `uan_disk_config` role configures swap and scratch disk partitions on UAN
nodes.

#### Requirements

There must be disk devices found on the UAN node by the `device_filter` module
or this role will exit with failure. This condition can be ignored by setting
`uan_require_disk` to `false`. See variable definitions below.

See the `library/device_filter.py` file for more information on this module.

The device that is found will be unmounted if mounted and a swap partition will
be created on the first half of the disk, and a scratch partition on the second
half. ext4 filesystems are created on each partition.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

##### `uan_require_disk`

Boolean to determine if this role continues to setup disk if no disks were found
by the device filter. Set to `true` to exit with error when no disks are found.

```yaml
uan_require_disk: false
```

##### `uan_device_name_filter`

Regular expression of disk device name for this role to filter.
Input to the `device_filter` module.

```yaml
uan_device_name_filter: "^sd[a-f]$"
```

##### `uan_device_host_filter`

Regular expression of host for this role to filter.
Input to the `device_filter` module.

```yaml
uan_device_host_filter: ""
```

##### `uan_device_model_filter`

Regular expression of device model for this role to filter.
Input to the `device_filter` module.

```yaml
uan_device_model_filter: ""
```

##### `uan_device_vendor_filter`

Regular expression of disk vendor for this role to filter.
Input to the `device_filter` module.

```yaml
uan_device_vendor_filter: ""
```

##### `uan_device_size_filter`


Regular expression of disk size for this role to filter.
Input to the `device_filter` module.

```yaml
uan_device_size_filter: "<1TB"
```

##### `uan_swap`

Filesystem location to mount the swap partition.

```yaml
uan_swap: "/swap"
```

##### `uan_scratch`

Filesystem location to mount the scratch partition.

```yaml
uan_scratch: "/scratch"
```

##### `swap_file`

Name of the swapfile to create. Full path is `<uan_swap>/<swapfile>`.

```yaml
swap_file: "swapfile"
```

##### `swap_dd_command`

`dd` command to create the `swapfile`.

```yaml
swap_dd_command: "/usr/bin/dd if=/dev/zero of={{ uan_swap }}/{{ swap_file }} bs=1GB count=10"
```

##### swap_swappiness

Value to set the swapiness in sysctl.

```yaml
swap_swappiness: "10"
```

#### Dependencies
------------

`library/device_filter.py` is required to find eligible disk devices.

#### Example Playbook
----------------

```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_disk_config }
```

This role is included in the UAN `site.yml` play.

### uan_interfaces

The `uan_interfaces` role configures site/customer-defined network interfaces
and Shasta Customer Access Network (CAN) network interfaces on UAN nodes.

#### Requirements

None.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

##### `uan_can_setup`

`uan_can_setup` configures the Customer Access Network (CAN) on UAN nodes. If
this value is falsey no CAN is configured on the nodes.

```yaml
uan_can_setup: no
```

##### `sls_nmn_name`

`sls_nmn_name` is the Node Management Network name used by SLS.

```yaml
sls_nmn_name: "NMN"
```

##### `sls_nmn_svcs_name`

`sls_nmn_svcs_name` is the Node Management Services Network name used by SLS.

```yaml
sls_nmn_svcs_name: "NMNLB"
```

##### `sls_mnmn_svcs_name`

`sls_mnmn_svcs_name` is the Mountain Node Management Services Network name used by SLS.

```yaml
sls_mnmn_svcs_name: "NMN_MTN"
```

##### `sls_can_name`

`sls_can_name` is the Customer Access Network name used by SLS.

```yaml
sls_can_name: "CAN"
```

##### `customer_uan_interfaces`

`customer_uan_interfaces` is as list of interface names used for constructing
`ifcfg-<customer_uan_interfaces.name>` files. Define ifcfg fields for each
interface here. Field names are converted to uppercase in the generated
`ifcfg-<name>` file(s).

Interfaces should be defined in order of dependency.

```yaml
customer_uan_interfaces: []

# Example:
customer_uan_interfaces:
  - name: "net1"
    settings:
      bootproto: "static"
      device: "net1"
      ipaddr: "1.2.3.4"
      startmode: "auto"
  - name: "net2"
    settings:
      bootproto: "static"
      device: "net2"
      ipaddr: "5.6.7.8"
      startmode: "auto"
```

##### `customer_uan_routes`

`customer_uan_routes` is as list of interface routes used for constructing
`ifroute-<customer_uan_routes.name>` files.

```yaml
customer_uan_routes: []

# Example
customer_uan_routes:
  - name: "net1"
    routes:
      - "10.92.100.0 10.252.0.1 255.255.255.0 -"
      - "10.100.0.0 10.252.0.1 255.255.128.0 -"
  - name: "net2"
    routes:
      - "default 10.103.8.20 255.255.255.255 - table 3"
      - "10.103.8.128/25 10.103.8.20 255.255.255.255 net2"
```

##### `customer_uan_rules`

`customer_uan_rules` is as list of interface rules used for constructing
`ifrule-<customer_uan_routes.name>` files.

```yaml
customer_uan_rules: []

# Example
customer_uan_rules:
  - name: "net1"
    rules:
      - "from 10.1.0.0/16 lookup 1"
  - name: "net2"
    rules:
      - "from 10.103.8.0/24 lookup 3"
```

##### `customer_uan_global_routes`

`customer_uan_global_routes` is a list of global routes used for constructing
the "routes" file.

```yaml
customer_uan_global_routes: []

# Example
customer_uan_global_routes:
  - routes: 
    - "10.92.100.0 10.252.0.1 255.255.255.0 -"
    - "10.100.0.0 10.252.0.1 255.255.128.0 -"
```

##### `external_dns_searchlist`

`external_dns_searchlist` is a list of customer-configurable fields to be added
to the `/etc/resolv.conf` DNS search list.

```yaml
external_dns_searchlist: [ '' ] 

# Example
external_dns_searchlist:
  - 'my.domain.com'
  - 'my.other.domain.com'
```

##### `external_dns_servers`

`external_dns_servers` is a list of customer-configurable fields to be added
to the `/etc/resolv.conf` DNS server list.

```yaml
external_dns_servers: [ '' ] 

# Example
external_dns_servers:
  - '1.2.3.4'
  - '5.6.7.8'
```

##### `external_dns_options`

`external_dns_options` is a list of customer-configurable fields to be added
to the `/etc/resolv.conf` DNS options list.

```yaml
external_dns_options: [ '' ]

# Example
external_dns_options:
  - 'single-request'
```

##### `uan_access_control`

`uan_access_control` is a boolean variable to control whether non-root access control is enabled
Default is `no`

```yaml
uan_access_control: no
```

##### `api_gateways`

`api_gateways` is a list of API gateway DNS names to block non-user access

```yaml
api_gateways:
  - "api-gw-service"
  - "api-gw-service.local"
  - "api-gw-service-nmn.local"
  - "kubeapi-vip"
```

##### `api_gw_ports`

`api_gw_ports` is a list of gateway ports to protect.

```yaml
api_gw_ports: "80,443,8081,8888"
```

##### `sls_url`

`sls_url` is the SLS URL.

```yaml
sls_url: "http://cray-sls"
```

#### Dependencies


None.

#### Example Playbook

```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_interfaces }
```

This role is included in the UAN `site.yml` play.

### uan_ldap

The `uan_ldap` role configures LDAP and AD groups on UAN nodes.

#### Requirements

NSCD, pam-config, sssd.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

`uan_ldap_setup` is a boolean variable to selectively skip the setup of LDAP on nodes it
would otherwise be configured due to `uan_ldap_config` being defined.  The default setting
is to setup LDAP when `uan_ldap_config` is not empty.

```yaml
uan_ldap_setup: yes
```

`uan_ldap_config` configures LDAP domains and servers. If this list is empty,
no LDAP configuration will be applied to the UAN targets and all role tasks will
be skipped.

```yaml
uan_ldap_config: []

# Example
uan_ldap_config:
  - domain: "mydomain-ldaps"
    search_base: "dc=...,dc=..."
    servers: ["ldaps://123.123.123.1", "ldaps://213.312.123.132"]
    chpass_uri: ["ldaps://123.123.123.1"]

  - domain: "mydomain-ldap"
    search_base: "dc=...,dc=..."
    servers: ["ldap://123.123.123.1", "ldap://213.312.123.132"]

```

`uan_ad_groups` configures active directory groups on UAN nodes.

```yaml
uan_ad_groups: []

# Example
uan_ad_groups:
  - { name: admin_grp, origin: ALL }
  - { name: dev_users, origin: ALL }
```

`uan_pam_modules` configures PAM modules on the UAN nodes in `/etc/pam.d`.

```yaml
uan_pam_modules: []

# Example
uan_pam_modules:
  - name: "common-account"
    lines:
      - "account required\tpam_access.so"
```

#### Dependencies

None.

#### Example Playbook

```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_ldap }
```

This role is included in the UAN `site.yml` play.

### uan_motd

The `uan_motd` role appends text to the `/etc/motd` file.

#### Requirements

None.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

```yaml
uan_motd_content: []
```

`uan_motd_content` contains text to be added to the end of the `/etc/motd` file.

#### Dependencies

None.

#### Example Playbook

```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_motd, uan_motd_content: "MOTD CONTENT" }
```

This role is included in the UAN `site.yml` play.

### uan_packages

The `uan_packages` role installs additional RPMs on UANs using the Ansible
`zypper` module.

Packages that are required for UANs to function should be preferentially
installed during image customization and/or image creation.

Installing RPMs during post-boot node configuration can cause high system loads
on large systems.

This role will only run on SLES-based nodes.

#### Requirements

Zypper must be installed.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

```yaml
uan_additional_sles15_packages: []
```

`uan_additional_sles15_packages` contains the list of RPM packages to install.

#### Dependencies

None.

#### Example Playbook

```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_packages, uan_additional_sles15_packages: ['vim'] }
```

This role is included in the UAN `site.yml` play.


### uan_shadow

The `uan_shadow` role configures the root password on UAN nodes.

#### Requirements

The root password hash has to be installed in HashiCorp Vault at `secret/uan root_password`.

#### Role Variables

Available variables are listed below, along with default values (see defaults/main.yml):

##### `uan_vault_url`

`uan_vault_url` is the URL for the HashiCorp Vault

```yaml
uan_vault_url: "http://cray-vault.vault:8200"
```

##### `uan_vault_role_file`

`uan_vault_role_file` is the required Kubernetes role file for HashiCorp Vault access.

```yaml
uan_vault_role_file: /var/run/secrets/kubernetes.io/serviceaccount/namespace
```

##### `uan_vault_jwt_file`

`uan_vault_jwt_file` is the path to the required Kubernetes token file for HashiCorp Vault access.

```yaml
uan_vault_jwt_file: /var/run/secrets/kubernetes.io/serviceaccount/token
```

##### `uan_vault_path`

`uan_vault_path` is the path to use for storing data for UANs in HashiCorp Vault.

```yaml
uan_vault_path: secret/uan
```

##### `uan_vault_key`

`uan_vault_key` is the key used for storing the root password in HashiCorp Vault.

```yaml
uan_vault_key: root_password
```

#### Dependencies

None.

#### Example Playbook


```yaml
- hosts: Application_UAN
  roles:
      - { role: uan_shadow }
```

This role is included in the UAN `site.yml` play.

License
---------

Copyright 2021 Hewlett Packard Enterprise Development LP

Author Information
------------------

Hewlett Packard Enterprise Development LP
