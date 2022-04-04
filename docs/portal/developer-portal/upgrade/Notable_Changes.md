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
  * Application nodes may now choose to implement user access over either the existing Customer Access Network \(CAN\), the new Customer High Speed Network \(CHN\), or a direct connection to the customers user network.  By default, a direct connection is selected as it was in previous releases.  The choice of `CAN` or `CHN` must match the overall system implementation.
    * `uan_user_access_cfg` selects the customer access network implementation to use and replaces `uan_can_setup`.  Valid values are `CAN`, `CHN`, or `DIRECT`.  Default is `DIRECT`.
    * `uan_can_setup` is now deprecated.  If present and true, it resolves to `uan_user_access_cfg: CAN`.
  * Application nodes may now set a default route other than the CAN or CHN default route when CAN or CHN are selected.
    * `uan_customer_default_route: true` will allow a customer defined default route to be set using the `customer_uan_routes` structure when `uan_user_access_cfg` is set to `CAN` or `CHN`.
* `sat bootprep` is now used in the documentation to streamline the IMS, CFS, and BOS commands to create and customize images and creating sessiontemplates.
