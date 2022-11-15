# KDUMP Configuration Workaround

There exists a known bug in the `site.yml` file of the `uan-config-management` VCS repository where the `kdump` Ansible role is being called too early in the configuration process.  The `kdump` role creates the kdump initrd and it is being called prior to all the UAN packages being installed. This creates a kdump initrd which does not include the required network drivers for the UAN hardware and causes kdump to fail on UAN nodes. The following procedure details the workaround for this issue. The workaround consists of the following steps.

1. Change the location of the `kdump` role in the `site.yml` file to be just prior to the `rebuild_initrd` role

1. Commit and push this change to VCS

1. Update the UAN CFS configuration(s)

1. Reconfigure the UAN image(s) with the updated CFS configuration

1. Update the UAN BOS session template(s) with the new image and CFS configuration

1. Reboot the UAN nodes

The following procedure describes how to perform the workaround.

## Procedure

1. Login to the master node (m001).

1. Obtain the password for the `crayvcs` user.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

1. Create a copy of the Git configuration. Enter the credentials for the `crayvcs` user when prompted.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    ```

1. Change to the `uan-config-management` directory.

    ```bash
    ncn-m001# cd uan-config-management
    ```
1. Checkout the `integration` branch or whatever branch is currently used to configure the UANs.

    ```bash
    ncn-m001# git checkout integration
    ```

1. Edit the `site.yml` file and move these lines as shown below:

    **FROM:**
    ```yaml
        # Standard UNIX configuration
        - rsyslog
        - localtime
        - ntp
        - limits
        - role: kdump             <--- Remove this line
          kdump_target_uan: yes   <--- Remove this line
    ```

    **TO:**
    ```yaml
        # Rebuild initrd for image customization
        - role: kdump             <--- Add this line
          kdump_target_uan: yes   <--- Add this line
        - { role: rebuild-initrd,     when: cray_cfs_image|default(false)|bool }
    ```

1. Add the change from the working directory to the staging area.

    ```bash
    ncn-m001# git add site.yml
    ```

1. Commit the file to the branch.

    ```bash
    ncn-m001# git commit -m 'Enable kdump'
    ```

1. Push the commit.

    ```bash
    ncn-m001# git push
    ```

1. Obtain the commit ID for the commit pushed in the previous step.

    ```bash
    ncn-m001# git rev-parse --verify HEAD
    ```

1. Update any CFS configurations used by the UANs with the commit ID from the previous step.

    1. Download the JSON of the current UAN CFS configuration to a file.

       This file will be named `uan-config-PRODUCT_VERSION.json`. Replace `PRODUCT_VERSION` with the current installed UAN version.

       ```bash
           ncn-m001#  cray cfs configurations describe uan-config-PRODUCT_VERSION \
            --format=json >uan-config-PRODUCT_VERSION.json
       ```

    1. Remove the unneeded lines from the JSON file.

        The lines to remove are:

        - the `lastUpdated` line
        -  the last `name` line

        These must be removed before uploading the modified JSON file back into CFS to update the UAN configuration.

        ```bash
        ncn-m001# cat uan-config-PRODUCT_VERSION.json
        {
          "lastUpdated": "2021-03-27T02:32:10Z",      
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
              "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
              "name": "uan-integration-PRODUCT_VERSION",
              "playbook": "site.yml"
            },
          "name": "uan-config-2.0.1-full"            
        } 
        ```

    1. Replace the `commit` value in the JSON file with the commit ID obtained in the previous Step.

        The name value after the commit line may also be updated to match the new UAN product version, if desired. This is not necessary as CFS does not use this value for the configuration name.

        ```bash
        {
         "layers": [
           {
             "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-configmanagement.git",
             "commit": "aa5ce7d5975950ec02493d59efb89f6fc69d67f1",
             "name": "uan-integration-PRODUCT_VERSION",
             "playbook": "site.yml"
           }
         ]
        }
        ```

    1. Create a new UAN CFS configuration with the updated JSON file.

       The following example uses `uan-config-PRODUCT_VERSION` for the name of the new CFS configuration, to match the JSON file name.

        ```bash
        ncn-m001# cray cfs configurations update uan-config-PRODUCT_VERSION \
         --file uan-config-PRODUCT_VERSION.json
        ```

1. Download the JSON of the current UAN BOS session template to a file.

   This session template name in this example is `uan-bos-PRODUCT_VERSION` and the file will be named `uan-bos-PRODUCT_VERSION.json`. Replace `PRODUCT_VERSION` with the current installed UAN version.

   ```bash
      ncn-m001#  cray bos sessiontemplates describe uan-config-PRODUCT_VERSION \
       --format=json >uan-bos-PRODUCT_VERSION.json
   ```

1. Reconfigure the UAN image used in the BOS session template.

    1. The image ID of the UAN image can be found in the BOS session template.  It is the value between `boot-images/` and `/manifest.json` in the "path" line. `42b82508-8fa0-46e0-a659-1ad566ee98a1` in the example below. Save this value in the IMAGE_ID environment variable.

    ```bash
    {
      "boot_sets": {
        "compute": {
          "etag": "1560f33e61ef52b5b23dceda18b972a4",
          "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}",
          "node_roles_groups": [
            "Application",
            "Application_UAN"
          ],
          "path": "s3://boot-images/42b82508-8fa0-46e0-a659-1ad566ee98a1/manifest.json",
          "rootfs_provider": "cpss3",
          "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:hsn0,hsn1,nmn0:0",
          "type": "s3"
        }
      },
      "cfs": {
        "configuration": "uan-config-PRODUCT_VERSION"
      },
      "enable_cfs": true
    }
    ```

    ```bash
    ncn-m001# export IMAGE_ID=42b82508-8fa0-46e0-a659-1ad566ee98a1
    ```

    1. Run CFS to reconfigure the UAN image.

    ```bash
    ncn-m001# cray cfs sessions create --name uan-kdump \
    --configuration-name uan-config-PRODUCT_VERSION --target-definition image \
    --target-group Application $IMAGE_ID \
    --target-group Application_UAN $IMAGE_ID
    ```

    1. Monitor the CFS session.  It is named `uan-kdump` in the command line above. Repeat this command until the [status.session] status is "complete" and succeeded is "true".

    ```bash
    ncn-m001# cray cfs sessions describe uan-kdump
    ```

    ```bash
    ncn-m001# cray cfs sessions describe uan-kdump
    name = "uan-kdump"

    [ansible]
    config = "cfs-default-ansible-cfg"
    verbosity = 0

    [configuration]
    limit = ""
    name = "uan-config-PRODUCT_VERSION"

    [status]
    [[status.artifacts]]
    image_id = "42b82508-8fa0-46e0-a659-1ad566ee98a1"
    result_id = "bf27f180-bd54-42ee-acd5-796bf8c4d9cd"
    type = "ims_customized_image"

    [tags]

    [target]
    definition = "image"
    [[target.groups]]
    members = [ "42b82508-8fa0-46e0-a659-1ad566ee98a1",]
    name = "Application"

    [[target.groups]]
    members = [ "42b82508-8fa0-46e0-a659-1ad566ee98a1",]
    name = "Application_UAN"

    [status.session]
    completionTime = "2022-11-07T18:29:43"
    job = "cfs-107886ab-92d2-4cb8-bb28-190373342ceb"
    startTime = "2022-11-07T18:22:52"
    status = "complete"
    succeeded = "true"
    ```

    1. When the CFS session completes, there will be a value in the `resultant_id` field. This is the newly configured UAN image.  Save this ID as NEW_IMAGE_ID.

    ```bash
    ncn-m001# export NEW_IMAGE_ID=bf27f180-bd54-42ee-acd5-796bf8c4d9cd
    ```

1. Update the BOS session template with the newly configure image information.

    1. Get the image etag value from IMS.

    ```bash
    ncn-m001# cray ims images describe $NEW_IMAGE_ID
    created = "2022-11-03T16:43:19.985083+00:00"
    id = "bf27f180-bd54-42ee-acd5-796bf8c4d9cd"
    name = "image-uan"
    
    [link]
    etag = "56b5f71a3f4b97261adc80868ba724cc"
    path = "s3://boot-images/bf27f180-bd54-42ee-acd5-796bf8c4d9cd/manifest.json"
    type = "s3"
    ```

    1. Update the BOS session template JSON file with the new etag and image id values.

    1. Update the BOS session template with the JSON file.

    ```bash
    ncn-m001# cray bos sessiontemplates create --file uan-bos-PRODUCT_VERSION.json uan-bos-PRODUCT_VERSION.json
    ```
    
1. Reboot the UAN with the Boot Orchestration Service \(BOS\).

    KDUMP will be available when the UAN is rebooted to the newly configured image.

    ```bash
    ncn-m001# cray bos v1 session create \
     --template-uuid uan-bos-PRODUCT_VERSION --operation reboot
    ```
