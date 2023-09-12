#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright [2020-2022] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
set -Eeuox pipefail

# Function to log errors for simpler debugging
function notify {
        FAILED_COMMAND="$(caller): ${BASH_COMMAND}"
        echo "ERROR: ${FAILED_COMMAND}"
}
trap notify ERR

# Extract ansible from the UAN CFS container for IUF and version scanning
function extract_ansible {
    # copy ansible from uan-config container
    REGISTRY_DIR="${BUILDDIR}/docker/artifactory.algol60.net/uan-docker/stable"
    SRC_DIR=$(find ${REGISTRY_DIR} -name "cray-uan-config*")
    extract-from-container ${SRC_DIR} ${BUILDDIR}/vcs/ "content"

    # remove these special files from the OCI layers
    find ${BUILDDIR}/vcs -type f -name '.wh..wh..opq' -delete

    # Add back error detection mistakenly disabled by the vendor
    # lib extract-from-container function
    set -e
}

# Scan the UAN CFS (ansible) for version information. This prevents duplication
# of version fields and helps decouple the ansible from the release build pipeline
function extract_and_replace_versions {
    cmd_retry curl -sfSLOR "$UAN_VCS_VERSIONS_URL"
    if [[ ! $? ]]; then
        echo "Could not curl $UAN_VCS_VERSIONS_FILE"
        exit 1
    fi
    METALLB_VERSION=$($YQ '.metallb_version' < ${ROOTDIR}/$UAN_VCS_VERSIONS_FILE)
    HAPROXY_VERSION=$($YQ '.haproxy_version' < ${ROOTDIR}/$UAN_VCS_VERSIONS_FILE)
    K3S_VERSION=$($YQ '.k3s_version' < ${ROOTDIR}/$UAN_VCS_VERSIONS_FILE)
    FRR_VERSION=$($YQ '.frr_version' < ${ROOTDIR}/$UAN_VCS_VERSIONS_FILE)
    HAPROXY_CONTAINER_VERSION=$($YQ '.haproxy_container_version' < ${ROOTDIR}/$UAN_VCS_VERSIONS_FILE)

    sed -e "s/@metallb_version@/${METALLB_VERSION}/g
            s/@haproxy_version@/${HAPROXY_VERSION}/g
            s/@k3s_version@/${K3S_VERSION}/g
            s/@frr_version@/${FRR_VERSION}/g
            s/@haproxy_container_version@/${HAPROXY_CONTAINER_VERSION}/g" "${ROOTDIR}/vars.sh" > "${ROOTDIR}/vars_replaced.sh"
}

function copy_manifests {
    rsync -aq "${ROOTDIR}/manifests/" "${BUILDDIR}/manifests/"
    # Set any dynamic variables in the UAN manifest
    sed -i -e "s/@product_version@/${VERSION}/g" "${BUILDDIR}/manifests/uan.yaml"
    sed -i -e "s/@uan_version@/${UAN_CONFIG_VERSION}/g" "${BUILDDIR}/manifests/uan.yaml"

    # Set any dynamic variables in the iuf-product-manifest
    sed -e "s/@product_version@/${VERSION}/g 
            s/@major@/${MAJOR}/g
            s/@minor@/${MINOR}/g
            s/@patch@/${PATCH}/g
            s/@uan_image_name@/${UAN_IMAGE_NAME}/g
            s/@uan_image_version@/${UAN_IMAGE_VERSION}/g
            s/@uan_kernel_version@/${UAN_KERNEL_VERSION}/g" "${BUILDDIR}/manifests/iuf-product-manifest.yaml" > "${BUILDDIR}/iuf-product-manifest.yaml"

    rsync -aq "${ROOTDIR}/docker/" "${BUILDDIR}/docker/"
    # Set any dynamic variables in the UAN manifest
    sed -i -e "s/@uan_version@/${UAN_CONFIG_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@product_catalog_version@/${PRODUCT_CATALOG_UPDATE_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@metallb_controller_version@/${METALLB_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@metallb_speaker_version@/${METALLB_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@frr_version@/${FRR_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@haproxy_version@/${HAPROXY_CONTAINER_VERSION}/g" "${BUILDDIR}/docker/index.yaml"

    rsync -aq "${ROOTDIR}/helm/" "${BUILDDIR}/helm/"
    # Set any dynamic variables in the UAN manifest
    sed -i -e "s/@uan_version@/${UAN_CONFIG_VERSION}/g" "${BUILDDIR}/helm/index.yaml"
}

function setup_nexus_repos {
    # generate Nexus blob store configuration
    sed s/@name@/${NAME}/g nexus-blobstores.yaml.tmpl | generate-nexus-config blobstore > "${BUILDDIR}/nexus-blobstores.yaml"

    # generate Nexus repository configuration
    REPOFILE=${ROOTDIR}/nexus-repositories.yaml.tmpl

    sed -e "s/@major@/${MAJOR}/g
            s/@minor@/${MINOR}/g
            s/@patch@/${PATCH}/g
            s/@version@/${VERSION}/g
            s/@name@/${NAME}/g" ${REPOFILE} | \
        generate-nexus-config repository  > "${BUILDDIR}/nexus-repositories.yaml"
}

function sync_repo_content {
    # sync helm charts
    helm-sync "${BUILDDIR}/helm/index.yaml" "${BUILDDIR}/helm"

    # sync container images
    skopeo-sync "${BUILDDIR}/docker/index.yaml" "${BUILDDIR}/docker"
}

function sync_third_party_content {
    mkdir -p "${BUILDDIR}/third-party"
    pushd "${BUILDDIR}/third-party"
    for url in "${THIRD_PARTY_ASSETS[@]}"; do
      cmd_retry curl -sfSLOR "$url"
      ASSET=$(basename $url)
      md5sum $ASSET | cut -d " " -f1 > ${ASSET}.md5sum
    done

    helm repo add haproxy $HAPROXY_URL
    helm repo add metallb $METALLB_URL
    helm pull --version $HAPROXY_VERSION haproxy/haproxy 
    helm pull --version $METALLB_VERSION metallb/metallb
    popd
}

function sync_install_content {
    rsync -aq "${VENDOR}/lib/install.sh" "${BUILDDIR}/lib/install.sh"

    sed -e "s/@major@/${MAJOR}/g
            s/@minor@/${MINOR}/g
            s/@patch@/${PATCH}/g
            s/@version@/${VERSION}/g
            s/@name@/${NAME}/g" include/README > "${BUILDDIR}/README"

    sed -e "s/@major@/${MAJOR}/g
            s/@minor@/${MINOR}/g
            s/@patch@/${PATCH}/g
            s/@version@/${VERSION}/g
            s/@name@/${NAME}/g" include/INSTALL.tmpl > "${BUILDDIR}/INSTALL"

    sed -e "s/@major@/${MAJOR}/g
            s/@minor@/${MINOR}/g
            s/@patch@/${PATCH}/g" include/nexus-upload.sh > "${BUILDDIR}/lib/nexus-upload.sh"

    cat << EOF > "${BUILDDIR}/vars.sh"
UAN_PRODUCT_VERSION=$VERSION
UAN_CONFIG_VERSION=$UAN_CONFIG_VERSION
PRODUCT_CATALOG_UPDATE_VERSION=$PRODUCT_CATALOG_UPDATE_VERSION
UAN_IMAGE_VERSION=$UAN_IMAGE_VERSION
UAN_IMAGE_NAME_X86_64=$UAN_IMAGE_NAME_X86_64
UAN_IMAGE_NAME_AARCH64=$UAN_IMAGE_NAME_AARCH64
UAN_IMAGE_NAME=$UAN_IMAGE_NAME
UAN_KERNEL_VERSION=$UAN_KERNEL_VERSION
EOF

    rsync -aq "${ROOTDIR}/tests/" "${BUILDDIR}/tests/"
    rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"
    rsync -aq "${ROOTDIR}/init-ims-image.sh" "${BUILDDIR}/"
    rsync -aq "${ROOTDIR}/validate-pre-install.sh" "${BUILDDIR}/"
    rsync -aq "${ROOTDIR}/iuf_hooks/setup_k3s_groups.sh" "${BUILDDIR}/iuf_hooks/setup_k3s_groups.sh"
}

function package_distribution {
    PACKAGE_NAME=${NAME}-${VERSION}
    tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${PACKAGE_NAME}.tar.gz $(basename $BUILDDIR)
}

function sync_image_content {
    mkdir -p "${BUILDDIR}/images/application/$1"
    pushd "${BUILDDIR}/images/application/$1"
    for url in "${APPLICATION_ASSETS[@]}"; do
      if [[ ${url} != *$2* ]]; then continue; fi
      cmd_retry curl -sfSLOR -u "${ARTIFACTORY_USER}:${ARTIFACTORY_TOKEN}" "$url"
      ASSET=$(basename $url)
      md5sum $ASSET | cut -d " " -f1 > ${ASSET}.md5sum
    done
    find .
    popd
}

function update_iuf_product_manifest {
    pushd "${BUILDDIR}/images/application/$1"
    find .
    for asset in "${APPLICATION_ASSETS[@]}"; do
      ASSET=$(basename $asset);
      if [[ ${asset} != *$2* ]]; then continue; fi
      if [[ ${ASSET} == *squashfs ]]; then
        UAN_ROOTFS_MD5SUM=$(cat ${ASSET}.md5sum);
      fi
      if [[ ${ASSET} == *kernel ]]; then
        UAN_KERNEL_MD5SUM=$(cat ${ASSET}.md5sum);
      fi
      if [[ ${ASSET} == *xz ]]; then
        UAN_INITRD_MD5SUM=$(cat ${ASSET}.md5sum);
      fi
    done
    popd
    if [[ $1 == *x86_64* ]]; then
      sed -i -e "s/@uan_rootfs_md5sum_x86_64@/${UAN_ROOTFS_MD5SUM}/g
                 s/@uan_kernel_md5sum_x86_64@/${UAN_KERNEL_MD5SUM}/g
                 s/@uan_initrd_md5sum_x86_64@/${UAN_INITRD_MD5SUM}/g" "${BUILDDIR}/iuf-product-manifest.yaml"
    else
      sed -i -e "s/@uan_rootfs_md5sum_aarch64@/${UAN_ROOTFS_MD5SUM}/g
                 s/@uan_kernel_md5sum_aarch64@/${UAN_KERNEL_MD5SUM}/g
                 s/@uan_initrd_md5sum_aarch64@/${UAN_INITRD_MD5SUM}/g" "${BUILDDIR}/iuf-product-manifest.yaml"
    fi

}

if [ ! -z "$ARTIFACTORY_USER" ] && [ ! -z "$ARTIFACTORY_TOKEN" ]; then
    export REPOCREDSVARNAME="REPOCREDSVAR"
    export REPOCREDSVAR=$(jq --null-input --arg url "https://artifactory.algol60.net/artifactory/" --arg realm "Artifactory Realm" --arg user "$ARTIFACTORY_USER" --arg password "$ARTIFACTORY_TOKEN"   '{($url): {"realm": $realm, "user": $user, "password": $password}}')
fi

# Definitions and sourced variables
ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
VENDOR="${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/"

# Set PYTHONPATH to nothing so ${VENDOR}/lib/release.sh doesn't error on an undefined
PYTHONPATH=""

source "${ROOTDIR}/vars.sh"
source "${ROOTDIR}/assets.sh"
source "${VENDOR}/lib/release.sh"
requires rsync tar generate-nexus-config helm-sync skopeo-sync rpm-sync vendor-install-deps sed realpath
BUILDDIR="$(realpath -m "$ROOTDIR/dist/${NAME}-${VERSION}")"

# Initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"
mkdir -p "${BUILDDIR}/lib"
mkdir -p "${BUILDDIR}/iuf_hooks"

# Collect version information from UAN VCS and inject into vars.sh
extract_and_replace_versions
source "${ROOTDIR}/vars_replaced.sh"

echo "VARS FILE IS HERE"
cat ${ROOTDIR}/vars_replaced.sh

env

# Create the Release Distribution
copy_manifests
sync_install_content
setup_nexus_repos
sync_third_party_content
sync_repo_content
sync_image_content $UAN_IMAGE_NAME_X86_64 x86_64
sync_image_content $UAN_IMAGE_NAME_AARCH64 aarch64
update_iuf_product_manifest $UAN_IMAGE_NAME_X86_64 x86_64
update_iuf_product_manifest $UAN_IMAGE_NAME_AARCH64 aarch64
extract_ansible

# Save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

iuf-validate "${BUILDDIR}/iuf-product-manifest.yaml"

# Package the distribution into an archive
package_distribution
