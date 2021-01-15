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

# TODO figure out where to actually get customizations from
: "${CUSTOMIZATIONS:="/opt/cray/site-info/customizations.yaml"}"

# Generate manifests with customizations
mkdir -p "${ROOTDIR}/build/manifests"
manifestgen -i "${ROOTDIR}/manifests/uan.yaml" -c "$CUSTOMIZATIONS" -o "${ROOTDIR}/build/manifests/uan.yaml"

load-install-deps

# Setup Nexus
nexus-setup blobstores   "${ROOTDIR}/nexus-blobstores.yaml"
nexus-setup repositories "${ROOTDIR}/nexus-repositories.yaml"

# Upload repository contents for offline installs
[[ -x "${ROOTDIR}/lib/nexus-upload.sh" ]] && "${ROOTDIR}/lib/nexus-upload.sh"

clean-install-deps

# Deploy manifests
loftsman ship --charts-path "${ROOTDIR}/helm" --manifest-path "${ROOTDIR}/build/manifests/uan.yaml"

