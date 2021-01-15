# uan-product-stream

The uan-product-stream repo provides release.sh and install.sh
scripts for generating a UAN product release distribution and
installing it, respectively.

Bloblet generation is currently done in master and release/shasta-X.Y
branches, not main or release/X.Y.Z branches (where X.Y.Z is the
UAN version, not the overarching "Shasta" version.

## Setting up a Release

### Setup vars.sh

Use `UAN_RELEASE_VERSION` and `UAN_RELEASE_PREFIX` to switch between master
and release builds. These variables define the location of the bloblet
so ensure that location exists on DST servers.

### Update Pointers to Artifacts and Install Content

1. Update the versions of docker images, helm charts, and manifests in
the docker, helm, and manifests directories, respectively.

2. Update the Nexus repos and the blob locations where they will gather
RPMs from in nexus-repositories.yaml.tmpl.

3. Update include/INSTALL.tmpl for installation instructions and include/README
for user-facing documentation.

4. Make any changes necessary for building the release distribution in release.sh

5. Run `git vendor update shastarelm-release` to update the shared libraries
provided by the Shasta Release Management release tools.

### Generate a Release Distribution

Run ./release.sh to create a release distribution. The distribution will
appear as a `dist/${NAME}-${UAN_RELEASE_VERSION}.tar.gz` file. This is the
default release distribution and is meant for airgapped system installations.

#### Online Releases

Run ./release.sh --online to create a release distribution for online
installation. This distribution will not upload artifacts and will
setup proxy repositories in Nexus on the system.
