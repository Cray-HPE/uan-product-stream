# Notable Changes

The following guide describes changes included in a particular UAN version that may be of note during an install or upgrade.

When an upgrade is being performed, please review the notable changes for **all** of the UAN versions up to the version being installed. If a particular version does not appear in this guide, it may have only had minor changes. For a full account of the changes involved in a release, consult the ChangeLog.md file at the root of the UAN product repository.

## UAN 2.2

* UAN 2.2 was an internal release and was not made generally available.

## UAN 2.3.1

* UAN 2.3 no longer ships a default recipe or image. To build a UAN image, administrators should select a COS recipe to build as the base of their UAN and Application Nodes.
* The role `uan_packages` will now install the rpms needed by UAN and Application Nodes
* The role `uan_packages` supports GPG checking when the CSM version is 1.2 or greater.
  * `uan_disable_gpg_check: yes` must be set if CSM is earlier than 1.2
  * `uan_disable_gpg_check: no` should be set if CSM is 1.2 or greater

## UAN 2.4.0

* UAN 2.4.0 adds support for a Bifurcated Customer Access Network \(BiCAN\) and the ability to specify a default route other than the CAN or CHN when they are selected.  
  * Application nodes may now choose to implement user access over either the existing Customer Access Network \(CAN\), the new Customer High Speed Network \(CHN\), or a direct connection to the customers user network.  By default, a direct connection is selected as it was in previous releases.  
    * `uan_can_setup`, when set to `yes`, selects the customer access network implementation based on the setting of the BICAN System Default Route in SLS.
    * Application nodes may now set a default route other than the CAN or CHN default route when `uan_can_setup: yes`.
    * `uan_customer_default_route: true` will allow a customer defined default route to be set using the `customer_uan_routes` structure when `uan_can_setup` is set to `yes`.
* `sat bootprep` is now used in the documentation to streamline the IMS, CFS, and BOS commands to create and customize images and creating sessiontemplates.

## UAN 2.4.1

* The UAN CFS playbook now supports a section for Compute nodes. The Compute section will run the role `uan_interfaces` to provide Customer High Speeed Network \(CHN\) routing.
  * CHN on the Compute nodes requires:
    * Customer High Speed Network has been enabled in CSM. See "Enabling Customer High Speed Network Routing" in the CSM Documentation
    * UAN CFS configurd with `uan_can_setup: yes`
    * Fully configured HSN
    * SLS has IP assignments for compute nodes on hsn0
* Updates to GPU roles to match COS 2.3

## UAN 2.4.2

* There is a known issue with the version of GPU support included in the UAN CFS repo. The result is that both AMD and Nvidia SDKs are not able to be projected at the same time. Until this is resolved in a later release, modify the site.yml in the UAN CFS repo to only include either amd or nvidia.

## UAN 2.4.3

* A new CFS role, `uan_hardening` adds iptables rules that will block SSH traffic to NCNs. See the README.md in the uan_hardening role for more information.

## UAN 2.5.3

* A technical preview of a standard SLES image for UAN/Application nodes is included.
* Support SLES15SP4 COS based images

## UAN 2.6.0

* UAN CFS configurations now require a CSM and two COS layers. Roles that were duplicated from COS CFS in the UAN CFS repo have been removed.
  * Values for COS CFS roles that were previously set in the UAN CFS group_vars directory should now be set in COS CFS group_vars
* UAN CFS has been restructured to work for COS and Standard SLES images
* uan_packages variables are now vars/uan_packages.yml and vars/uan_repos.yml and have been renamed. Admins will need to migrate to the new settings.
