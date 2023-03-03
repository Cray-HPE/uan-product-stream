# About UAN Configuration

This section describes the Ansible playbooks and roles that configure UANs.

## UAN configuration overview

Configuration of UAN nodes is performed by the Configuration Framework Service \(CFS\). CFS can apply configuration to both images and nodes. When the configuration is applied to nodes, the nodes must be booted and accessible through SSH over the Node Management Network \(NMN\).

The Ansible roles involved in UAN configuration are listed in the site.yml file in the uan-config-management git repository in VCS. Most of the roles that are specific to image configuration are required for the operation as a UAN and must not be removed from site.yml.

The UAN-specific roles involved in post-boot UAN node configuration are:

- `uan_disk_config`: this role configures the last disk found on the UAN that is smaller than 1TB, by default. That disk will be formatted with a scratch and swap partition mounted at /scratch and /swap, respectively. Each partition is 50% of the disk.
- `uan_packages`: this role installs any RPM packages listed in the uan-config-management repo.
- `uan_interfaces`: this role configures the UAN node networking. By default, this role does not configure a default route or the Customer Access Network \(CAN or CHN\) connection for the HPE Cray EX supercomputer. If CAN or CHN is enabled, the default route will be on the CAN or CHN. Otherwise, a default route must be set up in the customer interfaces definitions. Without the CAN or CHN, there will not be an external connection to the customer site network unless one is defined in the customer interfaces. See [Configure Interfaces on UANs](Configure_Interfaces_on_UANs.md).

  ***NOTE:*** If a UAN layer is used in the Compute node CFS configuration, the `uan_interfaces` role will configure the default route on Compute nodes to be on the HSN, if the BICAN System Default Route is set to `CHN`.
- `uan_motd`: this role Provides a default message of the day that can be customized by the administrator.
- `uan_ldap`: this optional role configures the connection to LDAP servers. To disable this role, the administrator must set 'uan_ldap_setup:no' in the 'uan-config-management' VCS repository.

The UAN roles in site.yml are required and must not be removed, with exception of `uan_ldap` if the site is using some other method of user authentication. The `uan_ldap` may also be skipped by setting the value of `uan_ldap_setup` to `no` in a `group_vars` or `host_vars` configuration file.

For more information about these roles, see [UAN Ansible Roles](UAN_Ansible_Roles.md#uan-ansible-roles).

## UAN network configuration

The `uan_interfaces` role configures the interfaces on the UAN nodes in three phases:

1. Setup and configure the NMN.
    1. Gather information from the System Layout Service \(SLS\) for the NMN.
    2. Populate `/etc/resolv.conf`.
    3. Configure the first OCP port on an HPE server, or the first LOM port on a Gigabyte server, as the `nmn0` interface.
2. Set up the CAN or CHN, if wanted
    1. Gather information from SLS for the CAN or CHN.
    2. Configure the route to the CAN or CHN gateway as the default one.
    3. Implement the CAN or CHN.
        1. CAN: Implement bonded pair
            1. On HPE servers, use the second port of the 25Gb OCP card and a second 25Gb card.
            2. On Gigabyte servers, use both ports of the 40Gb card.
        2. CHN: Implement the CHN interface on the HSN
3. Setup customer-defined networks

See [Configure Interfaces on UANs](Configure_Interfaces_on_UANs.md#configure-interfaces-on-uans) for detailed instructions.

### UAN LDAP network requirements

LDAP configuration requires either a CAN or another customer-provided network that can route to the LDAP servers. Both such networks route outside of the HPE Cray EX system. If a UAN only has the `nmn0` interface configured and active, the UAN cannot route outside of the system.
