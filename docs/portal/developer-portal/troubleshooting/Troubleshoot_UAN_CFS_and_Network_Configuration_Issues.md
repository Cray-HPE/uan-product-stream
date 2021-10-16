
## Troubleshoot UAN CFS and Network Configuration Issues

Examine the UAN CFS pod logs to help troubleshoot CFS and networking issues on UANs.

Read [About UAN Configuration](../operations/About_UAN_Configuration.md#about-uan-configuration) before starting this procedure.

1. Obtain the name of the CFS session that failed by running the following command on a management or worker NCN:

    This example sorts the list of CFS sessions so that the most recent one is at the bottom.

    ```bash
    ncn# kubectl -n services get pods --sort-by=.metadata.creationTimestamp | grep ^cfs
    ```

2. View the Ansible log of the CFS session found in the previous step \(CFS\_SESSION in the following example\). Use the information in log to guide troubleshooting.

    ```bash
    ncn# kubectl -n services logs -f -c ansible-0 CFS_SESSION
    ```

3. **Optional:** Troubleshoot `uan_interfaces` issues by logging into the affected node \(usually with the conman console\) and using standard network debugging techniques.

    NMN and CAN network setup errors can also result from incorrect switch configuration and network cabling.

4. For additional debugging of the `uan_interfaces` role, consider increasing ansible logs by changing the following configmap:

   ```bash
   ncn# kubectl -n services edit cm cfs-default-ansible-cfg
   ```

   Set the following options to `yes`:
   ```bash
   display_ok_hosts      = yes
   display_skipped_hosts = yes
   ```

   **Warning:** It is recommended that these settings be reset when no longer troubleshooting CFS errors.

5. Failure to configure LDAP or other failures due to no default route.

   If the CAN wasn't configured due to an error, or no default route is set on the UAN with `uan_interfaces`, that could lead to errors later in CFS. For example, the LDAP server may not be accessible or PE and WLM are not able to access artifacts.

   If the CAN isn't configured, even though it was enabled, turn on the extra debugging in the previous step and check for an `NXDOMAIN` error. If an NXDOMAIN error is found, that would cause the play to skip setting up the CAN because an IP address could not be found for the correct alias.

   Log in to the UAN and run the following to check if an appropriate CAN alias can be found:
   ```bash
   uan# nslookup ${HOSTNAME/-nmn/-can}.can
   Server:		10.92.100.225
   Address:	10.92.100.225#53

   Name:	uan01.can
   Address: 10.102.10.14
   ```

   If the logs or the above command shows an NXDOMAIN error, consult the CSM documentation titled "Add UAN CAN IP Addresses to SLS" to add an appropriate alias and rerun CFS.
