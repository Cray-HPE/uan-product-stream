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
PRODUCT_CATALOG_UPDATE_VERSION=1.6.0
UAN_CONFIG_VERSION=1.10.1

# Versions for UAN images
UAN_IMAGE_RELEASE=stable
UAN_IMAGE_VERSION=0.2.1
UAN_KERNEL_VERSION=5.3.18-150300.59.87-default
UAN_IMAGE_NAME=cray-application-sles15sp3.x86_64-$UAN_IMAGE_VERSION
UAN_IMAGE_URL=https://artifactory.algol60.net/artifactory/user-uan-images/$UAN_IMAGE_RELEASE/application

# Versions for doc product manifest
DOC_PRODUCT_MANIFEST_VERSION="^0.1.0" # Keep this field like this until further notice

APPLICATION_ASSETS=(
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/application-$UAN_IMAGE_VERSION.squashfs
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/$UAN_KERNEL_VERSION-$UAN_IMAGE_VERSION.kernel
    $UAN_IMAGE_URL/$UAN_IMAGE_VERSION/initrd.img-$UAN_IMAGE_VERSION.xz
)

HPE_SIGNING_KEY=https://arti.dev.cray.com/artifactory/dst-misc-stable-local/SigningKeys/HPE-SHASTA-RPM-PROD.asc

BLOBLET_URL="https://artifactory.algol60.net/artifactory/uan-rpms/hpe/stable"
