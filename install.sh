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
# User Access Node Installation Script

set -Eeuox pipefail
function notify {
    FAILED_COMMAND="$(caller): ${BASH_COMMAND}"
    echo "ERROR: ${FAILED_COMMAND}"
}
trap notify ERR

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
SYS_NAME=$(craysys metadata get system-name)
SITE_DOMAIN=$(craysys metadata get site-domain)
API_GW=https://api.nmnlb.$SYS_NAME.$SITE_DOMAIN
CURL_ARGS="-s"

if [ $SYS_NAME == "gcp" ]; then
    API_GW="https://api-gw-service-nmn.local"
    CURL_ARGS="-sk"

    # Initialize and auth craycli
    if [[ ! -f /tmp/setup-token.json ]]; then
      ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
      curl -k -s -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=$ADMIN_SECRET https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token > /tmp/setup-token.json
    fi
    export CRAY_CREDENTIALS=/tmp/setup-token.json
    cray init --hostname $API_GW --no-auth --overwrite
fi

function list_ims_images {
    set +x
    TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d \
                             client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                             $API_GW/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    curl $CURL_ARGS -H "Authorization: Bearer ${TOKEN}" $API_GW/apis/ims/images
    unset TOKEN
    set -x
}

source "${ROOTDIR}/lib/install.sh"
source "${ROOTDIR}/vars.sh"

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

# Verify the container runtime is configured to mirror artifactory.algol60.net
if crictl info | jq -e '.config.registry.mirrors | keys | map(select(. == "artifactory.algol60.net")) | length <= 0' >/dev/null; then
    # It's not, so update image references to pull directly from registry.local
    yq w -i "${ROOTDIR}/build/manifests/uan.yaml" 'spec.charts.(name == cray-uan-install).values.cray-import-config.config_image.image.repository' 'registry.local/artifactory.algol60.net/uan-docker/stable/cray-uan-config'
    yq w -i "${ROOTDIR}/build/manifests/uan.yaml" 'spec.charts.(name == cray-uan-install).values.cray-import-config.catalog.image.repository' 'registry.local/artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update'
fi

# Deploy manifests
loftsman ship --charts-path "${ROOTDIR}/helm" --manifest-path "${ROOTDIR}/build/manifests/uan.yaml"

ARTIFACT_PATH=${ROOTDIR}/images/application
KERNEL=${ARTIFACT_PATH}/$UAN_KERNEL_VERSION-$UAN_IMAGE_VERSION.kernel
INITRD=${ARTIFACT_PATH}/initrd.img-$UAN_IMAGE_VERSION.xz
ROOTFS=${ARTIFACT_PATH}/application-$UAN_IMAGE_VERSION.squashfs

# Check for the existence of the SLES image to be installed
IMAGE_ID=$(list_ims_images | jq --arg UAN_IMAGE_NAME "$UAN_IMAGE_NAME" -r 'sort_by(.created) | .[] | select(.name == $UAN_IMAGE_NAME ) | .id' | head -1)
if [ -z $IMAGE_ID ]; then
  ${ROOTDIR}/init-ims-image.sh -n ${UAN_IMAGE_NAME} -k ${KERNEL} -i ${INITRD}  -r ${ROOTFS}
  IMAGE_ID=$(list_ims_images | jq --arg UAN_IMAGE_NAME "$UAN_IMAGE_NAME" -r 'sort_by(.created) | .[] | select(.name == $UAN_IMAGE_NAME ) | .id' | head -1)
else
  echo "Found $UAN_IMAGE_NAME already exists as $IMAGE_ID... Skipping image upload"
fi

if [ -z $IMAGE_ID ]; then
    echo "Could not find an IMS Image ID for $UAN_IMAGE_NAME"
    exit 1
fi

cat << EOF > "$UAN_PRODUCT_VERSION-$IMAGE_ID.json"
images:
  $UAN_IMAGE_NAME:
    id: $IMAGE_ID
EOF

# Register the image with the product catalog
podman run --rm --name uan-$UAN_PRODUCT_VERSION-image-catalog-update \
    -u $USER \
    -e PRODUCT=uan \
    -e PRODUCT_VERSION=$UAN_PRODUCT_VERSION \
    -e YAML_CONTENT=/results/$UAN_PRODUCT_VERSION-$IMAGE_ID.json \
    -e KUBECONFIG=/.kube/admin.conf \
    -v /etc/kubernetes:/.kube:ro \
    -v ${PWD}:/results:ro \
    artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update:$PRODUCT_CATALOG_UPDATE_VERSION
