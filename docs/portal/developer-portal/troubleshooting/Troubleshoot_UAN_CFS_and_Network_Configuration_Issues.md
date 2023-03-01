
# Troubleshoot UAN CFS and Network Configuration Issues

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

    NMN and CAN/CHN network setup errors can also result from incorrect switch configuration and network cabling.
