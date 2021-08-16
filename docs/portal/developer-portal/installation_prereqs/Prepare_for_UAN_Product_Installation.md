## Prepare for UAN Product Installation

Perform this procedure to ready the HPE Cray EX supercomputer ready for UAN product installation.

Install and configure the COS product before performing this procedure.

**MANAGEMENT NETWORK SWITCH CONFIGURATION**

1. Ensure that the management network switches are properly configured.

2. Ensure that the management network switches have the proper firmware.

    Refer to the procedure "Update the Management Network Firmware" in the HPE Cray EX hardware documentation.

3. Ensure that the host reservations for the UAN CAN network have been properly set.

    Refer to the procedure "Add UAN CAN IP Addresses to SLS" in the HPE Cray EX hardware documentation.

**BMC CONFIGURATION**

4. Configure the BMC of the UAN.

    - Perform [Configure the BMC for UANs with iLO](#configure_the_bmc_for_uans_with_ilo) if the UAN is a HPE server with an iLO.

**BIOS CONFIGURATION**

5. Configure the BIOS of the UAN.

    - Perform [Configure the BIOS of an HPE UAN](#configure_the_bios_of_an_hpe_uan) if the UAN is a HPE server with an iLO.
    - Perform [Configure the BIOS of a Gigabyte UAN](#configure_the_bios_of_a_gigabyte_uan) if the UAN is a Gigabyte server.

**VERIFY UAN BMC FIRMWARE VERSION**

6. Verify that the firmware for each UAN BMC meets the specifications.

    Use the System Admin Toolkit firmware command to check the current firmware version on a UAN node. Refer to [Node Firmware](#node_firmware).

    ```bash
    ncn-m001# sat firmware -x BMC_XNAME
    ```

7. Repeat the previous six Steps for all UANs.

**VERIFY REQUIRED SOFTWARE FOR UAN INSTALLATION**

8. Perform [Apply the UAN Patch](#apply_the_uan_patch) to apply any needed patch content for the UAN product.

    This process must be performed to ensure that the correct UAN release artifacts are deployed.

9. Unpackage the file.

    ```bash
    ncn-m001# tar zxf uan-PRODUCT_VERSION.tar.gz
    ```

10. Navigate into the uan-PRODUCT_VERSION/ directory.

    ```bash
    ncn-m001# cd uan-PRODUCT_VERSION/
    ```

11. Run the pre-install goss tests to determine if the system is ready for the UAN product installation.

    This requires that goss is installed on the node running the tests. Skip this step to if the automated tests can not be run.

    ```bash
    ncn# ./validate-pre-install.sh
    ...............
    
    Total Duration: 1.304s
    Count: 15, Failed: 0, Skipped: 0
    ```

12. Run the `./tests/goss/scripts/uan\_preflight\_same\_in\_sls\_and\_hsm.py` script if the previous step reports an error for the `uans_same_in_sls_and_hsm` Goss test. Address any errors that are reported.

    This script must be run rerun manually because this test produces erroneous failures otherwise.

13. Manually verify the UAN software prerequisites.

    1. Verify that the cray CLI tool, manifestgen, and loftsman are installed.

        ```bash
        ncn-m001# which cray
        /usr/bin/cray
        ncn-m001# which manifestgen
        /usr/bin/manifestgen
        ncn-m001# which loftsman
        /usr/bin/loftsman
        ```

    2. Verify that Helm is installed and is at least version 3 or greater.

        ```bash
        ncn-m001# which helm
        /usr/bin/helm
        ncn-m001# helm version
        version.BuildInfo{Version:"v3.2.4", GitCommit:"0ad800ef43d3b826f31a5ad8dfbb4fe05d143688", 
        GitTreeState:"clean", GoVersion:"go1.13.12"}
        ```

    3. Verify that the Cray System Management \(CSM\) software has been successfully installed and is running on the system.

        The following Helm releases should be installed and verified:

        - gitea
        - cray-product-catalog
        - cray-cfs-api
        - cray-cfs-operator
        - cray-ims
        
        The following command checks that all these releases are present and have a status of deployed:

        ```bash
        ncn-m001# helm ls -n services -f \
        '^gitea$|cray-cfs-operator|cray-cfs-api|cray-ims|cray-product-catalog'\
         -o json | jq -r '.[] | .status + " " + .name'
        deployed cray-cfs-api
        deployed cray-cfs-operator
        deployed cray-ims
        deployed cray-product-catalog
        deployed gitea
        ```

    4. Verify `cray-conman` is connected to compute nodes and UANs.

        Sometimes the compute nodes an UAN are not up yet when `cray-conman` is initialized and will not be monitored yet. Verify that all nodes are being monitored for console logging or re-initialize `cray-conman` if needed.

        a. Use kubectl to exec into the running `cray-conman` pod, then check the existing connections.

        ```bash
        cray-conman-b69748645-qtfxj:/ # conman -q
        x9000c0s1b0n0
        x9000c0s20b0n0
        x9000c0s22b0n0
        x9000c0s24b0n0
        x9000c0s27b1n0
        x9000c0s27b2n0
        x9000c0s27b3n0
        ```

        b. If the compute nodes and UANs are not included in the list of nodes being monitored, the `conman` process can be re-initialized by killing the conmand process.

        ```bash
        cray-conman-b69748645-qtfxj:/ # ps -ax | grep conmand
             13 ?        Sl     0:45 conmand -F -v -c /etc/conman.conf
          56704 pts/3    S+     0:00 grep conmand
        cray-conman-b69748645-qtfxj:/ # kill 13
        ```

        c. This will regenerate the conman configuration file and restart the conmand process, and now include all nodes that are included in the state manager.

        ```bash
        cray-conman-b69748645-qtfxj:/ # conman -q
        x9000c1s7b0n1
        x9000c0s1b0n0
        x9000c0s20b0n0
        x9000c0s22b0n0
        x9000c0s24b0n0
        x9000c0s27b1n0
        x9000c0s27b2n0
        x9000c0s27b3n0
        ```

    5. Verify that the HPE Cray OS \(COS\) has been installed on the system.

        COS is required to build UAN images from the recipe and to boot UAN nodes.

        ```bash
        ncn-m001# kubectl get cm -n services cray-product-catalog -o json | jq '.data | has("cos")'
        true
        ```

    6. Verify that the Data Virtualization Service \(DVS\) and LNet are configured on the nodes that are running Content Projection Service \(CPS\) `cps-cm-pm` pods provided by COS.

        The UAN product can be installed prior to this configuration being complete, but the the DVS modules must be loaded prior to booting UAN nodes. The following commands determine which nodes are running `cps-cm-pm` and then verifies that those nodes have the DVS modules loaded.

        ```bash
        ncn-m001# kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers
        ncn-w001
        ncn-w002
        ncn-m001# for node in `kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" \
        --no-headers`; do
        ssh $node "lsmod | grep '^dvs '"
        done
        ncn-w001
        ncn-w002
        ```

        More nodes or a different set of nodes may be displayed.

Next, install the UAN product by peforming the procedure [Install the UAN Product Stream](#install_the_uan_product_stream).
