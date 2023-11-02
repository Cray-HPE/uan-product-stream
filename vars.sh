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

# Versions for container images and helm charts
PRODUCT_CATALOG_UPDATE_VERSION=1.3.2
UAN_CONFIG_VERSION=1.12.9

# Versions for UAN images
UAN_IMAGE_RELEASE=stable
UAN_IMAGE_VERSION=5.1.9
UAN_IMAGE_ARCH=x86_64
UAN_KERNEL_VERSION=5.14.21-150400.24.63-default
UAN_IMAGE_NAME=cray-application-sles15sp4.$UAN_IMAGE_ARCH-$UAN_IMAGE_VERSION
UAN_IMAGE_URL=https://artifactory.algol60.net/artifactory/csm-images/$UAN_IMAGE_RELEASE/application

# Dependencies for UAIs on Application nodes
K3S_VERSION=1.26.0
METALLB_VERSION=0.13.7
HAPROXY_VERSION=1.17.3
HAPROXY_CONTAINER_VERSION=2.6.6
K3S_URL=https://github.com/k3s-io/k3s/releases/download/v$K3S_VERSION%2Bk3s1
K3S_INSTALLER=https://get.k3s.io
METALLB_URL=https://metallb.github.io/metallb
HAPROXY_URL=https://haproxytech.github.io/helm-charts

# Versions for doc product manifest
DOC_PRODUCT_MANIFEST_VERSION="^0.1.0" # Keep this field like this until further notice

APPLICATION_ASSETS=(
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/application-$UAN_IMAGE_VERSION-$UAN_IMAGE_ARCH.squashfs
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/$UAN_KERNEL_VERSION-$UAN_IMAGE_VERSION-$UAN_IMAGE_ARCH.kernel
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/initrd.img-$UAN_IMAGE_VERSION-$UAN_IMAGE_ARCH.xz
)

THIRD_PARTY_ASSETS=(
    $K3S_URL/k3s
    $K3S_URL/k3s-airgap-images-amd64.tar
    $K3S_INSTALLER/k3s-install.sh
)

HPE_SIGNING_KEY=https://arti.dev.cray.com/artifactory/dst-misc-stable-local/SigningKeys/HPE-SHASTA-RPM-PROD.asc

BLOBLET_URL="https://artifactory.algol60.net/artifactory/uan-rpms/hpe/stable"
