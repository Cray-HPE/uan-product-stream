## About UAN Configuration

A description of the Ansible playbooks and roles that configure UANs.

### UAN configuration overview

Configuration of UAN nodes is performed by the Configuration Framework Service \(CFS\). CFS can apply configuration to both images and nodes. When the configuration is applied to nodes, the nodes must be booted and accessible through SSH over the Node Management Network \(NMN\).

The Ansible roles involved in UAN configuration are listed in the site.yml file in the uan-config-management git repository in VCS. Most of the roles that are specific to image configuration are required for the operation as a UAN and must not be removed from site.yml.

The UAN-specific roles involved in post-boot UAN node configuration are:

- uan\_disk\_config: this role configures the first disk with a scratch and swap partition mounted at /scratch and /swap, respectively. Each partition is 50% of the disk.
- uan\_packages: this role installs any RPM packages listed in the uan-config-management repo.
- uan\_interfaces: this role configures the UAN node networking. By default, this role does not configure a default route or the Customer Access Network \(CAN\) connection for the HPE Cray EX supercomputer. If CAN is enabled, the default route will be on the CAN. Otherwise, a default route must be set up in the customer interfaces definitions.
- uan\_motd: this role Provides a default message of the day that can be customized by the administrator.
- uan\_ldap: this optional role configures the connection to LDAP servers.

The UAN roles in site.yml are required and must not be removed, with exception of uan\_ldap if the site is using some other method of user authentication. The uan\_ldap may also be skipped by setting the value of uan\_ldap\_setup to `no` in a group\_vars or host\_vars configuration file.

### UAN network configuration

The uan\_interfaces role configures the interfaces on the UAN nodes in three phases:

1. Setup and configure the NMN.
    1. Gather information from the System Layout Service \(SLS\) for the NMN.
    2. Populate /etc/resolv.conf.
    3. Configure the first OCP port on an HPE server, or the first LOM port on a Gigabyte server, as the `nmn0` interface.
2. Set up the CAN, if wanted
    1. Gather information from SLS for the CAN.
    2. Configure the route to the CAN gateway as the default one.
    3. Implement the CAN interface as a bonded pair.
        1. On HPE servers, use the second port of the 25Gb OCP card and a second 25Gb card.
        2. On Gigabyte servers, use both ports of the 40Gb card.
3. Setup customer-defined networks

### UAN LDAP network requirements

LDAP configuration requires either a CAN or another customer-provided network that can route to the LDAP servers. Both such networks route outside of the HPE Cray EX system. If a UAN only has the `nmn0` interface configured and active, the UAN cannot route outside of the system.
