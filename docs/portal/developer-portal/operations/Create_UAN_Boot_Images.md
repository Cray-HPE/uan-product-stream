
# Create UAN Boot Images

This procedure updates the configuration management git repository to match the installed version of the UAN product. That updated configuration is then used to create UAN boot images and a BOS session template.

UAN specific configuration, and other required configurations related to UANs are covered in this topic. Refer to *HPE Cray EX System Software Getting Started Guide* for further information on configuring other HPE products (for example, workload managers and the HPE Cray Programming Environment\) that may be configured on the UANs.

This is the overall workflow for preparing UAN images to boot UANs:

1. Clone the UAN configuration git repository and create a branch based on the branch imported by the UAN installation.
2. Update the configuration content and push the changes to the newly created branch.
3. Use Shasta Admin Toolkit (SAT) command `sat bootprep`, to automate the creation of IMS image, CFS configurations, and BOS session templates.

Once the UAN BOS session template is created, the UANs will be ready to be booted by a BOS session.

Replace `PRODUCT_VERSION` and `CRAY_EX_HOSTNAME` in the example commands in this procedure with the current UAN product version installed \(See Step 1\) and the hostname of the HPE Cray EX system, respectively.

**PREPARE CFS CONFIGURATION**

1. Obtain the artifact IDs and other information from the `cray-product-catalog` Kubernetes ConfigMap. Record the following information:
   - the `clone_url`
   - the `import_branch` value
   
   Upon successful installation of the UAN product, the UAN configuration is cataloged in this ConfigMap. This information is required for this procedure.
   
    `PRODUCT_VERSION` will be replaced by a numbered version string, such as `2.1.7` or `2.3.0`.
   
    ```bash
    ncn-m001# kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
    PRODUCT_VERSION:
      configuration:
        clone_url: https://vcs.CRAY_EX_HOSTNAME/vcs/cray/uan-config-management.git 
        commit: 6658ea9e75f5f0f73f78941202664e9631a63726                   
        import_branch: cray/uan/PRODUCT_VERSION                           
        import_date: 2021-02-02 19:14:18.399670
        ssh_url: git@vcs.CRAY_EX_HOSTNAME:cray/uan-config-management.git                      
    ```
   
2. **Optional** Generate the password hash for the `root` user. Replace PASSWORD with the `root` password you wish to use.  If an upgrade or image rebuild is being performed, the root password may have already been added to vault.

    ```bash
    ncn-m001# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) PASSWORD
    ```

3. **Optional** Obtain the HashiCorp Vault `root` token.

    ```bash
    ncn-m001# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | base64 -d; echo
    ```
    
4. **Optional** Write the password hash obtained in Step 2 to the HashiCorp Vault.

    The vault login command will request a token. That token value is the output of the previous step. The vault `read secret/uan` command verifies that the hash was stored correctly. This password hash will be written to the UAN for the `root` user by CFS.

    ```bash
    ncn-m001# kubectl exec -it -n vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan root_password='HASH'
    vault read secret/uan
    ```

5. **Optional** Write any uan_ldap sensitive data, such as the `ldap_default_authtok` value, to the HashiCorp Vault.

    The vault login command will request a token. That token value is the output of the Step 3. The vault `read secret/uan_ldap` command verifies that the `uan_ldap` data was stored correctly. Any values stored here will be written to the UAN `/etc/sssd/sssd.conf` file in the `[domain]` section by CFS.
    
    This example shows storing a value for `ldap_default_authtok`.  If more than one variable needs to be stored, they must be written in space separated `key=value` pairs on the same `vault write secret/uan_ldap` command line.

    ```bash
    ncn-m001# kubectl exec -it -n vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan_ldap ldap_default_authtok='TOKEN'
    vault read secret/uan_ldap
    ```

6. Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next command.

    ```bash
    ncn-m001# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
              VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    ```
    
7. Clone the UAN configuration management repository. Replace CRAY\_EX\_HOSTNAME in the clone url with **api-gw-service-nmn.local** when cloning the repository.

    The repository is in the VCS/Gitea service and the location is reported in the cray-product-catalog Kubernetes ConfigMap in the `configuration.clone_url` key. The CRAY\_EX\_HOSTNAME from the `clone_url` is replaced with `api-gw-service-nmn.local` in the command that clones the repository.

    ```bash
    ncn-m001# git clone https://$VCS_USER:$VCS_PASS@api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' from 'origin'.
    Already up to date.
    ```

8. Create a branch using the imported branch from the installation to customize the UAN image.

    This will be reported in the `cray-product-catalog` Kubernetes ConfigMap in the `configuration.import_branch` key under the UAN section. The format is cray/uan/PRODUCT\_VERSION. In this guide, an `integration` branch is used for examples, but the name can be any valid git branch name.

    Modifying the cray/uan/PRODUCT\_VERSION branch that was created by the UAN product installation is not allowed by default.

    ```bash
    ncn-m001# git checkout -b integration && git merge cray/uan/PRODUCT_VERSION
    Switched to a new branch 'integration'
    Already up to date.
    ```

9. Apply any site-specific customizations and modifications to the Ansible configuration for the UAN nodes and commit the changes.

    The default Ansible play to configure UAN nodes is `site.yml` in the base of the `uan-config-management` repository. The roles that are executed in this play allow for custom configuration as required for the system.

    Consult the individual Ansible role `README.md` files in the uan-config-management repository roles directory to configure individual role variables. Roles prefixed with `uan_` are specific to UAN configuration and include network interfaces, disk, LDAP, software packages, and message of the day roles.

    ***NOTE:*** Admins ***must*** ensure the `uan_can_setup` variable is set to the correct value for the site.  This variable controls how the nodes are configured for user access. When `uan_can_setup` is `yes`, user access is over the `CAN` or `CHN`, based on the BICAN System Default Route setting in SLS.  When `uan_can_setup` is `no`, the Admin must configure the user access interface and default route. See [Configure Interfaces on UANs](Configure_Interfaces_on_UANs.md)

    **Warning:** Never place sensitive information such as passwords in the git repository.

    The following example shows how to add a `vars.yml` file containing site-specific configuration values to the `Application_UAN` group variable location.

    These and other Ansible files do not necessarily need to be modified for UAN image creation. See [About UAN Configuration](About_UAN_Configuration.md#about-uan-configuration) for instructions for site-specific UAN configuration, including CAN/CHN configuration.

    ```bash
    ncn-m001# vim group_vars/Application_UAN/vars.yml
    ncn-m001# git add group_vars/Application_UAN/vars.yml
    ncn-m001# git commit -m "Add vars.yml customizations"
    [integration ecece54] Add vars.yml customizations
     1 file changed, 1 insertion(+)
     create mode 100644 group_vars/Application_UAN/vars.yml
    ```

10. Push the changes to the repository using the proper credentials, including the password obtained previously.

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

    The configuration parameters have been stored in a branch in the UAN git repository. The next phase of the process uses `sat bootprep` to handle creating the CFS configurations, IMS images, and BOS sessiontemplates for UANs.

**CREATE UAN IMAGES**

With Shasta Admin Toolkit (SAT) version `2.2.16` and later, it is recommended that administrators create an input file for use with `sat bootprep`. Use the following command to determine which version of SAT is installed:

```bash
ncn-m001# sat showrev --products --filter 'product_name="sat"'
```

A `sat bootprep` input file will have three sections: `configurations`, `images`, and `session_templates`. These sections create CFS configurations, IMS images, and BOS session templates respectively. Each section may have multiple elements to create more than one CFS, IMS, or BOS artifact. The format is similar to the input files for CFS, IMS, and BOS, but SAT will automate the process with fewer steps. Follow the subsections below to create a UAN bootprep input file.

Refer to *HPE Cray EX System Software Getting Started Guide* for further information on configuring other HPE products, as this procedure documents only the required configuration of the UAN.

**SAT Bootprep Configuration**

The SAT bootprep input file should have a configuration section that specifies each layer to be included in the CFS configuration for the UAN images for image customization and node personalization. This section will result in a CFS configuration named `uan-config`. The versions of each layer may be gathered using `sat showrev`. 

Note that the Slingshot Host Software CFS layer is listed first. This is required as the UAN layer will attempt to install DVS and Lustre packages that require SHS be installed first. The correct playbook for Cassini or Mellanox must also be specified. Consult the Slingshot Host Software documentation for more information.

```yaml
configurations:
- name: uan-config
  layers:
  - name: slingshot-host-software
    playbook: shs_mellanox_install.yml
    product:
      name: slingshot-host-software
      version: 2.0.0
      branch: integration

  ... add configuration layers for other products here, if desired ...

  - name: uan
    playbook: site.yml
    product:
      name: uan
      version: 2.4.0
      branch: integration
```

**SAT Bootprep Image**

The SAT bootprep input file should have a section that specifies which IMS images to create for UAN nodes. UANs are built using the COS recipe, so the section below specifies which image recipe to use based on what is provided by COS. To determine which COS recipes are available run the following command:

```bash
ncn-m001# sat showrev --products --filter 'product_name="cos"'
```

This example will create an IMS image with the name `cray-shasta-uan-sles15sp3.x86_64-2.3.25`. An appropriate name should be used to correctly identify the UAN image being built. Also note that the CFS configuration `uan-config` is being referenced so that CFS image customization will be run using that configuration along with the specified node groups.

```yaml
images:
- name: cray-shasta-uan-sles15sp3.x86_64-2.3.25
  ims:
    is_recipe: true
    name: cray-shasta-compute-sles15sp3.x86_64-2.3.25
  configuration: uan-config
  configuration_group_names:
  - Application
  - Application_UAN
```

**SAT Bootprep Session Template**

The final section of the SAT bootprep input file creates BOS session templates. This section references the named IMS image that `sat bootprep` generates, as well as a CFS configuration. The boot_sets key "uan" may be changed as needed. If there are more than one boot_sets in the session template, each key will need to be unique.

```yaml
session_templates:
- name: uan-2.4.0
  image: cray-shasta-uan-sles15sp3.x86_64-2.3.25
  configuration: uan-config
  bos_parameters:
    boot_sets:
      uan:
        kernel_parameters: spire_join_token=${SPIRE_JOIN_TOKEN}
        node_roles_groups:
        - Application_UAN
```

**Run SAT Bootprep**

Initiate the `sat bootprep` command to generate the configurations and artifacts needed to boot UANs. This command may take some time as it will initiate IMS image creation and CFS image customization.

```bash
ncn-m001# sat bootprep run uan-bootprep.yaml
```

If changes are necessary to complete `sat bootprep` with the provided input file, make adjustments to the CFS layers or input file as needed and rerun the `sat bootprep` command. If any artifacts are going to be overwritten, SAT will prompt for confirmation before taking action. This is useful when making CFS changes as SAT will automatically configure the layers to use the latest git commits if the branches are specified correctly.

Once `sat bootprep` completes successfully, save the input file to a known location. This input file will be useful to regenerate artifacts as changes are made or different product layers are added.

Finally, perform [Boot UANs](Boot_UANs.md#boot-uans) to boot the UANs with the new BOS session template.
