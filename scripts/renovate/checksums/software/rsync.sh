#!/usr/bin/env bash

# Fetch and replace the rsync checksum.
# Dependencies: curl, sed, awk

set -eo pipefail

source "$(dirname "$0")/shared.sh"
build_file="config/software/rsync.rb"

get_checksum() {
  local version="$1"
  local archive_url="https://download.samba.org/pub/rsync/rsync-${version}.tar.gz"

  # Rsync does not publish sha sums for their source tarballs, so we calculate it from the archive.
  curl -L "$archive_url" | sha256sum | awk '{print $1}'
}

version=$(get_default_version "$build_file")
checksum=$(get_checksum "$version")
replace_sha256_checksum "$checksum" "$build_file"
