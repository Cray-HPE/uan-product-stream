
## Build a New UAN Image Using the Default Recipe

Build or rebuild the UAN image using either the default UAN image or the default UAN image recipe.

- Both the COS and UAN product streams must be installed.
- The cray administrative CLI must be initialized.

- **OBJECTIVE**

    Build or rebuild the UAN image using either the default UAN image or image recipe. Both of these are supplied by the UAN product stream installer

The Cray EX User Access Node \(UAN\) recipe currently requires the Slingshot packages, which are not installed with the UAN product itself. Therefore, the UAN recipe can only be built after either the Slingshot product is installed, or after the Slingshot packages are removed from the recipe.

UAN images built without the Slingshot packages are not able to mount Lustre filesystems. Therefore, the UANs that run those images are limited in usefulness.

1. Determine if the Slingshot product stream is installed on the HPE Cray EX system.

    The Slingshot Diagnostics RPM and the following packages must be removed from the default recipe if the Slingshot product is not installed:
    - slingshot-firmware-management
    - slingshot-firmware-mellanox
    - slingshot-utils

2. Modify the default UAN recipe to remove the Slingshot packages. Skip this step if the Slingshot packages are not installed.

    1. Perform [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md) to download and extract the UAN image recipe, cray-sles15sp1-uan-cos, but stop before the step that modifies the recipe.

    2. Open the file config-template.xml.j2 within the recipe for editing and remove these lines:

        ```xml
         <!-- SECTION: Slingshot Diagnostic package -->
             <package name="cray-diags-fabric"/>
             <package name="slingshot-firmware-management"/>
             <package name="slingshot-firmware-mellanox"/>
             <package name="slingshot-utils"/>
        ```

    3. Resume the procedure [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md), starting with the step that locates the directory that contains the Kiwi-NG image description files.

        The next substep requires the id of the new image recipe record.

    4. Perform the procedure [Build an Image Using IMS REST Service](Build_an_Image_Using_IMS_REST_Service.md) to build the UAN image from the modified recipe. Use the id of the new image recipe.

        Skip the remaining steps of this current procedure.

3. **Optional:** Build the UAN image using IMS. Skip this step to build the UAN image manually.

    1. Identify the UAN image recipe.

        ```bash
        ncn-m001# cray ims recipes list --format json | jq '.[] | select(.name | contains("uan"))'
        {
          "created": "2021-02-17T15:19:48.549383+00:00",
          "id": "4a5d1178-80ad-4151-af1b-bbe1480958d1",  <<-- Note this ID
          "link": {
            "etag": "3c3b292364f7739da966c9cdae096964",
            "path": "s3://ims/recipes/4a5d1178-80ad-4151-af1b-bbe1480958d1/recipe.tar.gz",
            "type": "s3"
          },
          "linux_distribution": "sles15",
          "name": "cray-shasta-uan-cos-sles15sp1.x86_64-@product_version@",
          "recipe_type": "kiwi-ng"
        }
        ```

    2. Save the id of the IMS recipe in an environment variable.

        ```bash
        ncn-m001# export IMS_RECIPE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
        ```

    3. Use the saved IMS recipe id in the procedure [Build an Image Using IMS REST Service](Build_an_Image_Using_IMS_REST_Service.md) to build the UAN image.

4. **Optional:** Build the UAN image by customizing it manually. Skip this step if the UAN image was built automatically in the previous step.

    1. Identify the base UAN image to customize.

        ```bash
        ncn-m001# cray ims images list --format json | jq '.[] | select(.name | contains("uan"))'
        {
          "created": "2021-02-18T17:17:44.168655+00:00",
          "id": "6d46d601-c41f-444d-8b49-c9a2a55d3c21",
          "link": {
            "etag": "371b62c9f0263e4c8c70c8602ccd5158",
            "path": "s3://boot-images/6d46d601-c41f-444d-8b49-c9a2a55d3c21/manifest.json",
            "type": "s3"
          },
          "name": "uan-PRODUCT_VERSION-image"
        }
        ```

    2. Save the id of the IMS image in an environment variable.

        ```bash
        ncn-m001# export IMS_IMAGE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
        ```

    3. Use the saved IMS image id in the procedure [Customize an Image Root Using IMS](Customize_an_Image_Root_Using_IMS.md) to build the UAN image.

[Boot UANs](Boot_UANs.md)

