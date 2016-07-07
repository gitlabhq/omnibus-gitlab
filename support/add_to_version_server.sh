#!/bin/bash
# Set version to version.gitlab.com
# Variable VERSION_TOKEN and CI_BUILD_TAG need to be set

CI_BUILD_TAG=$1
VERSION_TOKEN=$2

VERSION=$(echo $CI_BUILD_TAG | grep -o -v "+rc" | grep -o -E "^[0-9]+\.[0-9]+\.[0-9]+")
if [ -z "$CI_BUILD_TAG" ] || [ -z "$VERSION_TOKEN" ]; then
    echo "Missing one of the arguments! (options: CI_BUILD_TAG, VERSION_TOKEN)"
    exit 1
else
  if [ -z "$VERSION" ]; then
      echo "$CI_BUILD_TAG not eligible for adding to version.gitlab.com"
  else
      echo "Matched $VERSION from $CI_BUILD_TAG"
      curl -X POST --header "Content-Type application/json" -d "private_token=$VERSION_TOKEN" -d "version=$VERSION" "https://version.gitlab.com/api/v1/versions/"
  fi
fi
