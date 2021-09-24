## Install the UAN Product Stream

This procedure installs the User Access Nodes \(UAN\) product on a system so that UAN boot images can be created.

Before performing this procedure:

- Initialize and configure the Cray command line interface \(CLI\) tool. See "Configure the Cray Command Line Interface \(CLI\)" in the CSM documentation for more information.
- Perform [Prepare for UAN Product Installation](installation_prereqs/Prepare_For_UAN_Product_Installation.md#prepare-for-uan-product-installation)

Replace PRODUCT\_VERSION in the example commands with the UAN product stream string \(2.0.0 for example\). Replace CRAY\_EX\_DOMAIN in the example commands with the FQDN of the HPE Cray EX.

**DOWNLOAD AND PREPARE THE UAN SOFTWARE PACKAGE**

1. Start a typescript to capture the commands and output from this installation.

    ```bash
    ncn-m001# script -af product-uan.$(date +%Y-%m-%d).txt 
    ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

2. Run the installation script using either one of the following commands:

    - If the HPE Cray EX is configured for online installations, run this command:

        ```bash
        ncn-m001# ./install.sh --online
        ```

    - If the HPE Cray EX is configured for offline \(that is, air-gapped\) installations, run this command:

        ```bash
        ncn-m001# ./install.sh
        ```

**VERIFY THE INSTALLATION**

3. Verify that the UAN configuration, images, and recipes were imported and added to the `cray-product-catalog` ConfigMap in the Kubernetes `services` namespace.

    a. Run the following command and verify that the output contains an entry for the PRODUCT\_VERSION that was installed in the previous steps:

        The following command may return more than one version of the UAN product if previous versions have been installed.

        ```bash
        ncn-m001# kubectl get cm cray-product-catalog -n services -o json | jq -r .data.uan
        PRODUCT_VERSION:
             configuration:
               clone_url: https://vcs.CRAY_EX_DOMAIN/vcs/cray/uan-config-management.git
               commit: 6658ea9e75f5f0f73f78941202664e9631a63726
               import_branch: cray/uan/PRODUCT_VERSION
               import_date: 2021-07-28 03:26:00.399670
               ssh_url: git@vcs.CRAY_EX_DOMAIN:cray/uan-config-management.git
             images:
               cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
                 id: c880251d-b275-463f-8279-e6033f61578b
             recipes:
               cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
                 id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a
        ```

    b. Verify that the configuration, images, and recipes sections for the installed product version contain information similar to the example output in the previous command.

    c. Verify that the Kubernetes jobs that import the configuration, image, and recipe content completed successfully. Skip this step if the previous substep indicates that the new UAN product version content installed successfully.
       
       A STATUS of `Completed` indicates that the Kubernetes jobs completed successfully.

       ```bash
       ncn-m001# kubectl get pods -n services | grep uan
       uan-config-import-PRODUCT_VERSION-wfh4f                                  0/3     Completed   0          3m15s
       uan-image-recipe-import-PRODUCT_VERSION-92cxz                            0/3     Completed   0          3m15s
       ```

4. Verify that the UAN RPM repositories have been created in Nexus using either of the following methods.:

   In both of the following examples, `PRODUCT_VERSION` is the UAN release number and `SLE_VERSION` is the SLE release version, such as `15sp1` or `15sp2`.

    - Navigate to `https://nexus.CRAY_EX_DOMAIN/#browse/browse` in a web browser to view the list of repositories and verify that the `uan-PRODUCT_VERSION-sle-SLE_VERSION` repository is present. Provided the major and minor versions match the expected PRODUCT\_VERSION, the installation may proceed (the patch version may differ). 
        
    - Query Nexus through its REST API to display the repositories prefixed with the name uan:

        ```bash
        ncn-m001# curl -s -k https://packages.local/service/rest/v1/repositories | jq -r '.[] | \
        select(.name | startswith("uan")) | .name'
        uan-PRODUCT_VERSION-sle-SLE_VERSION
        ```

5. Finish the typescript file started at the beginning of this procedure.

    ```bash
    # exit
    ```

6. **Optional:** Perform [Merge UAN Configuration Data](../upgrade/Merge_UAN_Configuration_Data.md#merge-uan-configuration-data) if a previous version of the UAN product was already installed.
