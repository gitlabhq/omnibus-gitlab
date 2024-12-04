#!/usr/bin/env bash

# Fetch and replace the python3 checksum.
# Dependencies: wget, sed, awk

set -eo pipefail

source "$(dirname "$0")/shared.sh"
build_file="config/software/python3.rb"

get_checksum() {
  local version="$1"
  local archive_url="https://www.python.org/ftp/python/${version}/Python-${version}.tgz"

  # Python does not publish sha sums for their source tarballs, so we calculate it from the archive.
  wget -q -O - "$archive_url" | sha256sum | awk '{print $1}'
}

version=$(get_default_version "$build_file")
checksum=$(get_checksum "$version")
replace_sha256_checksum "$checksum" "$build_file"
