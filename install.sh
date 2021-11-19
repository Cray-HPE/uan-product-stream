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
