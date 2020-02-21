#!/bin/bash

VERSION=$1
TYPE=$2
DOWNLOAD_URL=$3

# Expanding the variable to get actual license file contents
if [ -n "$4" ]; then
  EE_LICENSE_FILE=${!4}
fi

PACKER_PATH=$(pwd)/support/packer

cd $PACKER_PATH

packer build -var "aws_access_key=$AWS_AMI_ACCESS_KEY_ID" -var "aws_secret_key=$AWS_AMI_SECRET_ACCESS_KEY" -var "version=$VERSION" -var "download_url=$DOWNLOAD_URL" -var "license_file=$EE_LICENSE_FILE" $PACKER_PATH/$TYPE.json
