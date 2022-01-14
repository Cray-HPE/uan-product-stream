## Merge UAN Configuration Data

Perform this procedure to update the UAN product configuration.

Before performing this procedure:

- Perform [Install the UAN Product Stream](install/Install_the_UAN_Product_Stream.md#install-the-uan-product-stream)


Version 2.0.0 or later of the UAN product must be installed before performing this procedure.

In this procedure:

- PRODUCT\_VERSION: refers to the full name of the UAN product version that is currently installed.

1. Start a typescript to capture the commands and output from the procedure.

    ```bash
    ncn-m001# script -af product-uan.$\(date +%Y-%m-%d\).txt
    ncn-m001#  export PS1='\\u@\\H \\D\{%Y-%m-%d\} \\t \\w \# '
    ```

2. Obtain the URL of UAN configuration management repository in VCS \(the Gitea service\).

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

       This file will be named uan-config-2.3.0.json since it will be modified and then used for the updated UAN version.
       ```bash
           ncn-m001#  cray cfs configurations describe uan-config-2.0.0 \
            --format=json &>uan-config-2.3.0.json
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
