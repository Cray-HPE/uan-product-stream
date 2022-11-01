#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

export CRAY_FORMAT=json

KERNEL_NAME=kernel
INITRD_NAME=initrd
ROOTFS_NAME=rootfs
BUCKET=boot-images

function check_auth() {

  # Check if a Cray CLI configuration exists...
  if cray ims images list 2>&1 | egrep --silent "Error: No configuration exists"; then
    echo "cray command not initialized. Initialize with 'cray init' and try again"
    exit 1
  fi

  # Check if Cray CLI has a valid authentication token...
  if cray ims images list 2>&1 | egrep --silent "401|403"; then
    echo "cray command not authorized. Authorize with 'cray auth login' and try again"
    exit 1
  fi

}

function usage() {

  echo "$0 will create a new IMS image from a kernel, initrd, and rootfs. The "
  echo "artifacts will be uploaded to an S3 bucket, and the manifest.json file expected by "
  echo "IMS will be calculated and registered to the appropriate IMS image ID. The resultant "
  echo "IMS image ID will be returned upon completion."
  echo ""
  echo "Usage: $0 [-h|-b <s3 bucket>] -n <image-name> -k <kernel-path> -i <initrd-path> -r <rootfs-path>"
  echo ""
  echo "options:"
  echo "h      Print this help"
  echo "v      verbose mode"
  echo "n      name of the image"
  echo "k      path to a kernel"
  echo "i      path to an initrd"
  echo "r      path to a rootfs"
  echo "b      S3 Bucket (default boot-images)"
  echo ""
  exit 0

}

function cleanup() {

  if ! [ -z $KERNEL_META ]; then
    cray artifacts delete $BUCKET $IMAGE_ID/$KERNEL_NAME
  fi
  if ! [ -z $INITRD_META ]; then
    cray artifacts delete $BUCKET $IMAGE_ID/$INITRD_NAME
  fi
  if ! [ -z $ROOTFS_META ]; then
    cray artifacts delete $BUCKET $IMAGE_ID/$ROOTFS_NAME
  fi
  if ! [ -z $IMAGE_ID ]; then
    cray ims images delete $IMAGE_ID
  fi

}

while getopts "hvn:k:i:r:b:" arg; do
  case $arg in
    h)
      usage
      ;;
    v)
      set -x
      ;;
    n)
      IMAGE_NAME=$OPTARG
      ;;
    k)
      KERNEL_PATH=$OPTARG
      ;;
    i)
      INITRD_PATH=$OPTARG
      ;;
    r)
      ROOTFS_PATH=$OPTARG
      ;;
    b)
      BUCKET=$OPTARG
      ;;
  esac
done

check_auth

if [ -z $IMAGE_NAME ] || [ -z $KERNEL_PATH ] || [ -z $INITRD_PATH ] || [ -z $ROOTFS_PATH ] ; then
  echo "Specify an image name, and the path to the kernel, initrd, and rootfs"
  usage
  exit 1
fi

error=0
for file in $KERNEL_PATH $INITRD_PATH $ROOTFS_PATH; do
  if ! [ -f $file ]; then
    echo "$file not found"
    error=1
  fi 
done

if [ $error -eq "1" ]; then
  echo "Could not find necessary image artifacts."
  exit 1
fi

# Register a new IMS image
IMAGE_ID=$( cray ims images create --name "$IMAGE_NAME" | jq -r .id )
if [ $? -ne 0 ]; then
  echo "Failed to create IMS image"
  exit 1
fi

# Make sure we don't continue if this somehow return 0 with no id
if [ -z $IMAGE_ID ]; then
  echo "No IMAGE_ID detected"
  exit 1
fi

# Upload kernel artifacts and collect metadata
echo "Uploading kernel for $IMAGE_NAME"
cray artifacts create $BUCKET $IMAGE_ID/$KERNEL_NAME $KERNEL_PATH
KERNEL_META=$( cray artifacts describe boot-images $IMAGE_ID/$KERNEL_NAME | jq -r .artifact )
if [ $? -ne 0 ]; then
  echo "Failed to collect metadata for $IMAGE_ID/$KERNEL_NAME"
  cleanup
  exit 1
fi

# Upload initrd artifacts and collect metadata
echo "Uploading initrd for $IMAGE_NAME"
cray artifacts create $BUCKET $IMAGE_ID/$INITRD_NAME $INITRD_PATH
INITRD_META=$( cray artifacts describe boot-images $IMAGE_ID/$INITRD_NAME | jq -r .artifact )
if [ $? -ne 0 ]; then
  echo "Failed to collect metadata for $IMAGE_ID/$INITRD_NAME"
  cleanup
  exit 1
fi

# Upload rootfs artifacts and collect metadata
echo "Uploading rootfs for $IMAGE_NAME"
cray artifacts create $BUCKET $IMAGE_ID/$ROOTFS_NAME $ROOTFS_PATH
ROOTFS_META=$( cray artifacts describe boot-images $IMAGE_ID/$ROOTFS_NAME | jq -r .artifact )
if [ $? -ne 0 ]; then
  echo "Failed to collect metadata for $IMAGE_ID/$ROOTFS_NAME"
  cleanup
  exit 1
fi

# Collect MD5SUMs and ETAGs for the image artifacts
KERNEL_MD5S=$( echo $KERNEL_META | jq -r .Metadata.md5sum )
INITRD_MD5S=$( echo $INITRD_META | jq -r .Metadata.md5sum )
ROOTFS_MD5S=$( echo $ROOTFS_META | jq -r .Metadata.md5sum )
KERNEL_ETAG=$( echo $KERNEL_META | jq -r .ETag | sed -e 's/\"//g' )
INITRD_ETAG=$( echo $INITRD_META | jq -r .ETag | sed -e 's/\"//g' )
ROOTFS_ETAG=$( echo $ROOTFS_META | jq -r .ETag | sed -e 's/\"//g' )

MANIFEST=$(mktemp)
if [ $? -ne 0 ]; then
  echo "Failed to create a temp file for the manifest"
  cleanup
  exit 1
fi

cat <<EOF > $MANIFEST
  {
    "created": "`date '+%Y-%m-%d %H:%M:%S'`",
    "version": "1.0",
    "artifacts": [
      {
        "link": {
            "etag": "${KERNEL_ETAG}",
            "path": "s3://boot-images/$IMAGE_ID/$KERNEL_NAME",
            "type": "s3"
        },
        "md5": "$KERNEL_MD5S",
        "type": "application/vnd.cray.image.kernel"
      },
      {
        "link": {
            "etag": "${INITRD_ETAG}",
            "path": "s3://boot-images/$IMAGE_ID/$INITRD_NAME",
            "type": "s3"
        },
        "md5": "$INITRD_MD5S",
        "type": "application/vnd.cray.image.initrd"
      },
      {
        "link": {
            "etag": "${ROOTFS_ETAG}",
            "path": "s3://boot-images/$IMAGE_ID/$ROOTFS_NAME",
            "type": "s3"
        },
        "md5": "$ROOTFS_MD5S",
        "type": "application/vnd.cray.image.rootfs.squashfs"
      }
    ]
  }
EOF

cray artifacts create boot-images $IMAGE_ID/manifest.json $MANIFEST
if [ $? -ne 0 ]; then
  echo "Failed to upload the manifest"
  cleanup
  exit 1
fi

cray ims images update $IMAGE_ID --link-type s3 --link-path s3://$BUCKET/$IMAGE_ID/manifest.json
if [ $? -ne 0 ]; then
  echo "Failed to register the manifest with IMS"
  cleanup
  exit 1
fi

echo "$IMAGE_ID"
exit 0
