#!/usr/bin/env bash
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
#
# User Access Node Installation Script

set -Eeuox pipefail
function notify {
        FAILED_COMMAND="$(caller): ${BASH_COMMAND}"
        echo "ERROR: ${FAILED_COMMAND}"
}
trap notify ERR

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/lib/install.sh"

: "${RELEASE:="$(basename "$(realpath "$ROOTDIR")")"}"

# Generate manifests
mkdir -p "${ROOTDIR}/build/manifests"
manifestgen -i "${ROOTDIR}/manifests/uan.yaml" -o "${ROOTDIR}/build/manifests/uan.yaml"

load-install-deps

# Setup Nexus
nexus-setup blobstores   "${ROOTDIR}/nexus-blobstores.yaml"
nexus-setup repositories "${ROOTDIR}/nexus-repositories.yaml"

# Upload repository contents for offline installs
export SKOPEO_IMAGE=${SKOPEO_IMAGE}
export CRAY_NEXUS_SETUP_IMAGE=${CRAY_NEXUS_SETUP_IMAGE}
[[ -f "${ROOTDIR}/lib/nexus-upload.sh" ]] && . "${ROOTDIR}/lib/nexus-upload.sh"

clean-install-deps

# Deploy manifests
loftsman ship --charts-path "${ROOTDIR}/helm" --manifest-path "${ROOTDIR}/build/manifests/uan.yaml"
