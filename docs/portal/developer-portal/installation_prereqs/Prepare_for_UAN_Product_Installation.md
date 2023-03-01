# Prepare for UAN Product Installation

Perform this procedure to ready the HPE Cray EX supercomputer for UAN product installation.

Install and configure the COS product before performing this procedure.

1. Verify that the management network switches are properly configured.

   Refer to the [switch configuration procedures](https://github.com/Cray-HPE/docs-csm/tree/release/1.0/install) in the HPE Cray System Management Documentation.

2. Ensure that the management network switches have the proper firmware.

    Refer to the procedure "Update the Management Network Firmware" in the HPE Cray EX hardware documentation.

3. Ensure that the host reservations for the UAN CAN/CHN network have been properly set.

    Refer to the procedure "Add UAN CAN IP Addresses to SLS" in the HPE Cray EX hardware documentation.

4. Configure the BMC of the UAN.

   Perform [Configure the BMC for UANs with iLO](Configure_the_BMC_for_UANs_with_iLO.md#configure-the-bmc-for-uans-with-ilo) if the UAN is a HPE server with an iLO.

5. Configure the BIOS of the UAN.

    - Perform [Configure the BIOS of an HPE UAN](Configure_the_BIOS_of_an_HPE_UAN.md#configure-the-bios-of-an-hpe-uan) if the UAN is a HPE server with an iLO.
    - Perform [Configure the BIOS of a Gigabyte UAN](Configure_the_BIOS_of_a_Gigabyte_UAN.md#configure-the-bios-of-a-gigabyte-uan) if the UAN is a Gigabyte server.

6. Verify that the firmware for each UAN BMC meets the specifications.

   Use the System Admin Toolkit firmware command to check the current firmware version on a UAN node.

   ```bash
   ncn-m001# sat firmware -x BMC_XNAME
   ```

7. Repeat the previous six Steps for all UANs.

8. Unpackage the file.

    ```bash
    ncn-m001# tar zxf uan-PRODUCT_VERSION.tar.gz
    ```
    
9. Navigate into the uan-PRODUCT_VERSION/ directory.

    ```bash
    ncn-m001# cd uan-PRODUCT_VERSION/
    ```

10. Run the pre-install goss tests to determine if the system is ready for the UAN product installation.

    This requires that goss is installed on the node running the tests.

    ```bash
    ncn# ./validate-pre-install.sh
    ...............
    
    Total Duration: 1.304s
    Count: 15, Failed: 0, Skipped: 0
    ```

11. Ensure that the `cray-console-node` pods are connected to UANs so that they are monitored and their consoles are logged.

    1. Obtain a list of the xnames for all UANs (remove the `--subrole` argument to list all Application nodes).

       ```bash
       ncn# cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID | sort
       x3000c0s19b0n0
       x3000c0s24b0n0
       x3000c0s31b0n0
       ```
    
    2. Obtain a list of the console pods.

       ```bash
       ncn# PODS=$(kubectl get pods -n services -l app.kubernetes.io/name=cray-console-node --template '{{range .items}}{{.metadata.name}} {{end}}')
       ```
       
    3. Use `conman -q` to scan the list of connections being monitored by conman (only UAN xnames are shown for brevity).
    
       ```
       ncn# for pod in $PODS; do kubectl exec -n services -c cray-console-node $pod -- conman -q; done
       x3000c0s19b0n0
       x3000c0s24b0n0
       x3000c0s31b0n0
       ```

       If a console connection is not present, the install may continue, but a console connection should be established before attempting to boot the UAN.

Next, install the UAN product by performing the procedure [Install the UAN Product Stream](../install/Install_the_UAN_Product_Stream.md#install-the-uan-product-stream).
