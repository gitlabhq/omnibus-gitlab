#!/bin/bash
# Set version to version.gitlab.com
# Env. variable CI_VERSION_TOKEN, CI_VERSION_API_URL and CI_BUILD_REF_NAME need
# to be set

BUILD_REF_NAME=$1
CI_VERSION_API_URL=$2
CI_VERSION_TOKEN=$3

VERSION=$(echo $BUILD_REF_NAME | grep -o -v "+rc" | grep -o -E "^[0-9]+\.[0-9]\.[0-9]")
if [ -z "$BUILD_REF_NAME" ] || [ -z "$CI_VERSION_API_URL" ] || [ -z "$CI_VERSION_TOKEN" ]; then
    echo "Missing one of the arguments! (options: BUILD_REF_NAME, CI_VERSION_API_URL, CI_VERSION_TOKEN)"
    exit 1
else
  if [ -z "$VERSION" ]; then
      echo "$BUILD_REF_NAME not eligible for adding to version.gitlab.com"
  else
      echo "Matched $VERSION from $BUILD_REF_NAME"
      curl -X POST --header "Content-Type application/json" -d "private_token=$CI_VERSION_TOKEN" -d "version=$VERSION" "$CI_VERSION_API_URL/versions/"
  fi
fi
