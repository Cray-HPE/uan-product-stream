
## Troubleshoot Incorrect Time Set on UANs

Perform this procedure to resolve a `permission denied` error from iPXE by fixing the time set on the UAN.

If the time is not set correctly on the UAN, the `uan.yml` playbook fails in the `uan_bootstrap` role. Watch the console via `ipmitool sol` to see the error that an interface is getting configured, but the response from iPXE is a `permission denied` error.

1. Watch the console logs via `ipmitool sol` to verify the issue exists.

    The following is an example of the initial log output from the `uan_bootstrap` role. The `Configure UAN network boot` task fails.

    ```bash
    2020-04-17 23:10:11,288 p=2539766 u=root |  TASK [uan_bootstrap : Configure UAN network boot] . . .
    2020-04-17 23:10:11,288 p=2539766 u=root |  Friday 17 April 2020  23:10:11 +0000 (0:00:00.249)  . . .
    2020-04-17 23:10:11,655 p=2539766 u=root |  failed: [ncn-w001] (item=None) => changed=false
    censored: 'the output has been hidden due to the fact that ''no_log: true'' was specified for this
     result'
    2020-04-17 23:10:11,656 p=2539766 u=root |  fatal: [ncn-w001]: FAILED! => changed=false
    censored: 'the output has been hidden due to the fact that ''no_log: true'' was specified for this
     result'
    ```

    In the console output from the UAN, there will be a permission denied error similar to the following during the attempts to boot:

    ```bash
    Configuring (net0 a4:bf:01:28:9b:16)... ok
    net0 IPv4 lease: 10.2.0.6 mac: a4:bf:01:28:9b:16
    http://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript... Permission denied 
    (http://ipxe.org/020c618f)
    ```

2. Correct the system time in the system BIOS.

    1. Select to boot the system into BIOS.

        ```bash
        ncn-w001# ipmitool -U USERNAME -H HOSTNMAME -P PASSWORD \
        -I lanplus chassis bootdev bios
        ```

    2. Connect to the SOL.

    3. Correct the system time in the system BIOS.

3. Attempt to boot the UANs again after the system time has been corrected.

