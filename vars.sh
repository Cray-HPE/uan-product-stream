# Copyright 2020 Hewlett Packard Enterprise Development LP
# Name and Version Information for the User Access Node Distribution
NAME=uan

# This should be the overall UAN version and this git commit should be tagged
# with this version like v{VERSION}.
VERSION=$(./version.sh)
MAJOR=`./vendor/semver get major ${VERSION}`
MINOR=`./vendor/semver get minor ${VERSION}`
PATCH=`./vendor/semver get patch ${VERSION}`

BLOBLET_URL="https://artifactory.algol60.net/artifactory/uan-rpms/hpe/stable"
