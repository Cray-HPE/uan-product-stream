Copyright 2021 Hewlett Packard Enterprise Development LP


# UAN 2.0 Patch Upgrade Guide

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