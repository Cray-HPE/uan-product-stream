Copyright 2021 Hewlett Packard Enterprise Development LP


# UAN 2.0.2 Patch Upgrade Guide

- [About](#about)
  - [Release-Specific Procedures](#release-specific-procedures)
  - [Common Environment Variables](#common-environment-variables)
- [Preparation](#preparation)
- [Deploy Manifests](#deploy-manifests)


<a name="about"></a>
## About

This guide contains procedures for upgrading systems running UAN 2.0 to the
latest available patch release. It is intended for system installers, system
administrators, and network administrators. It assumes some familiarity with
standard Linux and associated tooling.

<a name="release-specific-procedures"></a>
### Release-Specific Procedures

Select procedures are annotated to indicate they are only applicable to
specific Shasta patch releases.

> **`WARNING:`** Follow this procedure only when upgrading to UAN 2.0.2.

> **`WARNING:`** Follow this procedure only when upgrading from UAN 2.0.0.


<a name="common-environment-variables"></a>
### Common Environment Variables

For convenience these procedures use the following environment variables:

- `UAN_RELEASE` - The UAN release version, e.g., `2.0.2`.
- `UAN_DISTDIR` - The directory of the _extracted_ UAN release distribution.


<a name="preparation"></a>
## Preparation

The remainder of this guide assumes the new UAN release distribution has been
extracted at `$UAN_DISTDIR`.

> **`NOTE`**: Use `--no-same-owner` and `--no-same-permissions` options to
> `tar` when extracting a UAN release distribution as `root` to ensure the
> extracted files are owned by `root` and have permissions based on the current
> `umask` value.

List current UAN versions in the product catalog:

```bash
ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.uan}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
```

<a name="deploy-manifests"></a>
## Deploy Manifests

```bash
ncn-m001# ${UAN_DISTDIR}/install.sh
```

## Update VCS Content

The deployment of the new manifests will install a new product branch in VCS.  These updates need to be merged into the VCS branch being used to configure UANs.  Refer to Section `12.8.2 VCS Branching Strategy` of the
Administration Guide.  The following steps should be performed to merge the new release into the current branch.
This example will use a branch named `integration` as the current branch holding the existing UAN configuration
data.

1. Clone the UAN configuration management repository.  The repository is located in the VCS/Gitea service
   and the location is reported in the `cray-product-catalog` Kubernetes ConfigMap in the
   `configuration.clone_url` key. Replace the hostname with `api-gw-service-nmm.local` when cloning the
   repository.

   ```bash
   ncn-m001:~/ $ git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
   # [... output removed ...]

   ncn-m001:~/ $ cd uan-config-management && git checkout cray/uan/@product_version@ && git pull
   Branch 'cray/uan/@product_version@' set up to track remote branch 'cray/uan/@product_version@' from 'origin'.
   Already up to date.
   ```

1. Checkout the branch currently used to hold UAN configuration.  (`integration` in this example)

   ```bash
   ncn-m001:~/ $ git checkout integration
   Switched to branch 'integration'
   Your branch is up to date with 'origin/integration'.
   ```

1. Merge the newly install branch to the current branch.

   ```bash
   ncn-m001:~/ $ git merge cray/uan/@product_version@
   ### A commit message will be presented.  Write and exit to merge. 
   ```

1. Get the `crayvcs` password and push the changes to VCS.

   ```bash
   ncn-m001:~/ $ kubectl get secret -n services vcs-user-credentials \
                  --template={{.data.vcs_password}} | base64 --decode

   ncn-m001:~/ $ git push
   ```

1. Retrieve the commit ID from the merge.

   ```bash
   ncn-m001:~/ $ git rev-parse --verify HEAD
   ```

1. Update any CFS configurations used by the UANs with the commit ID from step 4.
