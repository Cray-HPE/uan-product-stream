
## Create UAN Boot Images

This procedure updates the configuration management git repository to match the installed version of the UAN product. Then, that updated configuration is used to create UAN boot images and a BOS session template.

Perform "Install the UAN Product Stream" from the HPE Cray UAN Installation Guide first before starting this procedure.

This procedure only details how to apply UAN-specific configuration to the UAN image and nodes. Consult the documentation for the individual HPE products \(for example, workload managers and the HPE Cray Programming Environment\) that must be configured on the UANs.

This is the overall workflow for preparing UAN images for booting UANs:

1. Clone the UAN configuration git repository and create a branch based on the branch imported by the UAN installation.
2. Update the configuration content and push the changes to the newly created branch.
3. Create a Configuration Framework Service \(CFS\) configuration for the UANs, specifying the git configuration and the UAN image to apply the configuration to. More HPE products can also be added to the CFS configuration so that the UANs can install multiple HPE products into the UAN image at the same time.
4. Configure the UAN image using CFS and generate a newly configured version of the UAN image.
5. Create a Boot Orchestration Service \(BOS\) boot session template for the UANs. This template maps the configured image, the CFS configuration to be applied post-boot, and the nodes which will receive the image and configuration.

Once the UAN BOS session template is created, the UANs will be ready to be booted by a BOS session.

Replace PRODUCT\_VERSION and CRAY\_EX\_HOSTNAME in the example commands in this procedure with the current UAN product version installed \(See Step 1\) and the hostname of the HPE Cray EX system, respectively.

**UAN IMAGE PRE-BOOT CONFIGURATION**

1. Obtain the artifact IDs and other information from the `cray-product-catalog` Kubernetes ConfigMap. Record the following information:
   - the `clone_url`
   - the `commit`
   - the `import_branch` value
   - both the name and `id` values under `images`
   - both the name and `id` values under `recipes`

    Upon successful installation of the UAN product, the UAN configuration, image recipes, and prebuilt boot images are cataloged in this ConfigMap. This information is required for this procedure.

    ```bash
    ncn-m001# kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
    PRODUCT_VERSION:
      configuration:
        clone_url: https://vcs.CRAY_EX_HOSTNAME/vcs/cray/uan-config-management.git 
        commit: 6658ea9e75f5f0f73f78941202664e9631a63726                   
        import_branch: cray/uan/PRODUCT_VERSION                           
        import_date: 2021-02-02 19:14:18.399670
        ssh_url: git@vcs.CRAY_EX_HOSTNAME:cray/uan-config-management.git
      images:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       
          id: c880251d-b275-463f-8279-e6033f61578b                         
      recipes:
        cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:                       
          id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a                         
    ``` 

2. Generate the password hash for the `root` user. Replace PASSWORD with the `root` password you wish to use.

    ```bash
    ncn-m001# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
    ```

3. Obtain the HashiCorp Vault `root` token.

    ```bash
    ncn-m001# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' \
     | base64 -d; echo
    ```

4. Write the password hash obtained in Step 2 to the HashiCorp Vault.

    The vault login command will request a token. That token value is the output of the previous step. The vault `read secret/uan` command verifies that the hash was stored correctly. This password hash will be written to the UAN for the `root` user by CFS.

    ```bash
    ncn-m001# kubectl exec -itn vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan root_password='HASH'
    vault read secret/uan
    ```

5. Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next command.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

6. Clone the UAN configuration management repository. Replace CRAY\_EX\_HOSTNAME in the clone url with **api-gw-service-nmn.local** when cloning the repository.

    The repository is in the VCS/Gitea service and the location is reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.clone_url` key. The CRAY\_EX\_HOSTNAME from the `clone_url` is replaced with `api-gw-service-nmn.local` in the command that clones the repository.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' from 'origin'.
    Already up to date.
    ```

7. Create a branch using the imported branch from the installation to customize the UAN image.

    This will be reported in the `cray-product-catalog` Kubernetes ConfigMap in the `configuration.import_branch` key under the UAN section. The format is cray/uan/PRODUCT\_VERSION. In this guide, an `integration` branch is used for examples, but the name can be any valid git branch name.

    Modifying the cray/uan/PRODUCT\_VERSION branch that was created by the UAN product installation is not allowed by default.

    ```bash
    ncn-m001# git checkout -b integration && git merge cray/uan/PRODUCT_VERSION
    Switched to a new branch 'integration'
    Already up to date.
    ```

8. Apply any site-specific customizations and modifications to the Ansible configuration for the UAN nodes and commit the changes.

    The default Ansible play to configure UAN nodes is `site.yml` in the base of the `uan-config-management` repository. The roles that are executed in this play allow for custom  configuration as required for the system.

    Consult the individual Ansible role `README.md` files in the uan-config-management repository roles directory to configure individual role variables. Roles prefixed with `uan_` are specific to UAN configuration and include network interfaces, disk, LDAP, software packages, and message of the day roles.

    Variables should be defined and overridden in the Ansible inventory locations of the repository as shown in the following example and **not** in the Ansible plays and roles defaults. See [this page from the Ansible documentation](https://docs.ansible.com/ansible/2.9/user\_guide/playbooks\_best\_practices.html\#content-organization) for directory layouts for inventory.

    **Warning:** Never place sensitive information such as passwords in the git repository.

    The following example shows how to add a `vars.yml` file containing site-specific configuration values to the `Application_UAN` group variable location.

    These and other Ansible files do not necessarily need to be modified for UAN image creation. See [About UAN Configuration](operations/About_UAN_Configuration.md#about-uan-configuration) for instructions for site-specific UAN configuration, including CAN configuration.

    ```bash
    ncn-m001# vim group_vars/Application_UAN/vars.yml
    ncn-m001# git add group_vars/Application_UAN/vars.yml
    ncn-m001# git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
     1 file changed, 1 insertion(+)
     create mode 100644 group_vars/Application_UAN/vars.yml
    ```

9.  Verify that a default route will be configured.

    By default, no default route is set. The expectation is that customers either enable the CAN, or configure `uan_interfaces` correctly for their network.

    If `uan_interfaces` is not configured for a customer's network to enable a default route, the CAN may enabled with the following setting:
    ```bash
    ncn-m001# # cat group_vars/Application_UAN/vars.yaml
    ---
    uan_can_setup: yes
    ```

    **Warning:** If the CAN is not enabled, or the customer has not configured `uan_interfaces`, the UAN will fail CFS Node Personalization for tasks like LDAP, PE, and WLM.

10. Verify that the System Layout Service \(SLS\) and the `uan_interfaces` configuration role refer to the Mountain Node Management Network by the same name. Skip this step if there are no Mountain cabinets in the HPE Cray EX system.

    a. Edit the roles/uan\_interfaces/tasks/main.yml file and change the line that reads  
    `url: http://cray-sls/v1/search/networks?name=MNMN` to read  
    `url: http://cray-sls/v1/search/networks?name=NMN_MTN`.

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

    b. Stage and commit the network name change

        ```bash
        ncn-m# git add roles/uan_interfaces/tasks/main.yml
        ncn-m# git commit -m "Add Mountain cabinet support"
        ```

11. Push the changes to the repository using the proper credentials, including the password obtained previously.

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

12. Capture the most recent commit for reference in setting up a CFS configuration and navigate to the parent directory.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    
    ecece54b1eb65d484444c4a5ca0b244b329f4667
    
    ncn-m001# cd ..
    ```

    The configuration parameters have been stored in a branch in the UAN git repository. The next phase of the process initiates the Configuration Framework Service \(CFS\) to customize the image.


    **CONFIGURE UAN IMAGES**

13. Create a JSON input file for generating a CFS configuration for the UAN.

    Gather the git repository clone URL, commit, and top-level play for each configuration layer \(that is, Cray product\). Add them to the CFS configuration for the UAN, if wanted.

    For the commit value for the UAN layer, use the Git commit value obtained in the previous step.

    See the product-specific documentation for further information on configuring other HPE products, as this procedure documents only the configuration of the UAN. More layers can be added to be configured in a single CFS session.

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

14. Add the configuration to CFS using the JSON input file.

    In the following example, the JSON file created in the previous step is named `uan-config-PRODUCT_VERSION.json` only the details for the UAN layer are shown.

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

   The UAN layer must be first as it configures the network interfaces that may be required by subsequent layers. When other products are added to the CFS configuration used to boot UANs, the suggested order of the layers would be:

      1. UAN
      2. CPE (Cray Programming Environment)
      3. Workload Manager (Either Slurm or PBS Pro)
      4. Analytics
      5. customer

15. Create a CFS session to perform preboot image customization of the UAN image.

    ```bash
    ncn-m001# cray cfs sessions create --name uan-config-PRODUCT_VERSION \
                      --configuration-name uan-config-PRODUCT_VERSION \
                      --target-definition image \
                      --target-group Application_UAN IMAGE_ID\
                      --format json
    ```

16. Wait until the CFS configuration session for the image customization to complete. Then record the ID of the IMS image created by CFS.

    The following command will produce output while the process is running. If the CFS session completes successfully, an IMS image ID will appear in the output.

    ```bash
    ncn-m001# cray cfs sessions describe uan-config-PRODUCT_VERSION --format json | jq
    ```

**PREPARE UAN BOOT SESSION TEMPLATES**

17. Retrieve the xnames of the UAN nodes from the Hardware State Manager \(HSM\).

    These xnames are needed for Step 18.

    ```bash
    ncn-m001# cray hsm state components list --role Application --subrole UAN --format json | \
    jq -r .Components[].ID
    x3000c0s19b0n0
    x3000c0s24b0n0
    x3000c0s20b0n0
    x3000c0s22b0n0
    ```

18. Construct a JSON BOS boot session template for the UAN.

    a. Populate the template with the following information:

        - The xnames of Application nodes from Step 17
        - The customized image ID from Step 16 for
        - The CFS configuration session name from Step 15

    b. Verify that the session template matches the format and structure in the following example:

        ```json
        {
           "boot_sets": {
             "uan": {
               "boot_ordinal": 2,
               "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=512M 
               hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp
                numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14
                 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell
                  turbo_boost_limit=999 spire_join_token=${SPIRE_JOIN_TOKEN}", 
               "network": "nmn",
               "node_list": [
                 ** [ ... List of Application Nodes from cray hsm state command ...]**
               ],
               "path": "s3://boot-images/IMS_IMAGE_ID/manifest.json",  **<-- result_id from Step 16**
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

    c. Save the template with a descriptive name, such as `uan-sessiontemplate-PRODUCT_VERSION.json`.

19. Register the session template with BOS.

    The following command uses the JSON session template file to save a session template in BOS. This step allows administrators to boot UANs by referring to the session template name.

    ```bash
    ncn-m001# cray bos sessiontemplate create \
                       --name uan-sessiontemplate-PRODUCT_VERSION \
                       --file uan-sessiontemplate-PRODUCT_VERSION.json
    /sessionTemplate/uan-sessiontemplate-PRODUCT_VERSION
    ```

20. Perform [Boot UANs](Boot_UANs.md#boot-uans) to boot the UANs with the new image and BOS session template.
