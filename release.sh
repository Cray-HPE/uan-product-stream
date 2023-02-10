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
    sed -e "s/@name@/${NAME}/g
               s/@product_version@/${VERSION}/g
               s/@doc_product_manifest_version@/${DOC_PRODUCT_MANIFEST_VERSION}/g" "${BUILDDIR}/manifests/docs-product-manifest.yaml" > "${BUILDDIR}/docs-product-manifest.yaml"

    rsync -aq "${ROOTDIR}/docker/" "${BUILDDIR}/docker/"
    # Set any dynamic variables in the UAN manifest
    sed -i -e "s/@uan_version@/${UAN_CONFIG_VERSION}/g" "${BUILDDIR}/docker/index.yaml"
    sed -i -e "s/@product_catalog_version@/${PRODUCT_CATALOG_UPDATE_VERSION}/g" "${BUILDDIR}/docker/index.yaml"

    rsync -aq "${ROOTDIR}/helm/" "${BUILDDIR}/helm/"
    # Set any dynamic variables in the UAN manifest
    sed -i -e "s/@uan_version@/${UAN_CONFIG_VERSION}/g" "${BUILDDIR}/helm/index.yaml"
}

function copy_tests {
    rsync -aq "${ROOTDIR}/tests/" "${BUILDDIR}/tests/"
}

function copy_docs {
    DATE="`date`"
    rsync -aq "${ROOTDIR}/docs/" "${BUILDDIR}/docs/"
    # Set any dynamic variables in the UAN docs
    for docfile in `find "${BUILDDIR}/docs/" -name "*.md" -o -name "*.ditamap" -type f`;
    do
        sed -i.bak -e "s/@product_version@/${VERSION}/g" "$docfile"
        sed -i.bak -e "s/@name@/${NAME}/g" "$docfile"
        sed -i.bak -e "s/@date@/${DATE}/g" "$docfile"
    done
    for bakfile in `find "${BUILDDIR}/docs/" -name "*.bak" -type f`;
    do
        rm $bakfile
    done
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
            s#@bloblet_url@#${BLOBLET_URL}#g
            s/@name@/${NAME}/g" ${REPOFILE} | \
        generate-nexus-config repository  > "${BUILDDIR}/nexus-repositories.yaml"
}

function sync_repo_content {
    # sync helm charts
    helm-sync "${BUILDDIR}/helm/index.yaml" "${BUILDDIR}/helm"

    # sync container images
    skopeo-sync "${BUILDDIR}/docker/index.yaml" "${BUILDDIR}/docker"

    if [ ! -z "$ARTIFACTORY_USER" ] && [ ! -z "$ARTIFACTORY_TOKEN" ]; then
        REPOCREDSPATH="/tmp/"
        REPOCREDSFILENAME="repo_creds.json"
        jq --null-input   --arg url "https://artifactory.algol60.net/artifactory/" --arg realm "Artifactory Realm" --arg user "$ARTIFACTORY_USER"   --arg password "$ARTIFACTORY_TOKEN"   '{($url): {"realm": $realm, "user": $user, "password": $password}}' > $REPOCREDSPATH$REPOCREDSFILENAME
        REPO_CREDS_DOCKER_OPTIONS="--mount type=bind,source=${REPOCREDSPATH},destination=/repo_creds_data"
        REPO_CREDS_RPMSYNC_OPTIONS="-c /repo_creds_data/${REPOCREDSFILENAME}"
        trap "rm -f '${REPOCREDSPATH}${REPOCREDSFILENAME}'" EXIT
    fi

    # sync uan repos from bloblet
    rpm-sync "${ROOTDIR}/rpm/cray/uan/sle-15sp4/index.yaml" "${BUILDDIR}/rpms/sle-15sp4"
    createrepo "${BUILDDIR}/rpms/sle-15sp4"
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
UAN_IMAGE_NAME=$UAN_IMAGE_NAME
UAN_KERNEL_VERSION=$UAN_KERNEL_VERSION
EOF

    rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"
    rsync -aq "${ROOTDIR}/init-ims-image.sh" "${BUILDDIR}/"
    rsync -aq "${ROOTDIR}/validate-pre-install.sh" "${BUILDDIR}/"
}

function package_distribution {
    PACKAGE_NAME=${NAME}-${VERSION}
    tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${PACKAGE_NAME}.tar.gz $(basename $BUILDDIR)
}

function sync_image_content {
    mkdir -p "${BUILDDIR}/images/application/${UAN_IMAGE_NAME}"
    pushd "${BUILDDIR}/images/application/${UAN_IMAGE_NAME}"
    for url in "${APPLICATION_ASSETS[@]}"; do
      cmd_retry curl -sfSLOR -u "${ARTIFACTORY_USER}:${ARTIFACTORY_TOKEN}" "$url"
      ASSET=$(basename $url)
      md5sum $ASSET | cut -d " " -f1 > ${ASSET}.md5sum
    done
    popd
}

function update_iuf_product_manifest {
    pushd "${BUILDDIR}/images/application/${UAN_IMAGE_NAME}"
    for asset in "${APPLICATION_ASSETS[@]}"; do
      ASSET=$(basename $asset);
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
    sed -i -e "s/@uan_rootfs_md5sum@/${UAN_ROOTFS_MD5SUM}/g
               s/@uan_kernel_md5sum@/${UAN_KERNEL_MD5SUM}/g
               s/@uan_initrd_md5sum@/${UAN_INITRD_MD5SUM}/g" "${BUILDDIR}/iuf-product-manifest.yaml"
}

if [ ! -z "$ARTIFACTORY_USER" ] && [ ! -z "$ARTIFACTORY_TOKEN" ]; then
    export REPOCREDSVARNAME="REPOCREDSVAR"
    export REPOCREDSVAR=$(jq --null-input --arg url "https://artifactory.algol60.net/artifactory/" --arg realm "Artifactory Realm" --arg user "$ARTIFACTORY_USER"   --arg password "$ARTIFACTORY_TOKEN"   '{($url): {"realm": $realm, "user": $user, "password": $password}}')
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

# initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"
mkdir -p "${BUILDDIR}/lib"

# Create the Release Distribution
copy_manifests
copy_tests
copy_docs
sync_install_content
setup_nexus_repos
sync_third_party_content
sync_repo_content
sync_image_content
update_iuf_product_manifest
iuf-validate "${BUILDDIR}/iuf-product-manifest.yaml"

# copy ansible from uan-config container
REGISTRY_DIR="${BUILDDIR}/docker/artifactory.algol60.net/uan-docker/stable"
SRC_DIR=$(find ${REGISTRY_DIR} -name "cray-uan-config*")
extract-from-container ${SRC_DIR} ${BUILDDIR}/vcs/ "content"

# remove these special files from the OCI layers
find ${BUILDDIR}/vcs -type f -name '.wh..wh..opq' -delete

# Add back error detection mistakenly disabled by the vendor
# lib extract-from-container function
set -e

# Save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
package_distribution
