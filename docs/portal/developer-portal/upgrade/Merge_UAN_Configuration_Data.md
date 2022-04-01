# Merge UAN Configuration Data

Perform this procedure to update the UAN product configuration.

Before performing this procedure, perform [Install the UAN Product Stream](../install/Install_the_UAN_Product_Stream.md#install-the-uan-product-stream)

In this procedure, an upgrade from UAN 2.0.0 to UAN 2.3.1 is being performed. Administrators should replace the versions seen in this procedure with the versions being upgraded on the system. Additionally, this guide describes upgrading an `integration` branch. Each CFS branch responsible for configuring the various types of Application and UANs should be upgraded. 

1. Start a typescript to capture the commands and output from the procedure.

    ```bash
    ncn-m001# script -af product-uan.$\(date +%Y-%m-%d\).txt
    ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

2. Obtain the URL of the UAN configuration management repository in VCS (the Gitea service).

    This URL is reported as the value of the `configuration.clone_url` key in the `cray-product-catalog` Kubernetes ConfigMap.

3. Obtain the `crayvcs` password.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

4. Clone the UAN configuration management repository. Replace the hostname reported in the URL obtained in the previous step with `api-gw-service-nmm.local` when cloning the repository.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    . . .
    ncn-m001# cd uan-config-management && git checkout cray/uan/PRODUCT_VERSION && git pull
    Branch 'cray/uan/PRODUCT_VERSION' set up to track remote branch 'cray/uan/PRODUCT_VERSION' 
    from 'origin'.
    Already up to date.
    ```

5. Checkout the branch currently used to hold UAN configuration.

    The following example assumes that branch is `integration`.

    ```bash
    ncn-m001# git checkout integration
    Switched to branch 'integration'
    Your branch is up to date with 'origin/integration'.
    ```

6. Merge the new install branch to the current branch. Write a commit message when prompted.

    ```bash
    ncn-m001# git merge cray/uan/PRODUCT_VERSION
    ```

7. Push the changes to VCS. Enter the `crayvcs` password when prompted.

    ```bash
    ncn-m001# git push
    ```

8. Retrieve the commit ID from the merge and store it for later use.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    ```

9. Update any CFS configurations used by the UANs with the commit ID from the previous step.

    1. Download the JSON of the current UAN CFS configuration to a file.
       
       The CFS configuration `uan-config-2.0.0` is an example, the site should use the CFS configuration used for the UANs being upgraded.

       This file will be named `uan-config-2.3.1.json` since it will be modified and then used for the updated UAN version.

       ```bash
       ncn-m001# cray cfs configurations describe uan-config-2.0.0 \
       --format=json &>uan-config-2.3.1.json
       ```

    2. Remove the unneeded lines from the JSON file.

       The lines to remove are:
    
       - the `lastUpdated` line
       - the last `name` line 
    
       These must be removed before uploading the modified JSON file back into CFS to update the UAN configuration.
    
       ```bash
       ncn-m001# cat uan-config-2.3.1.json
       {
         "lastUpdated": "2021-03-27T02:32:10Z",      
         "layers": [
           {
             "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
             "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
             "name": "uan-integration-2.0.0",
             "playbook": "site.yml"
           },
         "name": "uan-config-2.0.0"            
       }
       ```

    3. Replace the `commit` value in the JSON file with the commit ID obtained with `git rev-parse --verify HEAD`.

       The `name` value after the `commit` line may also be updated to match the new UAN product version, if desired. This is not necessary as CFS does not use this value for the configuration name.
       
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

    4. Create a new UAN CFS configuration with the updated JSON file.

       The following example uses `uan-config-2.3.1` for the name of the new CFS configuration, to match the JSON file name.

       ```bash
       ncn-m001# cray cfs configurations update uan-config-2.3.1 \
       --file uan-config-2.3.1.json
       ```

10. Finish the typescript file started at the beginning of this procedure.

    ```bash
    ncn-m001# exit
    ```

11. Deploy the updated UAN product software to the User Access Nodes. 
    
    Continue with "Build a New UAN Image Using the COS Recipe" and "Create UAN Boot Images" in the publication _HPE Cray User Access Node (UAN) Software Administration Guide_ to upgrade the boot images and perform CFS image customization for the UAN images.
