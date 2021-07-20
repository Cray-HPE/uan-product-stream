
## Create UAN Boot Images

Update configuration management git repository to match the installed version of the UAN product. Then use that updated configuration to create UAN boot images and a BOS session template.

[Install the UAN Product Stream](Install_the_UAN_Product_Stream.md)

The UAN product stream must be installed. Refer to the publication *HPE Cray EX System Installation and Configuration Guide \(S-8000\)*.

- **OBJECTIVE**

    This procedure creates images for booting UANs.

- **LIMITATIONS**

    This guide only details how to apply UAN-specific configuration to the UAN image and nodes. Consult the manuals for the individual HPE products \(for example, workload managers and the HPE Cray Programming Environment\) that must be configured on the UANs.

This is the overall workflow for preparing UAN images for booting UANs:

1. Clone the UAN configuration git repository and create a branch based on the branch imported by the UAN installation.
2. Update the configuration content and push the changes to the newly created branch.
3. Create a Configuration Framework Service \(CFS\) configuration for the UANs, specifying the git configuration and the UAN image to apply the configuration to. More Cray products can also be added to the CFS configuration so that the UANs can install multiple Cray products into the UAN image at the same time.
4. Configure the UAN image using CFS and generate a newly configured version of the UAN image.
5. Create a Boot Orchestration Service \(BOS\) boot session template for the UANs. This template maps the configured image, the CFS configuration to be applied post-boot, and the nodes which will receive the image and configuration.

Once the UAN BOS session template is created, the UANs will be ready to be booted by a BOS session.

Replace PRODUCT\_VERSION and CRAY\_EX\_HOSTNAME in the example commands in this procedure with the current UAN product version installed \(See Step 1\) and the hostname of the HPE Cray EX system, respectively.

1. |UAN IMAGE PRE-BOOT CONFIGURATION|

2. Obtain the artifact IDs and other information from the `cray-product-catalog` Kubernetes ConfigMap. Record the information labeled in the following example.

    Upon successful installation of the UAN product, the UAN configuration, image recipes, and prebuilt boot images are cataloged in this ConfigMap. This information is required for this procedure.

    ```bash
    ncn-m001# kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
    PRODUCT_VERSION:
      configuration:
        clone_url: https://vcs.CRAY_EX_HOSTNAME/vcs/cray/uan-config-management.git **# <--- Gitea clone url**
        commit: 6658ea9e75f5f0f73f78941202664e9631a63726                   **# <--- Git commit id**
        import_branch: cray/uan/PRODUCT_VERSION                           **# <--- Git branch with configuration**
        import_date: 2021-02-02 19:14:18.399670
        ssh_url: git@vcs.CRAY_EX_HOSTNAME:cray/uan-config-management.git
      images:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       **# <--- IMS image name**
          id: c880251d-b275-463f-8279-e6033f61578b                         **# <--- IMS image id**
      recipes:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       **# <--- IMS recipe name**
          id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a                         **# <--- IMS recipe id**
    ```

3. Generate the password hash for the `root` user. Replace PASSWORD with the `root` password you wish to use.

    ```bash
    ncn-m001# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
    ```

4. Obtain the HashiCorp Vault `root` token.

    ```bash
    ncn-m001# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' \
    | base64 -d; echo
    ```

5. Write the password hash obtained in Step 2 to the HashiCorp Vault.

    The vault login command will request a token. That token value is the output of the previous step. The vault read secret/uan command verifies that the hash was stored correctly. This password hash will be written to the UAN for the `root` user by CFS.

    ```bash
    ncn-m001# kubectl exec -itn vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan root_password='HASH'
    vault read secret/uan
    ```

6. Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next command.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
    --template={{.data.vcs_password}} | base64 --decode
    ```

7. Clone the UAN configuration management repository. Replace CRAY\_EX\_HOSTNAME in clone url with **api-gw-service-nmn.local** when cloning the repository.

    The repository is in the VCS/Gitea service and the location is reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.clone_url` key. The CRAY\_EX\_HOSTNAME from the `clone_url` is replaced with `api-gw-service-nmn.local` in the command that clones the repository.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' from 'origin'.
    Already up to date.
    ```

8. Create a branch using the imported branch from the installation to customize the UAN image.

    This imported branch will be reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.import_branch` key under the UAN section. The format is cray/uan/PRODUCT\_VERSION. In this guide, an `integration` branch is used for examples, but the name can be any valid git branch name.

    Modifying the cray/uan/PRODUCT\_VERSION branch that was created by the UAN product installation is not allowed by default.

    ```bash
    ncn-m001# git checkout -b integration && git merge cray/uan/PRODUCT_VERSION
    Switched to a new branch 'integration'
    Already up to date.
    ```

9. Configure a root user in the UAN image by adding the encrypted password of the root user from /etc/shadow on an NCN worker to the file group\_vars/Application/passwd.yml. Skip this step if the root user is already configured in the image.

    Hewlett Packard Enterprise recommends configuring a root user in the UAN image for troubleshooting purposes. The entry for root user password will resemble the following example:

    ```bash
    root_passwd: $6$LmQ/PlWlKixK$VL4ueaZ8YoKOV6yYMA9iH0gCl8F4C/3yC.jMIGfOK6F61h6d.iZ6/QB0NLyex1J7AtOsYvqeycmLj2fQcLjfE1
    ```

10. Apply any site-specific customizations and modifications to the Ansible configuration for the UAN nodes and commit the changes.

    The default Ansible play to configure UAN nodes is site.yml in the base of the uan-config-management repository. The roles that are executed in this play allow for nondefault configuration as required for the system.

    Consult the individual Ansible role README.md files in the uan-config-management repository roles directory to configure individual role variables. Roles prefixed with uan\_ are specific to UAN configuration and include network interfaces, disk, LDAP, software packages, and message of the day roles.

    Variables should be defined and overridden in the Ansible inventory locations of the repository as shown in the following example and **not** in the Ansible plays and roles defaults. See https://docs.ansible.com/ansible/2.9/user\_guide/playbooks\_best\_practices.html\#content-organization for directory layouts for inventory.

    **Warning:** Never place sensitive information such as passwords in the git repository.

    The following example shows how to add a vars.yml file containing site-specific configuration values to the `Application_UAN` group variable location.

    These and other Ansible files do not necessarily need to be modified for UAN image creation.

    ```bash
    ncn-m001# vim group_vars/Application_UAN/vars.yml
    ncn-m001# git add group_vars/Application_UAN/vars.yml
    ncn-m001# git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
     1 file changed, 1 insertion(+)
     create mode 100644 group_vars/Application_UAN/vars.yml
    ```

11. Verify that the System Layout Service \(SLS\) and the uan\_interfaces configuration role refer to the Mountain Node Management Network by the same name. Skip this step if there are no Mountain cabinets in the HPE Cray EX system.

    1. Edit the roles/uan\_interfaces/tasks/main.yml file and change the line that reads `url: http://cray-sls/v1/search/networks?name=MNMN` to read `url: http://cray-sls/v1/search/networks?name=NMN_MTN`.

        The following excerpt of the relevant section of the file shows the result of the change.

        ```bash
        - name: Get Mountain NMN Services Network info from SLS
          local_action:
            module: uri
              url: http://cray-sls/v1/search/networks?name=NMN_MTN 
            method: GET
          register: sls_mnmn_svcs
          ignore_errors: yes 
        ```

    2. Stage and commit the network name change

        ```bash
        ncn-m# git add roles/uan_interfaces/tasks/main.yml
        ncn-m# git commit -m "Add Mountain cabinet support"
        ```

12. Push the changes to the repository using the proper credentials, including the password obtained previously.

    ```bash
    ncn-m001# git push --set-upstream origin integration
    Username for 'https://api-gw-service-nmn.local': crayvcs
     Password for 'https://crayvcs@api-gw-service-nmn.local':
     . . .
     remote: Processed 1 references in total
     To https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
      * [new branch]      integration -> integration
      Branch 'integration' set up to track remote branch 'integration' from 'origin'.
    ```

13. Capture the most recent commit for reference in setting up a CFS configuration and navigate to the parent directory.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    
    ecece54b1eb65d484444c4a5ca0b244b329f4667
    
    ncn-m001# cd ..
    ```

    The configuration parameters have been stored in a branch in the UAN git repository. The next phase of the process is initiating the Configuration Framework Service \(CFS\) to customize the image.


    **CONFIGURE UAN IMAGES**

15. Create a JSON input file for generating a CFS configuration for the UAN.

    Gather the git repository clone URL, commit, and top-level play for each configuration layer \(that is, Cray product\). Add them to the CFS configuration for the UAN, if wanted.

    For the commit value for the UAN layer, use the Git commit value obtained in the previous step.

    See the product manuals for further information on configuring other Cray products, as this procedure documents only the configuration of the UAN. More layers can be added to be configured in a single CFS session.

    The following configuration example can be used for preboot image customization as well as post-boot node configuration.

    ```json
    {
      "layers": [
        {
          "name": "uan-integration-PRODUCT_VERSION",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "playbook": "site.yml",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667"
        }
        # **{ ... add configuration layers for other products here, if desired ... }**
      ]
    }
    ```

16. Add the configuration to CFS using the JSON input file.

    In the following example, the JSON file created in the previous step is named uan-config-PRODUCT\_VERSION.json only the details for the UAN layer are shown.

    ```bash
    ncn-m001# cray cfs configurations update uan-config-PRODUCT_VERSION \
                      --file ./uan-config-PRODUCT_VERSION.json \
                      --format json
    {
      "lastUpdated": "2021-07-28T03:26:00:37Z",
      "layers": [
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
          "commit": "ecece54b1eb65d484444c4a5ca0b244b329f4667",
          "name": "uan-integration-PRODUCT_VERSION",
          "playbook": "site.yml"
        }  **# <-- Additional layers not shown, but would be inserted here**
      ],
      "name": "uan-config-PRODUCT_VERSION"
    }
    ```

18. Create a CFS session to perform preboot image customization of the UAN image.

    ```bash
    ncn-m001# cray cfs sessions create --name uan-config-PRODUCT_VERSION \
                      --configuration-name uan-config-PRODUCT_VERSION \
                      --target-definition image \
                      --target-group Application_UAN \
                      --format json
    ```

19. Wait until the CFS configuration session for the image customization to complete. Then record the ID of the IMS image created by CFS.

    The following command will produce output while the process is running. If the CFS session completes successfully, an IMS image ID will appear in the output.

    ```bash
    ncn-m001# cray cfs sessions describe uan-config-PRODUCT_VERSION --format json | jq
    ```

20. |PREPARE UAN BOOT SESSION TEMPLATES|

21. Retrieve the xnames of the UAN nodes from the Hardware State Manager \(HSM\).

    These xnames are needed for Step 20.

    ```bash
    ncn-m001# cray hsm state components list --role Application --subrole UAN --format json | jq -r .Components[].ID
    x3000c0s19b0n0
    x3000c0s24b0n0
    x3000c0s20b0n0
    x3000c0s22b0n0
    ```

22. Determine the correct value for the ifmap option in the `kernel_parameters` string for the type of UAN.

    - Use ifmap=net0:nmn0,lan0:hsn0,lan1:hsn1 if the UANs are:
        - Either HPE DL325 or DL385 server that have a single OCP PCIe card installed.
        - Gigabyte servers that do not have additional PCIe network cards installed other than the built-in LOM ports.
    - Use ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 if the UANs are:
        - Either HPE DL325 or DL385 servers which have a second OCP PCIe card installed, regardless if it is being used or not.
        - Gigabyte servers that have a PCIe network card installed in addition to the built-in LOM ports, regardless if it is being used or not.
23. Construct a JSON BOS boot session template for the UAN.

    1. Populate the template with the following information:

        - The value of the ifmap option for the `kernel_parameters` string that was determined in the previous step.
        - The xnames of Application nodes from Step 18
        - The customized image ID from Step 17 for
        - The CFS configuration session name from Step 17
    2. Verify that the session template matches the format and structure in the following example:

        ```json
        {
           "boot_sets": {
             "uan": {
               "boot_ordinal": 2,
               "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
               "network": "nmn",
               "node_list": [
                 ** [ ... List of Application Nodes from cray hsm state command ...]**
               ],
               "path": "s3://boot-images/IMS_IMAGE_ID/manifest.json",  **<-- result_id from CFS image customization session**
               "rootfs_provider": "cpss3",
               "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
               "type": "s3"
             }
           },
           "cfs": {
               "configuration": "uan-config-PRODUCT_VERSION"
           },
           "enable_cfs": true,
           "name": "uan-sessiontemplate-PRODUCT_VERSION"
         }
        ```

    3. Save the template with a descriptive name, such as uan-sessiontemplate-PRODUCT\_VERSION.json.

24. Register the session template with BOS.

    The following command uses the JSON session template file to save a session template in BOS. This step allows administrators to boot UANs by referring to the session template name.

    ```bash
    ncn-m001# cray bos sessiontemplate create \
                       --name uan-sessiontemplate-PRODUCT_VERSION \
                       --file uan-sessiontemplate-PRODUCT_VERSION.json
    /sessionTemplate/uan-sessiontemplate-PRODUCT_VERSION
    ```

Perform [Boot UANs](Boot_UANs.md) to boot the UANs with the new image and BOS session template.
