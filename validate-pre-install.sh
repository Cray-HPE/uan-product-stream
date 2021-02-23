#!/usr/bin/env bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
export GOSS_BASE=${ROOTDIR}/tests/goss

goss -g ${GOSS_BASE}/tests/goss-software-prereqs.yaml validate
