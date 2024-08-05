#!/usr/bin/env bash

# Fetch and replace the libxml2 checksum.
# Dependencies: curl, sed, awk

set -eo pipefail

source "$(dirname "$0")/shared.sh"
build_file="config/software/libxml2.rb"

get_checksum() {
  local version="$1"
  local minor_version=$(sed -nr 's|(\w*).(\w*).(\w*)|\1.\2|p' <<< "$version")

  local checksum_file_url="https://download.gnome.org/sources/libxml2/${minor_version}/libxml2-${version}.sha256sum"
  local archive_name="libxml2-${version}.tar.xz"

  wget -q -O - "$checksum_file_url" | awk -v file="$archive_name" '{if($2==file){print $1}}'
}

version=$(get_default_version "$build_file")
checksum=$(get_checksum "$version")
replace_sha256_checksum "$checksum" "$build_file"
