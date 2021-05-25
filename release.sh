#!/usr/bin/env bash
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
set -Eeuox pipefail

# Function to log errors for simpler debugging
function notify {
        FAILED_COMMAND="$(caller): ${BASH_COMMAND}"
        echo "ERROR: ${FAILED_COMMAND}"
}
trap notify ERR

# Command line option to create an online (not-airgapped) release distribution
function setup_command_options {
    IS_ONLINE=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --online)
            IS_ONLINE=true;;
        *)
            echo &2 "error: unsupported argument: $1"
            echo &2 "usage: ${0##*/} [--online]"
            exit 1
            ;;
        esac
        shift
    done
}

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
    if [[ $IS_ONLINE == true ]] ; then
        REPOFILE=${ROOTDIR}/nexus-repositories-online.yaml.tmpl
    fi

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

    # Modify how docker images will be imported so helm charts will work without changes
    mkdir "${BUILDDIR}/docker/arti.dev.cray.com/cray"
    mv ${BUILDDIR}/docker/arti.dev.cray.com/csm-docker-stable-local/* "${BUILDDIR}/docker/arti.dev.cray.com/cray"
    mv ${BUILDDIR}/docker/arti.dev.cray.com/uan-docker-stable-local/* "${BUILDDIR}/docker/arti.dev.cray.com/cray"
    rmdir "${BUILDDIR}/docker/arti.dev.cray.com/csm-docker-stable-local"
    rmdir "${BUILDDIR}/docker/arti.dev.cray.com/uan-docker-stable-local"

    # sync uan repos from bloblet
    reposync "${BLOBLET_URL}/rpms/cray-sles15-sp2-ncn/" "${BUILDDIR}/rpms/cray-sles15-sp2-ncn/"
}

function sync_install_content {
    rsync -aq "${ROOTDIR}/vendor/stash.us.cray.com/scm/shastarelm/release/lib/install.sh" "${BUILDDIR}/lib/install.sh"

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

    if [[ $IS_ONLINE == true ]] ; then
        cat "${ROOTDIR}/install.sh" \
            | sed -e 's#loftsman ship --charts-path "${ROOTDIR}/helm"#loftsman ship --charts-repo "http://helmrepo.dev.cray.com:8080/"#' \
            > "${BUILDDIR}/install.sh"
        chmod +x "${BUILDDIR}/install.sh"
    else
        rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"
        rsync -aq "${ROOTDIR}/include/nexus-upload.sh" "${BUILDDIR}/lib/nexus-upload.sh"
    fi

    rsync -aq "${ROOTDIR}/validate-pre-install.sh" "${BUILDDIR}/"
}

function package_distribution {
    PACKAGE_NAME=${NAME}-${VERSION}
    if [[ $IS_ONLINE == true ]] ; then
        PACKAGE_NAME=${NAME}-${VERSION}-online
    fi
    tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${PACKAGE_NAME}.tar.gz $(basename $BUILDDIR)
}

# Definitions and sourced variables
ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/vars.sh"
source "${ROOTDIR}/vendor/stash.us.cray.com/scm/shastarelm/release/lib/release.sh"
requires rsync tar generate-nexus-config helm-sync skopeo-sync reposync vendor-install-deps sed realpath
BUILDDIR="$(realpath -m "$ROOTDIR/dist/${NAME}-${VERSION}")"

# initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"
mkdir -p "${BUILDDIR}/lib"

# Create the Release Distribution
setup_command_options "$@"
copy_manifests
copy_tests
copy_docs
sync_install_content
setup_nexus_repos
if [[ $IS_ONLINE == false ]] ; then
    echo >&2 "Warning: online release skips syncing assets"
    sync_repo_content
fi

# Save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
package_distribution
