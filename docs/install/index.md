# Cray EX User Access Nodes Software Installation

> version: @product_version@
>
> build date: @date@

This section describes the procedure for installing the UAN software package and
verifying the installation is successful.

---

## Contents

* [Download and Prepare the UAN Software Package](#prep)
* [Run the Installation Script (Online Install)](#online)
* [Run the Installation Script (Offline/air-gapped Install)](#offline)
* [Installation Verification](#verify)

---

<a name="prep"></a>
## Download and Prepare the UAN Software Package

1. Download the UAN software package and place it on the system.
2. Unpackage the file using the commands below.

    ```bash
    ncn-m001:~ $ tar zxf uan-@product_version@.tar.gz
    ncn-m001:~ $ cd uan-@product_version@/
    ```

3. Locate the system customizations file and configure UAN Helm customizations,
if applicable. Relevant customizations can be found in the following sections of
the `customizations.yaml` files:
    * `spec.kubernetes.services.cray-uan-install.cray-import-config`
    * `spec.kubernetes.services.cray-uan-install.cray-import-kiwi-recipe-image`.

4. Set the location of the `customizations.yaml` file.

    ```bash
    ncn-m001:~/ $ export CUSTOMIZATIONS=<path to customizations.yaml file>
    ```

    By default, the UAN installation assumes a location of `/opt/cray/site-info/customizations.yaml`
    for the customizations file.

<a name="online"></a>
## Run the Installation Script (Online Install)

If the Cray EX system is configured for online installations, use this section.
Otherwise, skip to the next section for offline (air-gapped) installation.

1. Run the UAN installation script with the `online` option:

    ```bash
    ncn-m001:~/ $ ./install.sh --online
    ```

<a name="offline"></a>
## Run the Installation Script (Offline/air-gapped Install)

If the Cray EX system is configured for offline/air-gapped installations, use
this section.

1. Run the UAN installation script:

    ```bash
    ncn-m001:~/ $ ./install.sh
    ```

<a name="verify"></a>
## Installation Verification

1. Verify that the UAN configuration, images, and recipes have been imported and
   added to the `cray-product-catalog` ConfigMap in the Kubernetes `services`
   namespace.

   ```bash
   ncn-m001:~ $ kubectl get cm cray-product-catalog -n services -o json | jq -r .data.uan

   @product_version@:
     configuration:
       clone_url: https://vcs.<shasta domain>/vcs/cray/uan-config-management.git
       commit: 6658ea9e75f5f0f73f78941202664e9631a63726
       import_branch: cray/uan/@product_version@
       import_date: 2021-07-28 03:26:00.399670
       ssh_url: git@vcs.<shasta domain>:cray/uan-config-management.git
     images:
       cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
         id: c880251d-b275-463f-8279-e6033f61578b
     recipes:
       cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
         id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a
   ```
2. Verify that the UAN RPM repositories have been created in Nexus. Navigate to
   `https://nexus.<shasta domain>/#browse/browse` to view the list of
   repositories. Ensure that the following repositories are present:
   * uan-2.0.0-sle-15sp1
   * uan-2.0-sle-15sp1

   Alternatively, use the Nexus REST API to display the repositories prefixed
   with the name `uan`:

   ```bash
   ncn-m001:~/ $ curl -s -k https://packages.local/service/rest/v1/repositories | jq -r '.[] | select(.name | startswith("uan")) | .name'

   uan-2.0-sle-15sp1
   uan-2.0.0-sle-15sp1
   ```
