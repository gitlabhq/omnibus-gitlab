#!/usr/bin/env bash

# Fetch and replace the libarchive checksum.
# Dependencies: curl, sed, awk

set -eo pipefail

source "$(dirname "$0")/shared.sh"
build_file="config/software/libarchive.rb"

get_checksum() {
  local version="$1"
  local archive_name="*libarchive-${version}.tar.gz"

  wget -q -O - "https://libarchive.org/downloads/sha256sums" | awk -v file="$archive_name" '{if($2==file){print $1}}'
}

version=$(get_default_version "$build_file")
checksum=$(get_checksum "$version")
replace_sha256_checksum "$checksum" "$build_file"
