#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright [2020-2021] Hewlett Packard Enterprise Development LP
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
    sed -i.bak -e "s/@product_version@/${VERSION}/g" "${BUILDDIR}/manifests/uan.yaml"
}

function copy_tests {
    rsync -aq "${ROOTDIR}/tests/" "${BUILDDIR}/tests/"
}

function copy_docs {
    DATE="`date`"
    rsync -aq "${ROOTDIR}/docs/" "${BUILDDIR}/docs/"
    # Set any dynamic variables in the UAN docs
    for docfile in `find "${BUILDDIR}/docs/" -name "*.md" -type f`;
    do
        sed -i.bak -e "s/@product_version@/${VERSION}/g" "$docfile"
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
    helm-sync "${ROOTDIR}/helm/index.yaml" "${BUILDDIR}/helm"

    # sync container images
    skopeo-sync "${ROOTDIR}/docker/index.yaml" "${BUILDDIR}/docker"

    # sync uan repos from bloblet
    reposync "${BLOBLET_URL}/sle-15sp2" "${BUILDDIR}/rpms/sle-15sp2"
    reposync "${BLOBLET_URL}/sle-15sp3" "${BUILDDIR}/rpms/sle-15sp3"
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

    rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"

    rsync -aq "${ROOTDIR}/validate-pre-install.sh" "${BUILDDIR}/"
}

function package_distribution {
    PACKAGE_NAME=${NAME}-${VERSION}
    tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${PACKAGE_NAME}.tar.gz $(basename $BUILDDIR)
}

# Definitions and sourced variables
ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
VENDOR="${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/"

# Set PYTHONPATH to nothing so ${VENDOR}/lib/release.sh doesn't error on an undefined
PYTHONPATH=""

source "${ROOTDIR}/vars.sh"
source "${VENDOR}/lib/release.sh"
requires rsync tar generate-nexus-config helm-sync skopeo-sync reposync vendor-install-deps sed realpath
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
sync_repo_content

# Save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
package_distribution
