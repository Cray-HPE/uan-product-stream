## Merge UAN Configuration Data

Perform this procedure to update the UAN product configuration.

Version 2.0.0 or later of the UAN product must be installed before performing this procedure.

In this procedure:

- UAN\_RELEASE: refers to the new UAN release version \(for example, 2.0.1\)

- UAN\_DISTDIR: refers to the directory containing the extracted UAN release distribution for the new UAN release.

- PRODUCT\_VERSION: refers to the full name of the UAN product version that is currently installed.

1. Start a typescript to capture the commands and output from the installation.

    ```bash
    ncn-m001# script -af product-uan.$\(date +%Y-%m-%d\).txt
    ncn-m001#  export PS1='\\u@\\H \\D\{%Y-%m-%d\} \\t \\w \# '
    ```

2. Download the new UAN distribution tarball to the ncn-m001 node.

3. Select an existing directory, or create a new directory, to contain the extracted release distribution for the new UAN release.

    The remaining steps in this procedure will refer to this directory as UAN\_DISTDIR.

4. Extract the contents of the tarball of the new UAN release to `UAN_DISTDIR`. Use the `--no-same-owner` and `--no-same-permissions` options of the `tar` command when extracting a UAN release distribution as the `root` user.

    These options ensure that the extracted files:

    - Are owned by the `root` user.

    - Have permissions based on the current `umask` value.

5. List the current UAN versions in the product catalog.

    This step verifies that version 2.0.0 of the UAN product is installed on the system.

    ```bash
    ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.uan}' \
    | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
    ```

6. Deploy the manifests of new UAN version.

    The following command will install a new product branch in VCS. In the next steps, the updated content in this new release branch will be merged into the VCS branch currently being used to configure UANs.

    ```bash
    ncn-m001# UAN_DISTDIR/install.sh
    ```

7. **Optional:** Generate a `root` password hash and store it in the HashiCorp Vault. Skip this step if a `root` password hash is already stored in the vault and that password will not be changed.

    a. Generate the password hash for the `root` user. Replace `PASSWORD` with the desired `root` password.

    ```bash
    ncn-m001# openssl passwd -6 -salt $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c4) \
    PASSWORD
    ```

    b. Obtain the HashiCorp Vault root token.

    ```bash
    ncn-m001# kubectl get secrets -n vault cray-vault-unseal-keys -o jsonpath='{.data.vault-root}' | \
    base64 -d; echo
    ```

    c. Write the password hash (from substep *a*) to the HashiCorp Vault. Enter the token value from the previous substep when prompted by `vault login`.
    
    The `vault read secret/uan` is to verify the hash was stored correctly. This password hash will be written to the UAN for the `root` user by CFS.

    It is important to enclose the hash in single quotes to preserve any special characters.

    ```bash
    ncn-m001# kubectl exec -itn vault cray-vault-0 -- sh
    export VAULT_ADDR=http://cray-vault:8200
    vault login
    vault write secret/uan root_password='<HASH>'
    vault read secret/uan
    ```

8. Obtain the URL of UAN configuration management repository in VCS \(the Gitea service\).

    This URL is reported as the value of the `configuration.clone_url` key in the `cray-product-catalog` Kubernetes ConfigMap.

9. Obtain the `crayvcs` password.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

10. Clone the UAN configuration management repository. Replace the hostname reported in the URL obtained in the previous step with `api-gw-service-nmm.local` when cloning the repository.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' 
    from 'origin'.
    Already up to date.
    ```

11. Checkout the branch currently used to hold UAN configuration.

    The following example assumes that branch is `integration`.

    ```bash
    ncn-m001# git checkout integration
    Switched to branch 'integration'
    Your branch is up to date with 'origin/integration'.
    ```

12. Merge the new install branch to the current branch. Write a commit message when prompted.

    ```bash
    ncn-m001# git merge cray/uan/PRODUCT_VERSION
    ```

13. Push the changes to VCS. Enter the `crayvcs` password when prompted.

    ```bash
    ncn-m001# git push
    ```

14. Retrieve the commit ID from the merge and store it for later use.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    ```

15. Update any CFS configurations used by the UANs with the commit ID from the previous step.

    a. Download the JSON of the current UAN CFS configuration to a file.

       This file will be named uan-config-2.0.1.json since it will be modified and then used for the updated UAN version.
       ```bash
           ncn-m001#  cray cfs configurations describe uan-config-2.0.0 \
            --format=json &>uan-config-2.0.1.json
       ```

    b. Remove the unneeded lines from the JSON file.

        The lines to remove are:

           - the `lastUpdated` line
           - the last `name` line 
        
        These must be removed before uploading the modified JSON file back into CFS to update the UAN configuration.

        ```bash
        ncn-m001# cat uan-config-2.0.1.json
        {
          "lastUpdated": "2021-03-27T02:32:10Z",      
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
              "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
              "name": "uan-integration-2.0.0",
              "playbook": "site.yml"
            },
          "name": "uan-config-2.0.1-full"            
        } 
        ```

    c. Replace the `commit` value in the JSON file with the commit ID obtained in Step 14.

        The name value after the commit line may also be updated to match the new UAN product version, if desired. This is not necessary as CFS does not use this value for the configuration name.

        ```bash
        {
         "layers": [
         {
         "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-configmanagement.git",
         "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
         "name": "uan-integration-2.0.0",
         "playbook": "site.yml"
         }
         ]
        }
        ```

    d. Create a new UAN CFS configuration with the updated JSON file.

       The following example uses `uan-config-2.0.1` for the name of the new CFS configuration, to match the JSON file name.

        ```bash
        ncn-m001# cray cfs configurations update uan-config-2.0.1 \
         --file uan-config-2.0.1.json
        ```

    e. Tell CFS to apply the new configuration to UANs by repeating the following command for each UAN. Replace UAN\_XNAME in the command below with the name of a different UAN each time the command is run.

        ```bash
        ncn-m001# cray cfs components update --desired-config uan-config-2.0.1 \
        --enabled true --format json UAN_XNAME
        ```

16. Finish the typescript file started at the beginning of this procedure.

    ```bash
    ncn-m001# exit
    ```

17. Perform "Create UAN Boot Images" in the HPE Cray UAN Administration Guide to upgrade the boot images used by the UANs.
