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
# Name and Version Information for the User Access Node Distribution
NAME=uan

# This should be the overall UAN version and this git commit should be tagged
# with this version like v{VERSION}.
VERSION=$(./version.sh)
MAJOR=`./vendor/semver get major ${VERSION}`
MINOR=`./vendor/semver get minor ${VERSION}`
PATCH=`./vendor/semver get patch ${VERSION}`

YQ="docker run -i artifactory.algol60.net/csm-docker/stable/docker.io/mikefarah/yq:4"

# Versions for UAN CFS and Product Catalog Update
PRODUCT_CATALOG_UPDATE_VERSION="1.3.2"
UAN_CONFIG_VERSION='1.14.10'
UAN_VCS_VERSIONS_FILE='uan_versions.yml'
UAN_VCS_VERSIONS_URL="https://raw.githubusercontent.com/Cray-HPE/uan/$UAN_CONFIG_VERSION/ansible/vars/$UAN_VCS_VERSIONS_FILE"

# Versions for UAN images
UAN_IMAGE_RELEASE='stable'
UAN_IMAGE_VERSION='5.2.42'
UAN_KERNEL_VERSION_x86_64='5.14.21-150500.55.28.1.26977.2.PTF.1214754-default'
UAN_KERNEL_VERSION_aarch64='5.14.21-150500.55.28.1.27002.1.PTF.1214754-default'
UAN_IMAGE_NAME='cray-application-sles15sp5'
UAN_IMAGE_NAME_X86_64="$UAN_IMAGE_NAME.x86_64-$UAN_IMAGE_VERSION"
UAN_IMAGE_NAME_AARCH64="$UAN_IMAGE_NAME.aarch64-$UAN_IMAGE_VERSION"
UAN_IMAGE_URL="https://artifactory.algol60.net/artifactory/csm-images/$UAN_IMAGE_RELEASE/compute"

# Dependencies for UAIs on Application nodes
METALLB_VERSION='@metallb_version@'
HAPROXY_VERSION='@haproxy_version@'
K3S_VERSION='@k3s_version@'
FRR_VERSION='@frr_version@'
HAPROXY_CONTAINER_VERSION='@haproxy_container_version@'
K3S_URL="https://github.com/k3s-io/k3s/releases/download/v@k3s_version@%2Bk3s1"
K3S_INSTALLER="https://get.k3s.io"
METALLB_URL="https://metallb.github.io/metallb"
HAPROXY_URL="https://haproxytech.github.io/helm-charts"

# Versions for doc product manifest
DOC_PRODUCT_MANIFEST_VERSION="^0.1.0" # Keep this field like this until further notice

APPLICATION_ASSETS=(
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/compute-$UAN_IMAGE_VERSION-x86_64.squashfs"
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/$UAN_KERNEL_VERSION_x86_64-$UAN_IMAGE_VERSION-x86_64.kernel"
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/initrd.img-$UAN_IMAGE_VERSION-x86_64.xz"
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/compute-$UAN_IMAGE_VERSION-aarch64.squashfs"
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/$UAN_KERNEL_VERSION_aarch64-$UAN_IMAGE_VERSION-aarch64.kernel"
    "$UAN_IMAGE_URL/$UAN_IMAGE_VERSION/initrd.img-$UAN_IMAGE_VERSION-aarch64.xz"
)

THIRD_PARTY_ASSETS=(
    "$K3S_URL/k3s"
    "$K3S_URL/k3s-airgap-images-amd64.tar"
    "$K3S_INSTALLER/k3s-install.sh"
)

HPE_SIGNING_KEY="https://arti.hpc.amslabs.hpecorp.net:443/artifactory/dst-misc-stable-local/SigningKeys/HPE-SHASTA-RPM-PROD.asc"
