# Configure the BMC for UANs with iLO

Perform this procedure to enable the IPMI/DCMI settings on an HPE UAN that are necessary to continue UAN product installation on an HPE Cray EX supercomputer.

Perform the first three steps of [Prepare for UAN Product Installation](Prepare_for_UAN_Product_Installation.md#prepare-for-uan-product-installation) before performing this procedure.

1. Create the SSH tunnel necessary to access the BMC web GUI interface.

   1. Find the IP or hostname for a UAN.

   2. Create an SSH tunnel to the UAN BMC. Run the following command on an external system.

      In the following example, `UAN_MGMT` is the UAN iLO interface host name or IP address. `NCN` is the host name or IP address of a non-compute node on the system. This example assumes that `NCN` allows port forwarding. `USER` will usually be `root`.

      ```bash
      $ ssh -L 8443:UAN_MGMT:443 USER@NCN
      ```

   3. Wait for SSH to establish the connection.

2. Open https://127.0.0.1:8443 in web browser on the NCN to access the BMC web GUI.

3. Log in to the web GUI using default credentials.

4. Click **Security** in the menu on the left side of the screen.

5. Click **Access Settings** in the menu at the top of the screen.

6. Click the pencil icon next to **Network** in the main window area.

7. Check the box next to **IPMI/DCMI over LAN**.

8. Ensure that the remote management settings match the following screenshot.

![IPMI/DCMI configuration screen](images/HPE_UAN_BMC_IPMI_DCMI_configuration.png)
