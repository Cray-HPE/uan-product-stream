Copyright 2021 Hewlett Packard Enterprise Development LP


# UAN 2.0.1 Patch Upgrade Guide

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

> **`WARNING:`** Follow this procedure only when upgrading to UAN 2.0.1.

> **`WARNING:`** Follow this procedure only when upgrading from UAN 2.0.0.


<a name="common-environment-variables"></a>
### Common Environment Variables

For convenience these procedures use the following environment variables:

- `UAN_RELEASE` - The UAN release version, e.g., `2.0.1`.
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

## Update UAN Image Recipe

There is a bug in the UAN Image Recipe shipped with the system.  It is missing one repository entry
required for building the UAN image.  Before building a new UAN image from the recipe in the UAN
Product Catalog, follow these steps to add the missing repository entry.

1. View the current UAN Product Catalog.

   ```bash
   ncn-m001:~ $ kubectl get cm -n services cray-product-catalog -o json | jq -r .data.uan
   @product_version@:
     configuration:
       clone_url: https://vcs.<domain>/vcs/cray/uan-config-management.git
       commit: 6658ea9e75f5f0f73f78941202664e9631a63726
       import_branch: cray/uan/@product_version@
       import_date: 2021-02-02 19:14:18.399670
       ssh_url: git@vcs.<domain>:cray/uan-config-management.git
     images:
       cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
         id: c880251d-b275-463f-8279-e6033f61578b
    recipes:
      cray-shasta-uan-cos-sles15sp1.x86_64-0.1.17:
        id: cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a                         # <--- IMS recipe id
   ```
1. Download the image recipe.

   1. Get the recipe path from IMS.

      ```bash
      ncn-m001:~ $ cray ims recipes describe cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a
      created = "2021-04-12T18:59:59.851877+00:00"
      id = "cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a"
      linux_distribution = "sles15"
      name = "cray-shasta-uan-cos-sles15sp1-x86_64-0.1.17"
      recipe_type = "kiwi-ng"

      [link]
      etag = ""
      path = "s3://ims/recipes/cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a/recipe.tgz"
      type = "s3"
      ```

   1. Get the recipe.tgz from S3.

      ```bash
      ncn-m001:~ $ mkdir -p /tmp/uan-recipe/recipe
      ncn-m001:~ $ cd /tmp/uan-recipe/recipe
      ncn-m001:~ $ cray artifacts get ims recipes/cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a/recipe.tgz recipe.tgz
      ncn-m001:~ $ tar zxf recipe.tgz
      ncn-m001:~ $ rm recipe.tgz
      ```

   1. Edit config.xml and add the new repository entry following repository entry.

      Add this content to the list of repositories (at/near line 197):

      ```bash
      <!-- SUSE SLE15sp1 packages, Nexus repo -->
      <repository type="rpm-md" alias="SUSE-SLE-Module-Server-Applications-15-SP1-x86_64-Pool" priority="4" imageinclude="true">
        <source path="https://packages.local/repository/SUSE-SLE-Module-Server-Applications-15-SP1-x86_64-Pool/"/>
      </repository>

      <!-- SUSE SLE15sp1 packages, Nexus repo -->
      <repository type="rpm-md" alias="SUSE-SLE-Module-Server-Applications-15-SP1-x86_64-Updates" priority="4" imageinclude="true">
        <source path="https://packages.local/repository/SUSE-SLE-Module-Server-Applications-15-SP1-x86_64-Updates/"/>
      </repository>
      ```
1. Package the new recipe and update the artifacts storage.

   ```bash
   ncn-m001:~ $ tar zcf ../recipe.tgz *
   ncn-m001:~ $ cray artifacts create ims recipes/cbd5cdf6-eac3-47e6-ace4-aa1aecb1359a/recipe.tgz ../recipe.tgz