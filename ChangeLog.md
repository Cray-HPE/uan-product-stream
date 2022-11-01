# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Restructure UAN CFS and remove COS CFS roles
- Update Application image to 0.2.1
- Enable install.sh to work on GCP vshastav2
- Add support for unified docs project - docs-product-manifest.yaml
- Update documentation for new COS CFS layers

## [2.5.6] - 2022-10-14
- Fix issue configuring CHN on computes nodes after COS 2.4.79 enabled cray-ifconf

## [2.5.5] - 2022-10-05
- Disable cray-ifconf
- Fix edge case in uan_interfaces

## [2.5.4] - 2022-09-07
- Update UAN with the latest COS CFS changes
- Use a new cf-gitea-import

## [2.5.3] - 2022-08-26
- Update uan_interfaces role to optimize SLS queries
- Update cray-application to 0.1.0 for new packages and build pipeline
- Add docs for SLES Image booting

## [2.5.2] - 2022-08-11
- Update vendored product /hpe/hpc-shastarealm-release
- Create UAN artifacts based on COS 2.4

## [2.5.1] - 2022-08-09
- Add new sles image cray-application-sles15sp3.x86_64-0.0.1
- Add documentation for repurposing compute nodes as UANs

## [2.5.0] - 2022-07-29
- Add support for uan_hardening role on computes
- Add SP4 repos

## [2.4.3] - 2022-06-24
- Add routing to CHN and CAN MetalLB
- Prevent loss of existing routes
- Add new uan_hardening role to block SSH traffic to NCNs

## [2.4.2] - 2022-06-06
- Reverse the order of CHN Gateway conditions to avoid undefined references in ansible
- Add where clause to Mountain NMN gateway play to avoid undefined reference on non-Mountain systems
- Update zypper repo to UAN-2.4 version

## [2.4.1] - 2022-05-24
- Increase short LDAP timeout
- CHN fixes for compute nodes leveraging an IP in SLS
- Include GPU changes from COS 2.3
- Remove cray-diags-fabric from uan-packages

## [2.4.0] - 2022-04-29
- Change documentation to reflect streamlined selection of CAN/CHN
- Change documentation to reflect uan_interfaces can configure compute default route
- Change documentation to use sat bootprep
- Updates to vendor directory for generating and installing releases

## [2.3.2] - 2022-03-01
- Updates to CFS plays for GPU fixes
- Updates to CFS plays for DVS/Lustre/configure_fs fixes
- Enable publishing of docs to HPE Support Center

## [2.3.1] - 2022-02-15
- Fix uan_packages to correctly check signatures
- Updates CFS roles to ROCM 4.5.2
- Updates CFS roles to AMD 21.40.2
- Updates CFS roles to Nvidia SDK 21.9
- Extra testing added to CFS plays
- Specify Application as a target group in CFS documentation
## [2.3.0] - 2021-12-15
- CASMUSER-2926: Add loki fixes for COS 2.2 and CSM artifacts
- Simplify builds of CFS and pin to COS 2.2 CFS plays
- CASMUSER-2920: Provide uan_disable_gpg_check support
- CASMUSER-2917: Fix rpm uploads to nexus and set major/minor/patch at build time
- CASMTRIAGE-2721: Update copyrights and license headers
- CASMUSER-2907: Remove online install support and doc references
- CASM-2594: Update reference to CSM repo to use algol60
- CASMUSER-2807: Add support for creating a UAN capable image with CFS only
- CASMUSER-2789: Remove the UAN kiwi recipe and image
- CASMUSER-2790: Use the COS provided boot parameters rpm
- CASMUSER-2832: Remove unneeded packages
- CASMUSER-2778: Update references from SP2 to SP3
- CASMUSER-2843: Fix formatting error in uan_ldap role
- CASMUSER-2780: Provide ability to get sensitive data from vault for uan_ldap role
- CASM-2589: UAN: Limit access to management gateway by non-root users

## [2.1.9] - 2021-11-28
- CASMUSER-2917: Fix the SHS repo url in the kiwi recipe
- CASMUSER-2917: Fix rpm uploads to nexus and set major/minor/patch at build time
- CASMUSER-2907: Remove references to online installs

## [2.1.8] - 2021-11-16
- CASMUSER-2912: Pin versions correctly for CFS plays from other products
- Use UAN and CSM artifacts from algol60

## [2.1.7] - 2021-10-28
- CASMUSER-2624: Add kdump support for HPE DL UAN nodes

## [2.1.6] - 2021-10-14
- CASMUSER-2868: Add troubleshooting steps for CAN and SLS configuration
- CASMUSER-2848: Add an example vars.yml showing how to enable the CAN
- CASMUSER-2845: Fix goss test and script that checks UAN discovery
- CASMUSER-2849: Remove ifmap from the BOS session template

## [2.1.5] - 2021-09-30
- CASMUSER-2814: Doc updates

## [2.1.4] - 2021-09-10
- CASMTRIAGE-2227: Doc updates
- CASMTRIAGE-2129: Clarify message on checking Nexus versions
- CASMUSER-2804: Update content base image to pick up newer dependent roles

## [2.1.3] - 2021-08-27
- STP-2762: Fix formatting and links in docs

## [2.1.2] - 2021-08-11
- CASMTRIAGE-1878: Use the updated default CAN alias in SLS as configured by csi
- CASMTRIAGE-1870: Fix kdump with packages required by COS
- CASMTRIAGE-1875: Set swappiness value to a string
- CASMTRIAGE-1872: Add steps to set the BIOS EFITIME and troubleshoot x509 cert issues.
- CASMTRIAGE-1854: Add suggestion on the ordering of CFS layers
- NETETH-1541: Change Slingshot to version to 1.4

## [2.1.1] - 2021-07-30
- CASMUSER-2737: uan_ldap runs only at node configuration and pick up other changes including Slingshot repo 1.3

## [2.1.0] - 2021-05-14
- CASMUSER-2608: Update site.yml and the uan recipe for GPU support
- CASMUSER-2709: Fix builds to use master or stable correctly
- CASMUSER-2709: Fix logic to find and replace ARTIFACT_BRANCH
- CASMUSER-2692: Include goss and diagnostics package
- CASMUSER-2613: Update UAN to SLES15SP2
- Added a Changelog
- Switched references of dtr to arti
- Update versions for sles15sp2 change
- CASMUSER-2687: Add CDST GUI packages
- CASMUSER-2613: Add some GPU packages that are present in the COS image
- CASMUSER-2711: Modify the layout of container images to work with existing helm charts
- CASMUSER-2711: Update release version to get the correct UAN rpms
- CASMUSER-2714: Update Slingshot repo to 1.1
- CASMUSER-2740: Update Slingshot repo to 1.2
- CASMUSER-2742: Update Slingshot repo to 1.3
- CASMUSER-2744: Update cray-product-catalog-update to latest version
- CASMUSER-2745: Add single-request option to uan_interfaces
- STP-2670: Restructure docs as Markdown
- CASMUSER-2748: Fix recipe format for profiles and preferences to work with new kiwi-ng
- CASMUSER-2737: Run uan_ldap only during node configuration
