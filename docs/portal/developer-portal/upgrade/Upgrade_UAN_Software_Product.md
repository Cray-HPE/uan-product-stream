# Upgrade UAN software product

Follow upgrade instructions in [*HPE Cray EX System Software Getting Started Guide (S-8000)*](https://www.hpe.com/support/ex-S-8000) to upgrade the UAN software product. Those instructions provide:

- Complete information about the options and arguments for the `cne-install` tool
- The correct sequence for upgrading UAN and other HPE Cray EX software products.

If UAN and COS were upgraded at the same time using `cne-install`, skip these instructions and [Boot UANs](../operations/Boot_UANs.md).

## About `cne-install`

The Compute Node Environment (CNE) installer (`cne-install`) simplifies upgrading several products of the HPE Cray EX software like SLE, COS, Slingshot Host Software, UAN, SMA, and SAT by providing the ability to automate many CNE upgrade tasks. `cne-install` does not support fresh installations of the CNE software.

The `cne-install` tool automates the upgrade of several compute node environment software products from tarball to producing a compute node image without interaction. This new tool automates the following:

- processing several product tarballs
- updating the git branches for each product
- updating the CFS configuration
- performing NCN personalization
- using `sat bootprep` to create and customize the compute and UAN node images
- creating the BOS session template in a single command

The `cne-install` tool can also be used to automate only specific stages of this process, allowing administrators to also use manual steps when necessary.

The UAN and COS installation and upgrade processes based on `install.sh` do not automatically affect the state of any other existing COS software on the system, for example COS software like the Data Virtualization Service \(DVS\) running on non-compute node \(NCN\) worker nodes or any COS software that runs on compute nodes. Administrators must perform additional procedures after the `install.sh` script has completed to use those upgraded software components. All of those tasks, however are performed automatically when administrators upgrade UAN via the `cne-install` tool.

HPE recommends that customers:

- **Upgrade all of the CNE products at the same time using the `cne-install` tool whenever possible.** This method greatly reduces chance of errors and saves customers time.
- **Upgrade COS and UAN at the same time using `cne-install` even if the other CNE products cannot be upgraded as well at the same time.** The UAN software products depends heavily on the COS software product code. Therefore, COS upgrades will almost always require a UAN upgrade.

Customer sites can use `cne-install` to upgrade UAN separately from COS, when necessary.

## Upgrade UAN automatically with `cne-install`

Perform this procedure if UAN was not already upgraded according to the workflow in the [*HPE Cray EX System Software Getting Started Guide (S-8000)*](https://www.hpe.com/support/ex-S-8000).

1. Copy the release distribution tarball file for UAN and any other products you wish to upgrade to a dedicated directory on ncn-m001.

If you only want to upgrade UAN, only the UAN tarball should be copied in this directory. The `cne-install` tool inspects the contents of the media directory and automatically upgrades supported products.

3. Run the CNE installer using the instructions in the [*HPE Cray EX System Software Getting Started Guide (S-8000)*](https://www.hpe.com/support/ex-S-8000).

`cne-install` will create the compute node and UAN images, as well as the BOS session templates required to boot those images. The tool will log progress is logged to `LOG_DIR` (defaults to `$PWD/log`) and output goes to stdout. If `cne-install` fails, the user can perform manual steps to correct the action, then restart `cne-install` from any stage or just re-run that stage by itself.

You do not need to perform any additional steps described in this document to configure UAN.

4. Perform [Boot UANs](../operations/Boot_UANs.md) to reboot the UANs with the new image.

The `cne-install` tool does not reboot compute nodes or UANs. The name of the UAN bos-sessiontemplate file is the same one from the `sat bootprep` input files that were used in the `cne-install` command.

## Upgrade UAN manually

Performing a manual upgrade of UAN from one version to the next follows the same general process as a fresh install. Some considerations may need to be made when merging the existing CFS configuration with the latest CFS configuration provided by the release.

The overall workflow for completing a UAN upgrade involves:

1. Perform the [UAN Installation](../install/Install_the_UAN_Product_Stream.md)

2. Review any [Notable Changes](Notable_Changes.md)

3. [Merge UAN CFS Configuration Data](Merge_UAN_Configuration_Data.md)

4. [Create UAN images and reboot](../operations/Create_UAN_Boot_Images.md)
