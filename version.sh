#!/usr/bin/env bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Version script required by the build pipeline. This script should output
# the version of the release distribution as defined by the tag of this commit.

# Tags should be of the format v[semver-compatible version]

# If the tag is v1.2.3:
#   and the pipeline runs this, then the version will be 1.2.3
#   and this is run locally, then the version will be 1.2.3
#   and this is run locally with committed changes, then the version will be 1.2.3-{commits}-{git hash}
#   and this is run locally with uncommitted changes, then the version will be appended with '-dirty'
set -eo pipefail

version=$(git describe --tags --match 'v*' | sed -e 's/^v//')
if [[ ! -z $(git status -s) ]]; then
    echo ${version}'-dirty'
else
    echo ${version}
fi
