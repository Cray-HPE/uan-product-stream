# Cray EX User Access Nodes Operational Tasks

> version: @product_version@
>
> build date: @date@

This section describes the procedures for operational (non-installation) tasks
required to properly configure and boot User Access Nodes (UAN).

---

## Contents

* [Overall Workflow](#workflow)
* [UAN Product Catalog Entry](#catalog)
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

<a name="catalog"></a>
## UAN Product Catalog Entry

Upon successful installation of the UAN product, the UAN configuration, image
recipe(s), and pre-built boot image(s) are catalogued in the `cray-product-catalog`
Kubernetes ConfigMap.

```bash
ncn-m001:~ $ kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
@product_version@:
  configuration:
    clone_url: https://vcs.<domain>/vcs/cray/uan-config-management.git # <--- Gitea clone url
    commit: 6658ea9e75f5f0f73f78941202664e9631a63726                   # <--- Git commit id
    import_branch: cray/uan/@product_version@                          # <--- Git branch with configuration
    import_date: 2021-02-02 19:14:18.399670
    ssh_url: git@vcs.<domain>:cray/uan-config-management.git
  images:
    cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       # <--- IMS image name
      id: c880251d-b275-463f-8279-e6033f61578b                         # <--- IMS image id
  recipes:
    cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       # <--- IMS recipe name
      id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a                         # <--- IMS recipe id
```

<a name="preboot"></a>
## UAN Image Pre-boot Configuration

1. Clone the UAN configuration management repository. The repository is located
   in the VCS/Gitea service and the location is reported in the
   `cray-product-catalog` Kubernetes ConfigMap in the `configuration.clone_url`
   key. Replace the hostname with `api-gw-service-nmm.local` when cloning the
   repository.

   ```bash
   ncn-m001:~/ $ git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
   # [... output removed ...]

   ncn-m001:~/ $ cd uan-config-management && git checkout cray/uan/@product_version@ && git pull
   Branch 'cray/uan/@product_version@' set up to track remote branch 'cray/uan/@product_version@' from 'origin'.
   Already up to date.
   ```

1. Create a branch using the imported branch from the installation to customize
   the UAN image. This imported branch will be reported in the
   `cray-product-catalog` Kubernetes ConfigMap in the `configuration.import_branch`
   key under the UAN section. The format is `cray/uan/@product_version@`. In
   this guide, an `integration` branch is used for examples, but the name can
   be any valid git branch name.

    **WARNING**: _You cannot make changes to the `cray/uan/@product_version@`
                 branch that was created by the UAN installation. By default,
                 modification is not allowed on this branch._

   ```bash
   ncn-m001:~/ $ git checkout -b integration && git merge cray/uan/@product_version@
   Switched to a new branch 'integration'
   Already up to date.
   ```

1. Apply site-specific customizations and modifications to the Ansible
   configuration for the UAN nodes and commit the changes.

   The default Ansible play to configure UAN nodes is located in the base of the
   `uan-config-management` repository in `site.yml`. The roles that are executed
   in this play allow for non-default configuration as required for the system.

   Consult the individual Ansible role `README.md` files in the
   `uan-config-management` repository `roles` directory for information on
   configuring individual role variables. Roles prefixed with `uan_` are
   specific to UAN configuration and include network interfaces, disk, LDAP,
   software packages, and message of the day roles.

   Variables should be defined and overridden in the Ansible inventory locations
   of the repository as shown below and **not** in the `site.yml` play and role
   default files. See the [Ansible Best Practices Guide](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#content-organization)
   with directory layouts for inventory.

   The following example shows adding a sample `vars.yml` file containing
   site-specific configuration values to the `Application` group variable
   location.

   ```bash
    ncn-m001:~/ $ vim group_vars/Application/vars.yml
    ncn-m001:~/ $ git add group_vars/Application/vars.yml
    ncn-m001:~/ $ git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
    1 file changed, 1 insertion(+)
    create mode 100644 group_vars/Application/vars.yml
   ```

1. Obtain the password for the `crayvcs` user from the Kubernetes secret for use
   in the next command.

   ```bash
   ncn-m001:~/ $ kubectl get secret -n services vcs-user-credentials \
                     --template={{.data.vcs_password}} | base64 --decode
   # <== password output ==>
   ```

1. Push the changes to the repository using the proper credentials.

   ```bash
    ncn-m001:~/ $ git push --set-upstream origin integration
    Username for 'https://api-gw-service-nmn.local': crayvcs
    Password for 'https://crayvcs@api-gw-service-nmn.local':  # <-- from previous command
    # [... output removed ...]
    remote: Processed 1 references in total
    To https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
     * [new branch]      integration -> integration
     Branch 'integration' set up to track remote branch 'integration' from 'origin'.
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
             the CFS configuration for the UAN, if desired. This guide shows
             only the configuration of the UAN, but additional layers can be
             added to configure them in a single CFS session. See the product
             manuals for further information on configuring other Cray products.

   ```bash
   ncn-m001:~/ $ cat uan-config-@product_version@.json
   {
     "layers": [
       {
         "name": "uan-integration-@product_version@",
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
         "playbook": "site.yml",
         "commit": "<git commit id>"  # <--- From git rev-parse command in previous section
       }
       # { ... add configuration layers for other products here, if desired ... }
     ]
   }
   ```

1. Add the configuration to CFS using the JSON input file.

    ```bash
    ncn-m001:~/ $ cray cfs configurations update uan-config-@product_version@ \
                      --file ./uan-config-@product_version@.json \
                      --format json
    {
      "lastUpdated": "2021-07-28T03:26:00:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "commit": "<git commit id",
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
                      --target-group Application <IMS image ID> \  # <--- from product catalog
                      --format json

    # <== output removed ==>
    ```

    ***WORKAROUND FOR CFS SESSION NOT COMPLETING (CASMCMS-6699)***
   
    Due to an issue with the CFS teardown container, CFS Sessions targeting IMS images will
    not complete without manual intervention. Follow the steps below to set the IMS `complete`
    flag. Once setting the `complete` flag, CFS should complete successfully.
   
    1. Locate the pod performing the CFS customizations
    
       ```bash   
       # kubectl get pods -n services | grep $(cray cfs sessions describe uan-config-1.9.9 --format json | jq -r '.status.session.job') | awk '{print $1}'
       cfs-fa57cde4-d01e-4512-9687-1c0c7db28ea7-fwmxk
       ```
   
    1. Watch the `ansible-0` container and wait for ansible to complete successfully.
       
       ```bash
       # kubectl logs -n services -f cfs-fa57cde4-d01e-4512-9687-1c0c7db28ea7-fwmxk -c ansible-0
       ...
       PLAY RECAP *********************************************************************
       cray-shasta-uan-cos-sles15sp1.x86_64-0.1.21-ecozzi_cfs_uan-config-1.9.9 : ok=35   changed=21   unreachable=0    failed=0    skipped=103  rescued=0    ignored=0
       ```
       
    1. Determine the IMS Pod being used to customize the image
       
       ```bash
       ncn-m001:~ # kubectl logs -n services -f cfs-fa57cde4-d01e-4512-9687-1c0c7db28ea7-fwmxk -c inventory | grep -m 1 job
       2021-02-15 21:33:12,705 - INFO    - cray.cfs.inventory.image - IMS status=creating for IMS image='08350e63-bf31-48a6-a9aa-25986cdaec97' job='ff27bf2c-9420-4379-989e-eedccd8b962a'. Elapsed time=0s
       ncn-m001:~ # IMS_JOB=ff27bf2c-9420-4379-989e-eedccd8b962a
       ncn-m001:~ # kubectl get pods -n ims | grep -m 1 $IMS_JOB
       cray-ims-ff27bf2c-9420-4379-989e-eedccd8b962a-customize-zd7vt   0/2     Running   0          32m
       ```
       
    1. Access the IMS Customizations pod and touch the complete flag. Note: CFS uses an IMS Jailed environment
       so the location of the complete flag is `/mnt/image/image-root/tmp/complete`.
       
       ```bash
       # kubectl exec -it -n ims cray-ims-ff27bf2c-9420-4379-989e-eedccd8b962a-customize-zd7vt -c sshd -- sh
       sh-4.4# touch /mnt/image/image-root/tmp/complete
       ```

1. When the CFS configuration session for the image customization has completed,
   record the ID of the IMS image that was created as a result of the
   customization.

    ```bash
    ncn-m001:~/ $ cray cfs sessions describe uan-config-@product_version@ --format json | jq -r .status.artifacts[].result_id

    0e54050a-c43c-4534-ba38-7191838e348d
    ```

    Retain this ID value for crafting a BOS session template in the next section.

<a name="bostemplate"></a>
## Preparing UAN Boot Session Templates

1. Retrieve the xnames of the UAN nodes from the Hardware State Manager (HSM).

    ```bash
    ncn-m001:~ $ cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID

    x3000c0s19b0n0
    x3000c0s24b0n0
    x3000c0s20b0n0
    x3000c0s22b0n0
    ```

    Retain these node names for crafting a BOS session template in the next step.

1. Construct a BOS boot session template for the UAN using the xnames of the
   Application nodes, the customized image ID from the previous section, and
   the CFS configuration session name from the previous section.

   **NOTE** The value for **ifmap=netX:nmn0** in the kernel_parameters string must be set accordingly
            for the following UAN configurations.  It is normally going to be **ifmap=net2:nmn0** on UANs
            that are also configured to use the CAN network.
   - **ifmap=net0:nmn0**
     - HPE DL325 or DL385 Hardware:
       - A single OCP PCIe card is installed
     - Gigabyte Hardware
       - No additional PCIe cards installed other than the built-in LOM ports
   - **ifmap=net2:nmn0**
     - HPE DL325 or DL385 Hardware:
       - A second PCIe card installed regardless of whether it is being used
     - Gigabyte Hardware
       - A PCIe card is installed in addition to the built-in LOM ports regardless of whether it is being used

   ```bash
    ncn-m001:~/ $ cat uan-sessiontemplate-@product_version@.json

    {
      "boot_sets": {
        "uan": {
          "boot_ordinal": 2,
          "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0 spire_join_token=${SPIRE_JOIN_TOKEN}",
          "network": "nmn",
          "node_list": [
            # [ ... List of Application Nodes from cray hsm state command ...]
          ],
          "path": "s3://boot-images/<IMS image id>/manifest.json",  # <-- result_id from CFS image customization session
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
    ncn-m001:~/ $ cray bos v1 session create --template-uuid uan-sessiontemplate-@product_version@ --operation reboot --format json | tee session.json

   {
     "links": [
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "jobId": "boa-89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "rel": "session",
         "type": "GET"
       },
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d/status",
         "rel": "status",
         "type": "GET"
       }
     ],
     "operation": "reboot",
     "templateUuid": "uan-sessiontemplate-@product_version@"
   }

    ```

1. Retrieve the BOS session id from the previous command's output.

    ```bash
    ncn-m001:~/ $ BOS_SESSION=$(jq -r '.links[] | select(.rel=="session") | .href' session.json | cut -d '/' -f4)

    ncn-m001:~/ $ echo $BOS_SESSION
    89680d0a-3a6b-4569-a1a1-e275b71fce7d
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
   ***HPE Cray EX System Administration Guide*** sections:
   * 11.2 Upload and Register an Image Recipe,
   * 11.3 Build an Image Using IMS REST Service, and 
   * 11.4 Customize an Image Root Using IMS.

If the user wishes to include the Slingshot Diagnosic package but also make
modifications to the default image, the default image may be customized by
using the procedure described in ***HPE Cray EX System Administration Guide***
section ***11.4 Customize an Image Root Using IMS***.
