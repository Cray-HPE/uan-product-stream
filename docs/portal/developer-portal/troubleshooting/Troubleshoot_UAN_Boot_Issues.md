
# Troubleshoot UAN Boot Issues

## The UAN boot process

BOS boots UANs. BOS uses session templates to define various parameters such as:

- Which nodes to boot
- Which image to boot
- Kernel parameters
- Whether to perform post-boot configuration \(Node Personalization\) of the nodes by CFS.
- Which CFS configuration to use if Node Personalization is enabled.

UAN boots are performed in three phases:

1. PXE booting an iPXE binary that will load the initrd of the UAN image that will boot.
2. Booting the initrd \(dracut\) image which configures the UAN for booting the UAN image. This process consists of two phases.
    1. Configuring the UAN node to use the Content Projection Service \(CPS\) and Data Virtualization Service \(DVS\). These services manage the UAN image rootfs mounting and make that image available to the UAN nodes.
    2. Mounting the rootfs
3. Booting the UAN image rootfs.

## PXE Issues

Most PXE boot failures are the result of misconfigured network switches and/or BIOS settings. The UAN must PXE boot over the Node Management Network \(NMN\) and the switches must be configured to allow connectivity to the NMN. The cable for the NMN must be connected to the first port of the OCP card on HPE DL325 and DL385 servers or to the first port of the built-in LAN-On-Motherboard \(LOM\) on Gigabyte servers. See "Prepare for UAN Product Installation" in the UAN Installation Guide for details on the switch and BIOS settings required to configure the UAN for PXE booting.

UANs may fail to boot when the BIOS EFITIME is too far away from the time on management nodes. If there are x509 certificate problems, check that the BIOS time is correct. See "Configure the BIOS of an HPE UAN" or "Configure the BIOS of a Gigabyte UAN" in the UAN Installation Guide for examples of checking settings in the BIOS.

## Initrd \(Dracut\) Issues

Dracut failures are often caused by the wrong interface being named `nmn0`, or to multiple entries for the UAN xname in DNS. The latter is a result of multiple interfaces making DHCP requests. Either condition can cause IP address mismatches in the `dvs_node_map`. DNS configures entries based on DHCP leases.

When dracut starts, it renames the network device named by the `ifmap=netX:nmn0` kernel parameter to `nmn0`. This interface is the only one dracut will enable DHCP on. The `ip=nmn0:dhcp` kernel parameter limits dracut to DHCP only `nmn0`. The ifmap value must be set correctly in the `kernel_parameters` field of the BOS session template.

See [Create UAN Boot Images](../operations/Create_UAN_Boot_Images.md#create-uan-boot-images) for details on how to configure the BOS session template. For UAN nodes that have more than one PCI card installed, `ifmap=net2:nmn0` is the correct setting. If only one PCI card is installed, `ifmap=net0:nmn0` is normally the correct setting.

UANs require CPS and DVS to boot from images. These services are configured in dracut to retrieve the rootfs and mount it. If the image fails to download, check that DVS and CPS are both healthy, and DVS is running on all worker nodes. Run the following commands to check DVS and CPS:

```bash
ncn-m001#  kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers
ncn-w001
ncn-w002
ncn-m001#  for node in `kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" \
--no-headers`; do
ssh $node "lsmod | grep '^dvs '"
done
ncn-w001
ncn-w002
```

If DVS and CPS are both healthy, then both of these commands will return all the worker NCNs in the HPE Cray EX system.

## Image Boot Issues

Once dracut exits, the UAN will boot the `rootfs` image. Failures seen in this phase tend to be failures of `spire-agent`, `cfs-state-reporter`, or both. The `cfs-state-reporter` tells BOA that the node is ready and allows BOA to start CFS for Node Personalization. If `cfs-state-reporter` does not start, check if the `spire-agent` has started. The `cfs-state-reporter` depends on the `spire-agent`. Running systemctl status spire-agent will show that that service is enabled and running if there are no issues with that service. Similarly, running `systemctl status cfs-state-reporter` will show a status of SUCCESS.

```bash
uan# systemctl status spire-agent
● spire-agent.service - SPIRE Agent
   Loaded: loaded (/usr/lib/systemd/system/spire-agent.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2021-02-24 14:27:33 CST; 19h ago
 Main PID: 3581 (spire-agent)
    Tasks: 57
   CGroup: /system.slice/spire-agent.service
           └─3581 /usr/bin/spire-agent run -expandEnv -config /root/spire/conf/spire-agent.conf

uan# systemctl status cfs-state-reporter
● cfs-state-reporter.service - cfs-state-reporter reports configuration level of the system
   Loaded: loaded (/usr/lib/systemd/system/cfs-state-reporter.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Wed 2021-02-24 14:29:51 CST; 19h ago
 Main PID: 3827 (code=exited, status=0/SUCCESS)
```

There may be errors related to failing to load kernel modules during the boot:

```bash
FAILED Failed to start Load Kernel Modules.
See 'systemctl status systemd-modules-load.service' for details.
```

Provided the UAN boots and completes post boot customizations, these messages may be ignored.
