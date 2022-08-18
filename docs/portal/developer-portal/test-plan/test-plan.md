# Test Plan for User Access Node (UAN) and Repurposed Compute Node as UAN

The following is the test plan for the User Access Node (UAN) or a Compute Node that has been repurposed to function as a UAN.  The tests are grouped in three categories:
- Unit tests
- Integration tests
- Functional tests

## Unit Tests

When possible, unit tests are run when the various components of UAN are built (uan-rpms, uan, and uan-product-stream). The `uan` repository contains the ansible code used when UANs boot and configure and much of the testing for that compoment must occur on a fully configured system. Future enhancements are underway to test the various compoments of UAN on a Virtual Shasta enviroment in GCP.
|Summary|Description|Automated|Notes|
|-------|-----------|---------|-----|
|`uan` builds|Verify the `uan` repo is able to generate artifacts|yes|Run `make` in a local checkout|
|`uan-rpms` builds|Verify the `uan-rpms` repo is able to generate rpms|yes|Run `make` in a local checkout|
|`uan-product-stream` builds|Verify the `uan-product-stream` repo is able to generate a release|yes|Tag a new release in `uan-product-stream` or run `make` in a local checkout|

## Integration Tests

The following integration tests verify that the UAN software interacts correctly with the rest of the products. The result of the integration tests will be a fully built and customized UAN image that boots and configures correctly. Depending on the configuration of the test system, extra integrations tests may be performed (HSN booting, WLM configuration, GPU configuration, etc).

| Summary                    | Description                                                  | Automated | Notes                                         |
| -------------------------- | ------------------------------------------------------------ | --------- | --------------------------------------------- |
| Install the UAN product | Run the install procedure | Yes      | Run `install.sh` from Install_the_UAN_Product_Stream.md |
| Build a COS recipe for UAN | Verify the COS recipe can be built as the base for a UAN image | no        | Build_a_New_UAN_Image_Using_the_COS_Recipe.md |
| Run UAN CFS                | Verify the CFS layers run correctly (SHS, UAN, WLM, CPE, etc) | no        | Create_UAN_Boot_Images.md                     |
| Boot UANs                  | Verify the UAN boots successfully                            | no        | Boot_UANS.md                                  |
| Enable HSN booting         | Verify the UAN is able to HSN boot                            | no        | Consult COS documentation                                  |
| Enable GPU                 | Verify the UAN is able to configure GPUs                      | no        | Consult GPU documentation                                  |

## Functional Tests

With a fully configured Shasta system, the following functional tests determines that a UAN is able to perform its intended capabilities. These tests apply to both native UANs and Compute Nodes which have been repurposed as UANs.

| Summary                      | Description                                                  | Automated | Notes                            |
| ---------------------------- | ------------------------------------------------------------ | --------- | -------------------------------- |
| User Authentication          | Verify a user is able to ssh to the UAN using LDAP authentication. | no        | `ssh user@uan`                   |
| Job launch                   | Verify a user is able to submit a basic job.                 | no        | `srun hostname` |
| Verify CPE                   | Verify the Cray Programming Environment is available         | no        | `module list`                    |
| Verify GPU functionality     | Run the test suite if GPUs are configured                    | yes       | `/opt/cray/uan/tests/validate-gpu.sh <nvidia\|amd>` |
| Verify CAN or CHN Configuration | Inspect the network interfaces and default routes used for CAN or CHN | no | <ul><li> For systems running CAN, there must be a `can0` interface present and the default route should be over that device.</li><li>For systems running CHN (including Compute Nodes repurposed as UANs), the `hsn0` interface must have a CHN IP in addition to the HSN IP and the default route should be over the `hsn0` device.</li></ul> |
