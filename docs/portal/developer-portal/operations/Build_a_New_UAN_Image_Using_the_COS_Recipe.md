
# Build a New UAN Image Using a COS Recipe

Prior to UAN 2.3, a similar copy of the COS recipe was imported with the UAN install. In the UAN 2.3 release, UAN does not install a recipe, and a COS recipe must be used. Additional uan packages will now be installed via CFS and the `uan_packages` role.

Perform the following before starting this procedure:

- Install the COS, Slingshot, and UAN product streams.
- Initialize the cray administrative CLI.

In the COS recipe for 2.2, several dependencies have been removed, this includes Slingshot, DVS, and Lustre. Those packages are now installed during CFS Image Customization. More information on this change is covered in the [Create UAN Boot Images](Create_UAN_Boot_Images.md#create-boot-images) procedure.

1. Identify the COS image recipe to base the UAN image on. Select the recipe that matches the version of COS that the compute nodes will be using.

   ```bash
   ncn-m001# cray ims recipes list --format json | jq '.[] | select(.name | contains("compute"))'
   {
     "created": "2021-02-17T15:19:48.549383+00:00",
     "id": "4a5d1178-80ad-4151-af1b-bbe1480958d1",  <<-- Note this ID
     "link": {
       "etag": "3c3b292364f7739da966c9cdae096964",
       "path": "s3://ims/recipes/4a5d1178-80ad-4151-af1b-bbe1480958d1/recipe.tar.gz",
       "type": "s3"
     },
     "linux_distribution": "sles15",
     "name": "cray-shasta-compute-sles15sp3.x86_64-2.2.27",
     "recipe_type": "kiwi-ng"
   }
   ```

2. Save the id of the IMS recipe in an environment variable.

   ```bash
   ncn-m001# IMS_RECIPE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
   ```

3. Use the IMS recipe id to build the UAN image:

   More detail on this IMS procedure may be found in the procedure "Build an Image Using IMS REST Service" in the CSM documentation.

   ```bash
   ncn-m001# IMS_PUBLIC_KEY=$(cray ims public-keys list --format json | jq -r ".[] | .id" | head -1)
   ncn-m001# IMS_ARCHIVE_NAME=$(cray ims recipes describe $IMS_RECIPE_ID --format json | jq -r .name)
   ncn-m001# IMS_ARCHIVE_NAME=${IMS_ARCHIVE_NAME/compute/uan}
   ncn-m001# cray ims jobs create --job-type create --public-key-id $IMS_PUBLIC_KEY --image-root-archive-name $IMS_ARCHIVE_NAME --artifact-id $IMS_RECIPE_ID
   ```

4. Perform [Create UAN Boot Images](Create_UAN_Boot_Images.md#create-boot-images) to run CFS Image Customization on the resulting image.
