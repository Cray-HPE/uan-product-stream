# Cray EX User Access Nodes Operational Tasks

> version: @product_version@
>
> build date: @date@

This section describes the procedures for operational (non-installation) tasks
required to properly configure and boot User Access Nodes (UAN).

---

## Contents

* [Overall Workflow](#workflow)
* [UAN Image Pre-boot Configuration](#preboot)
* [Configuring UAN images](#imgconfiguration)
* [Preparing UAN Boot Session Templates](#bostemplate)
* [Booting UAN Nodes](#bootuan)
* [Slingshot Diagnostics](#slingshotdiags)

---

<a name="workflow"></a>
## Overall Workflow

The overall workflow for preparing UAN images for boot is as follows:

1. Clone the UAN configuration git repository and create a new branch based on
   the branch imported by the UAN installation.
1. Update the configuration content and push the changes to the newly created
   branch.
1. Create a CFS configuration for the UANs, specifying the git configuration and
   the UAN image to apply the configuration to. Additional Cray products can
   also be added to the CFS configuration for the UANs to install multiple
   Cray products into the UAN image at the same time.
1. Configure the UAN image using CFS and generate a newly configured version of
   the UAN image.
1. Create a Boot Orchestration Service (BOS) boot session template for the UANs.
   This template maps the configured image, the CFS configuration to be applied
   post-boot, and the nodes which will receive the image and configuration.
1. UANs are now ready to be booted by creating a BOS session from the boot
   session template.

**NOTE**: This guide details how to apply UAN-specific configuration to the
          UAN image and nodes. Consult the manuals for the individual Cray
          products (e.g. workload managers, Cray Programming Environment, etc)
          that should be configured on the UANs.

<a name="preboot"></a>
## UAN Image Customization (Workaround to Enable required systemd services CASMCMS-6636)

1. Create an IMS job to customize the UAN image rootfs by following the procedures in the
   ***HPE Cray EX System Administration Guide*** section ***11.4 Customize an Image Root Using IMS***.

1. SSH to the IMS image customization host (IMS_SSH_HOST) and edit the following file in the image.

   1. Edit `/usr/lib/systemd/system-preset/89-cray-uan-default.preset` and ensure it has the following
      content.

   ```bash
   #
   # Copyright 2020-2021 Hewlett Packard Enterprise Development LP
   #
   # Cray services
   enable amd-fix-xGMI-width.service
   enable cfs-state-reporter.service
   enable cray-heartbeat.service
   enable cray-hugepage-setup.service
   enable cray-memory-spread.service
   enable cray-node-identity.service
   enable cray-orca.service
   enable cray-power-mon.service
   enable cray-printk.service
   enable jacsd.service
   enable kdump-spire-watcher.service
   enable mlx-set-irq-affinity.service
   enable palsd.service
   enable cray-switchboard-sshd.service
   # non-Cray services
   enable acpid.service
   enable chronyd.service
   disable firewalld.service
   enable kdump.service
   enable ldmsd-bootstrap.service
   enable msr-safe.service
   enable ras-mc-ctl.service
   enable rasdaemon.service
   enable spire-agent.service
   enable sshd.service
   enable wicked.service
   ```

1. Run `/tmp/images.sh` in the image chroot before exiting the image to rebuild the initrd.

1. Follow the remaining instructions in section ***11.4 Customize an Image Root Using IMS*** to
   complete the image customization.  

   **NOTE** Be sure to record the new resultant image ID for use in the
            in the remaining procedures where an image is referenced.

## UAN Image Pre-boot Configuration

1. Clone the UAN configuration management repository. The repository is located
   in the VCS/Gitea service and the location is reported in the
   `cray-product-catalog` Kubernetes ConfigMap in the `clone_url` key. Replace
   the hostname with `api-gw-service-nmm.local` when cloning the repository.

   ```bash
   ncn-m001:~/ $ git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
   # [... output removed ...]

   ncn-m001:~/ $ cd uan-config-management && git checkout cray/uan/@product_version@ && git pull
   Branch 'cray/uan/@product_version@' set up to track remote branch 'cray/uan/@product_version@' from 'origin'.
   Already up to date.
   ```

1. Create a branch using the imported branch from the installation to customize
   the UAN image. This imported branch will be reported in the
   `cray-product-catalog` Kubernetes ConfigMap in the `import_branch` key under the UAN section. The
   format is `cray/uan/@product_version@`. In this guide, an `integration`
   branch is used for examples.

    **WARNING**: _You cannot make changes to the `cray/uan/@product_version@`
                 branch that was created by the UAN installation. By default,
                 modification is not allowed on this branch._

   ```bash
   ncn-m001:~/ $ git checkout -b integration && git merge cray/uan/@product_version@
   Switched to a new branch 'integration'
   Already up to date.
   ```

   ***WORKAROUND FOR UAN NETWORKING (CASMCMS-6644)***

1. Apply uan_interfaces role workaround and group_vars needed for UAN CAN and LDAP support.  

   1. Copy the `uan_interfaces.tgz` and `group_vars.tgz` files from CSS to the top
      of the UAN configuration management repository. Use your Data Center credentials.
      dclogin may not be available from your particular machine. You may need to download
      it onto your laptop first and then push it up to the machine.

      ##FIXEME## We need to put these files someplace accessible from the installation 
      machine.

      ```bash
      ncn-m001:~/ $ scp <dc_username>@dclogin:/cray/css/users/keopp/uan/*.tgz .
      ```

   1. Expand the two tar files to install the workaround.

      ```bash
      ncn-m001:~/ $ tar zxf uan_interfaces.tgz
      ncn-m001:~/ $ tar zxf group_vars.tgz
      ```

   1. Apply the uan_interfaces role workaround to the Ansible configuration.

      ```bash
      ncn-m001:~/ $ git add group_vars/all/can.yml
      ncn-m001:~/ $ git add group_vars/all/ldap.yml
      ncn-m001:~/ $ git add roles/uan_interfaces/defaults/main.yml
      ncn-m001:~/ $ git add roles/uan_interfaces/files/ifcfg-nmn0
      ncn-m001:~/ $ git add roles/uan_interfaces/tasks/main.yml
      ncn-m001:~/ $ git add roles/uan_interfaces/tasks/can-v2.yml
      ncn-m001:~/ $ git add roles/uan_interfaces/templates/can-down.j2
      ncn-m001:~/ $ git add roles/uan_interfaces/templates/can-up.j2
      ncn-m001:~/ $ git add roles/uan_interfaces/templates/ifcfg-vlan007.j2
      ncn-m001:~/ $ git add roles/uan_interfaces/templates/ifroute-vlan007.j2
      ncn-m001:~/ $ git commit -m "Apply CAN workaround and LDAP config"
      ```

   1. Push the changes to the repository using the proper credentials.

      ```bash
       ncn-m001:~/ $ git push --set-upstream origin integration
       Username for 'https://api-gw-service-nmn.local': crayvcs
       Password for 'https://crayvcs@api-gw-service-nmn.local':
       # [... output removed ...]
       remote: Processed 1 references in total
       To https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
        * [new branch]      integration -> integration
        Branch 'integration' set up to track remote branch 'integration' from 'origin'.
      ```

      Obtain the password for the `crayvcs` user from the Kubernetes secret.

      ```bash
      ncn-m001:~/ $ kubectl get secret -n services vcs-user-credentials \
                    --template={{.data.vcs_password}} | base64 --decode
   
      # <== password output ==>
      ```

1. Apply any customizations and modifications to the Ansible configuration.
   Variables should be defined and overridden in the Ansible inventory locations
   of the repository and **not** in the Ansible plays and roles defaults. The
   following example shows how to add a `vars.yml` file to the `Application`
   group variables file.

   ```bash
    ncn-m001:~/ $ vim group_vars/Application/vars.yml
    ncn-m001:~/ $ git add group_vars/Application/vars.yml
    ncn-m001:~/ $ git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
    1 file changed, 1 insertion(+)
    create mode 100644 group_vars/Application/vars.yml
   ```

   ##FIXME## - UAN ansible configuration guide - listing role parameters to help
               the user with Ansible configuration for UAN roles.

   See the [Ansible Best Practices Guide](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#content-organization)
   with directory layouts for inventory.

1. Push the changes to the repository using the proper credentials.

   ```bash
    ncn-m001:~/ $ git push --set-upstream origin integration
    Username for 'https://api-gw-service-nmn.local': crayvcs
    Password for 'https://crayvcs@api-gw-service-nmn.local':
    # [... output removed ...]
    remote: Processed 1 references in total
    To https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
     * [new branch]      integration -> integration
     Branch 'integration' set up to track remote branch 'integration' from 'origin'.
   ```

   Obtain the password for the `crayvcs` user from the Kubernetes secret.

   ```bash
   ncn-m001:~/ $ kubectl get secret -n services vcs-user-credentials \
                     --template={{.data.vcs_password}} | base64 --decode
   
   # <== password output ==>
   ```

1. Capture the most recent commit for reference in setting up a CFS
   configuration and navigate to the parent directory.

   ```bash
   ncn-m001:~/ $ git rev-parse --verify HEAD

   ecece54b1eb65d484444c4a5ca0b244b329f4667

   ncn-m001:~/ $ cd ..
   ```

<a name="imgconfiguration"></a>
## Configuring UAN images

After the configuration parameters have been stored in a branch in the UAN git
repository, invoke the Configuration Framework Service (CFS) to customize the
image.

1. Create a JSON input file for generating a CFS configuration for the UAN.

   **NOTE**: This configuration can be used for pre-boot image customization as
             well as post-boot node configuration.

   **NOTE**: Gather the git repository clone URL, commit, and top-level play
             for each configuration layer (i.e. Cray product) and add them to
             the CFS configuration for the UAN, if desired. See the product
             manuals for further information on configuring other Cray products.

   ```bash
   ncn-m001:~/ $ cat uan-config-@product_version@.json
   {
     "layers": [
       {
         "name": "uan-integration-@product_version@",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
         "playbook": "site.yml",
         "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667"
       }
       # { ... add configuration layers for other products here, if desired ... }
     ]
   }
   ```

1. Add the configuration to CFS using the JSON input file.

   Note: The uan-config-@product_version@ is an input parameter that you get to
   set yourself.

    ```bash
    ncn-m001:~/ $ cray cfs configurations update uan-config-@product_version@ \
                      --file ./uan-config-@product_version@.json \
                      --format json
    {
      "lastUpdated": "2021-07-28T03:26:00:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667",
          "name": "uan-integration-@product_version@",
          "playbook": "site.yml"
        }  # <-- Additional layers not shown
      ],
      "name": "uan-config-@product_version@"
    }
    ```

1. Create a CFS session to do pre-boot image customization of the UAN image.

   Retrieve the image ID (stored in the Image Management Service (IMS)) from the
   product catalog and the CFS configuration name from the previous step.

    ```bash
    ncn-m001:~/ $ cray cfs sessions create --name uan-config-@product_version@ \
                      --configuration-name uan-config-@product_version@ \
                      --target-definition image \
                      --target-group Application c880251d-b275-463f-8279-e6033f61578b
                      --format json

    # <== output removed ==>
    ```

1. When the CFS configuration session for the image customization has completed,
   record the ID of the IMS image that was created as a result of the
   customization.

    ```bash
    ncn-m001:~/ $ cray cfs sessions describe uan-config-@product_version@ --format json | jq -r .status.artifacts[].result_id

    0e54050a-c43c-4534-ba38-7191838e348d
    ```

<a name="bostemplate"></a>
## Preparing UAN Boot Session Templates

1. Construct a BOS boot session template for the UAN using the xnames of the
   Application nodes, the customized image ID from the previous section, and
   the CFS configuration session name from the previous section.

   **FIXME** Determine if this is the default/good session template

   **NOTE** The value for **nmn0_netdev** in the kernel_parameters string must be set to **net0** for UAN
            hardware with one PCIe card installed.  It must be set to **net2** when a second PCI
            card is installed, regardless of whether or not it is being used.

   ```bash
    ncn-m001:~/ $ cat uan-sessiontemplate-@product_version@.json

    {
      "boot_sets": {
        "uan": {
          "boot_ordinal": 2,
          "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=1 rd.shell turbo_boost_limit=999 ifmap=net0:nmn0 spire_join_token=${SPIRE_JOIN_TOKEN}",
          "network": "nmn",
          "node_list": [
            # [ ... List of Application Nodes ...]
          ],
          "path": "s3://boot-images/0e54050a-c43c-4534-ba38-7191838e348d/manifest.json",  # <-- replace with image id from image customization
          "rootfs_provider": "cpss3",
          "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
          "type": "s3"
        }
      },
      "cfs": {
          "configuration": "uan-config-@product_version@"
      },
      "enable_cfs": true,
      "name": "uan-sessiontemplate-@product_version@"
    }
   ```

   **NOTE**: Retrieve the xnames of the UAN nodes from the Hardware State
             Manager (HSM).

    ```bash
    ncn-m001:~ $ cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID

    x3000c0s19b0n0
    x3000c0s24b0n0
    x3000c0s20b0n0
    x3000c0s22b0n0
    ```

1. Register the session template with BOS.

    ```bash
     ncn-m001:~/ $ cray bos v1 sessiontemplate create \
                       --name uan-sessiontemplate-@product_version@ \
                       --file uan-sessiontemplate-@product_version@.json

     /sessionTemplate/uan-sessiontemplate-@product_version@
    ```

<a name="bootuan"></a>
## Booting UAN Nodes

1. Create a BOS session to boot the UAN nodes.

    ```bash
    ncn-m001:~/ $ cray bos v1 session create --template-uuid uan-sessiontemplate-@product_version@ --operation reboot
    ```

1. Retrieve the BOS session id from the previous command.

    ```bash
    ncn-m001:~/ $ BOS_SESSION=89680d0a-3a6b-4569-a1a1-e275b71fce7d
    ```

1. Retrieve the Boot Orchestration Agent (BOA) Kubernetes job name for the BOS session.

    ```bash
    ncn-m001:~/ $ BOA_JOB_NAME=$(cray bos v1 session describe $BOS_SESSION --format json | jq -r .boa_job_name)
    ```

1. Retrieve the Kuberenetes pod name for the BOA assigned to run this session.

    ```bash
    ncn-m001:~/ $ BOA_POD=$(kubectl get pods -n services -l job-name=$BOA_JOB_NAME --no-headers -o custom-columns=":metadata.name")
    ```

1. View the logs for the BOA to track session progress.

    ```bash
    ncn-m001:~/ $ kubectl logs -f -n services $BOA_POD -c boa
    ```

1. Once the BOA progresses to the point of kicking off CFS session(s) (assuming
   CFS was enabled in the boot session template), find the relevant sessions
   that are currently running. `pending` and `complete` are also valid statuses
   to filter on.

    ```bash
    ncn-m001:~/ $ cray cfs sessions list --tags bos_session=$BOS_SESSION --status running --format json
    ```

<a name="slingshotdiags"></a>
## Slingshot Diagnostics

The default UAN image/recipe includes the Slingshot Diagnostics package, but
that RPM is not included in the release.  This leads to several different
scenarios with respect to using the default image/recipe and how to take
advantage of the diagnostics if needed.

If the user wishes to build a new UAN image based on the default recipe, the
lines including the Slingshot Diagnostics RPM must be removed.
1. Edit `images/kiwi-ng/cray-sles15sp1-uan-cos/config-template.xml.j2` and remove
   the lines:
   ```bash
        <!-- SECTION: Slingshot Diagnostic package -->
        <package name="cray-diags-fabric"/>
   ```

1. Continue with the other recipe modifications as outlined in the 
   ***HPE Cray EX System Administration Guide*** sections
   ***11.2 Upload and Register an Image Recipe***,
   ***11.3 Build an Image Using IMS REST Service***, and 
   ***11.4 Customize an Image Root Using IMS***.

If the user wishes to include the Slingshot Diagnosic package but also make
modifications to the default image, the default image may be customized by
using the procedure described in ***HPE Cray EX System Administration Guide***
section ***11.4 Customize an Image Root Using IMS***.
