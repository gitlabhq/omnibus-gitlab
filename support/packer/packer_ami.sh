#!/bin/bash

# DEV
VERSION=$1
TYPE=$2
DOWNLOAD_URL=$3

PACKER_PATH=$(pwd)/support/packer

cd $PACKER_PATH

packer build -var "aws_access_key=$AWS_AMI_ACCESS_KEY_ID" -var "aws_secret_key=$AWS_AMI_SECRET_ACCESS_KEY" -var "version=$VERSION" -var "download_url=$DOWNLOAD_URL" $PACKER_PATH/$TYPE.json
