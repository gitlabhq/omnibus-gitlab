#!/bin/bash

set -euo pipefail

NEW_VERSION="${1:-}"

if [[ -z "${NEW_VERSION}" ]]; then
  echo "ERROR: No bundler version specified as argument."
  echo "Usage: $0 <bundler_version>"
  exit 1
fi

directories=("." "config/templates/omnibus-gitlab-gems")

for dir in "${directories[@]}"; do
    echo "Updating bundler ${NEW_VERSION} in directory: $dir"
    cd "$dir"
    bundle update --bundler="${NEW_VERSION}"
    cd -
done

echo "Successfully updated bundler to ${NEW_VERSION}"
