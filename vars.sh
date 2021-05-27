# Copyright 2020 Hewlett Packard Enterprise Development LP
# Name and Version Information for the User Access Node Distribution
NAME=uan

# This should be the overall UAN version and this git commit should be tagged
# with this version like v{VERSION}.
VERSION=$(./version.sh)
MAJOR=`./vendor/semver get major ${VERSION}`
MINOR=`./vendor/semver get minor ${VERSION}`
PATCH=`./vendor/semver get patch ${VERSION}`

# For building and installing a master distribution, use 'master' here.
#UAN_RELEASE_VERSION=master
#UAN_RELEASE_PREFIX=dev

# For building and installing a release distribution, use the DST Shasta release
# here and comment above.
# Note that "uan-2.1-bloblet" is used because the uan.blobets file is in a 
# branch "release/uan-2.1-bloblet" in this repo. This will get better 
# when arti.dev.cray.com is used for rpms
UAN_RELEASE_VERSION=${NAME}-2.1-bloblet
UAN_RELEASE_PREFIX=release

BLOBLET_URL="http://dst.us.cray.com/dstrepo/bloblets/${NAME}/${UAN_RELEASE_PREFIX}/${UAN_RELEASE_VERSION}"
CAR_URL="http://car.dev.cray.com/artifactory/${NAME}/SCMS/sle15_sp2_ncn"
