# Booting an Application Node with a SLES Image (Technical Preview)

A SLES image is available for use with Application type nodes. This image is currently considered a "Technical Preview" as the initial support for booting with SLES Images without COS. This guide documents the procedure to boot and configure the new image as it currently differs from the standard COS-based image process in some ways.

The image is built with the same packer/qemu pipeline as Non-Compute-Node Images. Similarties may be noticed including the kernel and package versions.

## Limitations

As this is currently a "Technical Preview" of supporting SLES Images on Application Nodes, there are several limitations:

* S3 presigned URLs with an expiration limit for the rootfs must be created.
* BSS parameters must be set with `cray bss bootparameters replace ...`
* BOS Sessions and Templates are not supported.
* CFS Configurations that operate on COS and NCN images are not yet supported.
* CFS Node Personalization must be started manually.

## Overview

The following steps outline the process of configuring and booting an Application Node with the SLES Image.

  1. Determine the image to use.
    
  1. Configure the image with IMS/CFS (optional).

  1. Update BSS with the necessary parameters.

  1. Reboot the node.

  1. Run CFS Node Personalization (optional).

## Procedure

Perform the following steps to configure and boot a SLES image on an Application type node.

1. Log in to the master node `ncn-m001`. All commands in this procedure are run from the master node.

1. Verify the UAN release contains a SLES image.

    ```bash
    ncn-m001# UAN_RELEASE=2.5
    ncn-m001# sat showrev --filter 'product_name = uan' | grep $UAN_RELEASE
    ```

1. Select an Image to boot or customize.

    ```bash
    ncn-m001# APP_IMAGE_NAME=cray-application-sles15sp3.x86_64-0.1.0
    ncn-m001# APP_IMAGE_ID=$(cray ims images list --format json  | jq --arg APP_IMAGE_NAME "$APP_IMAGE_NAME" -r 'sort_by(.created) | .[] | select(.name == $APP_IMAGE_NAME ) | .id' | head -1)
    ncn-m001# cray ims images describe $APP_IMAGE_ID --format json
    {
      "created": "2022-08-24T20:07:27.263737+00:00",
      "id": "13964414-bbad-40e9-9e31-a3683010febb",
      "link": {
        "etag": "",
        "path": "s3://boot-images/13964414-bbad-40e9-9e31-a3683010febb/manifest.json",
        "type": "s3"
      },
      "name": "cray-application-sles15sp3.x86_64-0.1.0"
    }
    ```

1. Customize the image using SAT Bootprep. This will add a root password to the image as one is not included. If CFS is not going to be used on this node, this step is optional. Support for additional product layers will be added in subsequent releases.

    ```bash
    ncn-m001# cat bootprep-sles-uan.yml
    configurations:
    - name: sles-uan-configuration
      layers:
      - name: uan
        playbook: site.yml
        product:
          name: uan
          version: 2.5.3
          branch: integration
    
    images:
    - name: sles-uan-image
      ims:
        is_recipe: false
        name: cray-application-sles15sp3.x86_64-0.1.0
      configuration: sles-uan-configuration
      configuration_group_names:
      - Application
      - Application_UAN

    ncn-m001# sat bootprep run ./bootprep-sles-uan.yml
    ncn-m001# APP_IMAGE_NAME=sles-uan-image
    ncn-m001# APP_IMAGE_ID=$(cray ims images list --format json  | jq --arg APP_IMAGE_NAME "$APP_IMAGE_NAME" -r 'sort_by(.created) | .[] | select(.name == $APP_IMAGE_NAME ) | .id' | head -1)
    ncn-m001# cray ims images describe $APP_IMAGE_ID --format json
    {
      "created": "2022-08-25T20:07:27.263737+00:00",
      "id": "13964414-bbad-40e9-9e31-a36830101234",
      "link": {
        "etag": "",
        "path": "s3://boot-images/13964414-bbad-40e9-9e31-a36830101234/manifest.json",
        "type": "s3"
      },
      "name": "sles-uan-image"
    }
    ```

1. Create a presigned URL for the rootfs. This is needed for the node to boot in this release, in the future, this will be integrated into BSS and will not need to be performed. This URL will be valid for 1 hour and will need to be recreated if the node reboots after the URL expires. To set a longer expiration, adjust the "aws s3 presign" command accordingly.

    ```base
    ncn-m001# export AWS_ACCESS_KEY_ID=`kubectl get secrets -o yaml ims-s3-credentials -ojsonpath='{.data.access_key}' | base64 -d`
    ncn-m001# export AWS_SECRET_ACCESS_KEY=`kubectl get secrets -o yaml ims-s3-credentials -ojsonpath='{.data.secret_key}' | base64 -d`
    ncn-m001# alias aws="aws --endpoint-url http://rgw-vip"
    ncn-m001# ROOTFS_URL=$(aws s3 presign --expires-in 3600 s3://boot-images/$APP_IMAGE_ID/rootfs)
    ```

1. Select an Application UAN to boot with the image.

    ```bash
    ncn-m001# cray hsm state components list --role Application --subrole UAN --format json | jq -r '.Components | .[] | .ID'
    x3000c0s13b0n0
    x3000c0s15b0n0
    ncn-m001# NODE=x3000c0s13b0n0
    ```

1. Select a MAC address to use as the NMN interface.

    ```bash
    ncn-m001:~ # cray hsm inventory ethernetInterfaces list --component-id $NODE --format json | jq -r '.[] | "\(.Description) \t \(.MACAddress)"'
    Ethernet Interface Lan1 	 b4:2e:99:fd:45:c8
    Ethernet Interface Lan2 	 b4:2e:99:fd:45:c9
    ncn-m001:~ # MAC=b4:2e:99:fd:45:c8
    ```

1. Update BSS with the kernel, initrd, and desired parameters. 

    ```bash
    ncn-m001:~ # PARAMS="ifname=nmn0:$MAC ip=nmn0:dhcp spire_join_token=\${SPIRE_JOIN_TOKEN} biosdevname=1 pcie_ports=native transparent_hugepage=never console=tty0 console=ttyS0,115200 iommu=pt metal.no-wipe=1 initrd=initrd root=live:$ROOTFS_URL rd.live.ram=0 rd.writable.fsimg=0 rd.skipfsck rd.live.squashimg=filesystem.squashfs rd.live.overlay.thin=1 rd.live.overlay.overlayfs=1 rd.luks=0 rd.luks.crypttab=0 rd.lvm.conf=0 rd.lvm=1 rd.auto=1 rd.md=1 rd.dm=0 rd.neednet=0 rd.peerdns=1 rd.md.waitclean=1 rd.multipath=0 rd.md.conf=1 rd.bootif=0 hostname=$NODE rd.net.dhcp.retry=3 append nosplash quiet log_buf_len=1 rd.retry=10 rd.shell"
    ncn-m001:~ # cray bss bootparameters replace --hosts $NODE --initrd "s3://boot-images/$APP_IMAGE_ID/initrd" --kernel "s3://boot-images/$APP_IMAGE_ID/kernel" --params "$PARAMS"
    ```

1. Reboot the node. Wait for the status to return off before issuing the power on command.

    ```bash
    ncn-m001:# USERNAME=root
    ncn-m001:# read -r -s -p "$NODE BMC ${USERNAME} password: " IPMI_PASSWORD; echo
    ncn-m001:# export IPMI_PASSWORD
    ncn-m001:# ipmitool -U "${USERNAME}" -E -I lanplus -H ${NODE::-2} power off
    ncn-m001:# ipmitool -U "${USERNAME}" -E -I lanplus -H ${NODE::-2} power status
    ncn-m001:# ipmitool -U "${USERNAME}" -E -I lanplus -H ${NODE::-2} power on
    ```

1. Connect to the console for the node and verify it boots into multi-user mode. Find the correct pod by using `conman -q` to list the available connections in each pod.

    ```bash
    ncn-m001# kubectl exec -it -n services cray-console-node-0 -- conman -j $NODE
 
    ...
    2022-08-25 14:27:51 Welcome to SUSE Linux Enterprise High Performance Computing 15 SP3  (x86_64) - Kernel 5.3.18-150300.59.43-default (ttyS0).
    2022-08-25 14:27:51
    2022-08-25 14:27:51 x3000c0s13b0n0 login:
    ```

1. If the node does not complete the boot successfully, proceed to the troubleshooting section in this guide.

## Troubleshooting

Some general troublshooting tips may help in getting started using the SLES image.

### Dracut failures during booting

1. Could not find the kernel or the initrd. Verify the BSS bootparameters for the node. Specifically, check that the IMS Image ID is correct.

    ```bash
    http://rgw-vip.nmn/boot-images/13964414-bbad-40e9-9e31-a3683010febbasdf/kernel...HTTP 0x7f0fa808 status 404 Not Found
     No such file or directory (http://ipxe.org/2d0c618e)

    http://rgw-vip.nmn/boot-images/13964414-bbad-40e9-9e31-a3683010febbasdf/initrd...HTTP 0x7f0fa808 status 404 Not Found
     No such file or directory (http://ipxe.org/2d0c618e)
    ```

1. The presigned URL was generated incorrectly.

    ```bash
    2022-08-22 18:49:33 [    9.170981] dracut-initqueue[1427]: curl: (22) The requested URL returned error: 404 Not Found
    2022-08-22 18:49:33 [    9.191138] dracut-initqueue[1421]: Warning: Downloading 'http://rgw-vip/boot-images/c0d2d5fd-8354-4f21-a0ef-8ee2878cbde7/filesystem.squashfs?AWSAccessKeyId=I
    43RBLH07R65TRO3AL02&Signature=YLmTttUa2KT7qzKLemOd1zIsWlo%3D&Expires=1661273999' failed!
    2022-08-22 18:49:33 [    9.222966] dracut-initqueue[1411]: Warning: failed to download live image: error 0
    ```

1. No carrier detected on interface nmn0. Select a different MAC address to be assigned as nmn0.

    ```bash
    http://rgw-vip.nmn/boot-images/13964414-bbad-40e9-9e31-a3683010febb/kernel... ok
    http://rgw-vip.nmn/boot-images/13964414-bbad-40e9-9e31-a3683010febb/initrd... ok
    [    4.966173] dracut-initqueue[975]: Warning: Unable to retrieve metadata from server
    [    5.379611] dracut-initqueue[1130]: Warning: Unable to retrieve metadata from server
    [   10.547290] dracut-initqueue[1144]: Warning: No carrier detected on interface nmn0
    [   10.564694] dracut-initqueue[1393]: ls: cannot access '/tmp/leaseinfo.nmn0*': No such file or directory
    ...
    [   28.381198] dracut-initqueue[945]: Warning: dracut-initqueue timeout - starting timeout scripts
    [   28.400096] dracut-initqueue[945]: Warning: Could not boot.
    ```

1. The root filesystem doesn't won't download because the URL is too long. Regenerate the URL using the aws command.

    ```bash
    2022-08-03 19:41:52   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0Warning: Failed to create the file
    2022-08-03 19:41:52 [    9.842822] dracut-initqueue[1428]: Warning: rootfs?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=I43RBLH07R65T
    2022-08-03 19:41:52 [    9.862811] dracut-initqueue[1428]: Warning: RO3AL02%2F20220803%2F%2Fs3%2Faws4_request&X-Amz-Date=20220803T193518Z&
    2022-08-03 19:41:52 [    9.882714] dracut-initqueue[1428]: Warning: X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=9412c9eb0
    2022-08-03 19:41:52 [    9.902718] dracut-initqueue[1428]: Warning: 585604b3c8154376113c043fb41e3954cddc92a8d799e5176f8c140: File name
    2022-08-03 19:41:52 [    9.922710] dracut-initqueue[1428]: Warning: too long
    2022-08-03 19:41:52 [    9.938714] dracut-initqueue[1428]:
    2022-08-03 19:41:52   0 2020M    0 13977    0     0   524k      0  1:05:40 --:--:--  1:05:40  524k
    2022-08-03 19:41:52 [    9.958983] dracut-initqueue[1428]: curl: (23) Failed writing body (0 != 13977)
    2022-08-03 19:41:52 [    9.975166] dracut-initqueue[1422]: Warning: Downloading 'http://rgw-vip/boot-images/66c37928-6887-463e-8d9f-e4eec8089374/rootfs?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=I43RBLH07R65TRO3AL02%2F20220803%2F%2Fs3%2Faws4_request&X-Amz-Date=20220803T193518Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=9412c9eb0585604b3c8154376113c043fb41e3954cddc92a8d799e5176f8c140' failed!
    2022-08-03 19:41:52 [   10.019096] dracut-initqueue[1412]: Warning: failed to download live image: error 0
    ```

1. The presigned URL has expired or was generated incorrectly.

    ```bash
    [    9.787431] dracut-initqueue[1435]: curl: (22) The requested URL returned error: 403 Forbidden
    [    9.807724] dracut-initqueue[1429]: Warning: Downloading 'http://rgw-vip/boot-images/13964414-bbad-40e9-9e31-a3683010febb/rootfs?AWSAccessKeyId=I43RBLH07R65TRO3AL02&Signature=7%2FgOCotleoyLPGmeyG%2FFX8tpkWg%3D&Expires=1661523713' failed!
    ```

1. The dracut module livenet is missing from the initrd. Make sure the initrd was regenerated with `/srv/cray/scripts/common/create-ims-initrd.sh` if CFS was used.

    ```bash
    2022-08-24 14:48:53 [    5.784023] dracut: FATAL: Don't know how to handle 'root=live:http://rgw-vip/boot-images/e88ed416-5d58-4421-9013-fa2171ac11b8/rootfs?AWSAccessKeyId=I43RBLH07R65TRO3AL02&Signature=bL661kZHPyEgBsLLEuJHFz3zKVs%3D&Expires=1661438587'
    2022-08-24 14:48:53 [    5.805063] dracut: Refusing to continue
    ```

### Unable to log in to the node.

1.  The node is not up. Connect to the console and determine why the node has not booted, starting with the troubleshooting tips.

    ```bash
    ncn-m001:# ssh app01 
    ssh: connect to host uan01 port 22: No route to host
    ```

1. Unable to log in to the node with a password. No root password is defined in the image by default, one must be added via CFS or by modifying the squashfs filesystem.

    ```bash
    ncn-m001:# ssh app01
    Password:
    Password:
    Password:
    root@app01's password:
    Permission denied, please try again
    ```

### DHCP hostname is not set

1. If the node does not have a hostname assigned from DHCP, try verifying the DHCP settings and restarting wicked.

    ```bash
    x3000c0s13b0n0:~ # grep -R ^DHCLIENT_SET_HOSTNAME= /etc/sysconfig/network/dhcp
    DHCLIENT_SET_HOSTNAME="yes"
    x3000c0s13b0n0:# systemctl restart wicked
    x3000c0s13b0n0:# hostnamectl
       Static hostname: x3000c0s13b0n0
    Transient hostname: app01
             Icon name: computer-server
               Chassis: server
            Machine ID: 9bd0aacf29d04dd4827bc464121b130b
               Boot ID: af753b4e6fa9419bb14d55a029d0f526
      Operating System: SUSE Linux Enterprise High Performance Computing 15 SP3
           CPE OS Name: cpe:/o:suse:sle_hpc:15:sp3
                Kernel: Linux 5.3.18-150300.59.43-default
          Architecture: x86-64
    x3000c0s13b0n0:# hostname
    app01
    ```

### Spire is not running

1. Check the spire-agent logs for error messages.

    ```bash
    app01# systemctl status spire-agent
    ```
