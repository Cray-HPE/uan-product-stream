## Notable Changes

The following guide describes changes included in a particular UAN version that may be of note during an install or upgrade.

When an upgrade is being performed, please review the notable changes for **all** of the UAN versions up to the version being installed. If a particular version does not appear in this guide, it may have only had minor changes. For a full account of the changes involved in a release, consult the [Change Log](../../../../ChangeLog.md)

#### UAN 2.2

* UAN 2.2 was an internal release and was not made generally available.

#### UAN 2.3.1

* UAN 2.3 no longer ships a default recipe or image. To build a UAN image, administrators should select a COS recipe to build as the base of their UAN and Application Nodes.
* The role `uan_packages` will now install the rpms needed by UAN and Application Nodes
* The role `uan_packages` role supports GPG checking when the CSM version is 1.2 or greater.
  * `uan_disable_gpg_check: yes` must be set if CSM is earlier than 1.2
  * `uan_disable_gpg_check: no` should be set if CSM is 1.2 or greater

