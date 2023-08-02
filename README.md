# uan-product-stream

The uan-product-stream repo provides release.sh and install.sh
scripts for generating a UAN product release distribution and
installing it, respectively.

Bloblet generation is currently done in master and release/shasta-X.Y
branches, not main or release/uan-X.Y branches (where X.Y is the
UAN major/minor version, not the overarching "Shasta" version).

## Building a Release Distribution

### Setup vars.sh

Use `UAN_RELEASE_VERSION` and `UAN_RELEASE_PREFIX` to switch between builds that
package up master (unstable) or release (stable) builds. These variables define
the location of the bloblet so ensure the locations exist on DST servers before
attempting to build a release distribution.

### Update Pointers to Artifacts and Install Content

1. Update the versions of docker images, helm charts, and manifests in
   the docker, helm, and manifests directories, respectively.

1. Update the Nexus repos and the blob locations where they will gather
   RPMs from in `nexus-repositories.yaml.tmpl`

1. Update `include/INSTALL.tmpl` for installation instructions and
   `include/README` for general user-facing information.

1. Make any changes necessary for building and packaging artifacts for the
   release distribution in release.sh.

1. Ensure the documentation for the UAN is up-to-date in `docs/` for the
   artifacts that are referenced in the manifests.

1. Run `git vendor update shastarelm-release` to update the shared libraries
provided by the Shasta Release Management release tools.

### Generate a Release Distribution (local)

Run `./release.sh` to create a release distribution. The distribution will
appear as a `dist/${NAME}-${VERSION}.tar.gz` file. This is the
default release distribution and is meant for airgapped system installations.

### Generate a Release Distribution (Official)

1. All changes should be made to the `main` branch in this repository through
   a pull request.
1. If not already done, create a release branch format of `release/uan-{major}.{minor}`.
   If the branch already exists, create a PR to pull in main to the release
   branch. Approve and merge the PR (for existing branches). 
1. Tag the commit at the tip of the release branch with the format
   `v{major}.{minor}.{patch}` for official/stable releases. Add release
   candidate/alpha/beta information to the tag if this is a dev/unstable build.
1. Wait for the build pipeline to build the package. The build pipeline in this
   repository is tracking changes to tags. Creating the version tag will
   automatically build the release distribution with the version specified.
1. [Unstable builds](https://artifactory.algol60.net/artifactory/uan/hpe/unstable/)
    are available for download and installation. Any build that is not tagged with
    `v{major}.{minor}.{patch}` (e.g. v1.2.3-RC1) is considered an unstable (dev) build.
1. [Stable builds](https://artifactory.algol60.net/artifactory/uan/hpe/stable/)
   are available for download and installation as well.

### Versioning

The `$VERSION` used when creating a release distribution is based on the latest
git tag in the repository. Git tags are used to determine the version of the
overall UAN product, it is NOT set in any file in this repository.

Rather, the `version.sh` script reads the latest tag in the repository and
appends additional SEMVER-compatible versioning information to the release
distribution name. Version tags in this repository must start with a "v" and be
SEMVER-compliant.

* If the current commit is tagged, the version will be `${git_tag}`, minus the "v".
* If the current commit has progressed past the tag, the output of `git describe`
  will be used (minus the "v") and appended with as is done with `describe` output:
  `${git_tag}-{# commits since tag}-g{commit}`
* If there are unstaged changes, `-dirty` is appended to the version string.

This naming scheme is in place to ensure that development release distributions
can be created and not conflict with official releases.

## Documentation

UAN documentation is stored in the `docs` directory. Please keep it up to date
with the procedures associated with the artifacts that are referenced in the UAN
manifest(s).
