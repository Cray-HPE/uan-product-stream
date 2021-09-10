# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.4] - 2021-09-08
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
