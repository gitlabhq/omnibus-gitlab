#!/bin/bash

VERSION=$1
TYPE=$2

PACKER_PATH=$(pwd)/support/packer

cd $PACKER_PATH

packer build -var "aws_access_key=$AWS_ACCESS_KEY_ID" -var "aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var "version=$VERSION" $PACKER_PATH/$TYPE.json
