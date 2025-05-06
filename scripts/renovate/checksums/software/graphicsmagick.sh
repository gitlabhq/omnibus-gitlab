#!/usr/bin/env bash

# Fetch and replace the graphicsmagick checksum.
# Dependencies: wget, awk, sha256sum

set -eo pipefail

source "$(dirname "$0")/shared.sh"
build_file="config/software/graphicsmagick.rb"

get_checksum() {
  local version="$1"
  local archive_url="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/${version}/GraphicsMagick-${version}.tar.xz"
  # Graphicsmagick does not publish sha sums for their source tarballs, so we calculate it from the archive.
  wget -q -O - "$archive_url" | sha256sum | awk '{print $1}'
}

version=$(get_default_version "$build_file")
checksum=$(get_checksum "$version")
replace_sha256_checksum "$checksum" "$build_file"
