# Upgrades

Performing an upgrade of UAN from one version to the next follows the same general process as a fresh install. Some considerations may need to be made  when merging the existing CFS configuration with the latest CFS configuration provided by the release.

The overall workflow for completing a UAN upgrade involves:

1. Perform the [UAN Installation](../install/Install_the_UAN_Product_Stream.md) 

2. Review any [Notable Changes](Notable_Changes.md)

3. [Merge UAN CFS Configuration Data](Merge_UAN_Configuration_Data.md)

4. [Recreate UAN images from an IMS recipe](../operations/Build_a_New_UAN_Image_Using_the_COS_Recipe.md)

5. [Customize UAN images and reboot](../operations/Create_UAN_Boot_Images.md)
* Run CFS Image Customization on the new UAN image
   
* Update the BOS session template
   
* Reboot the UANs