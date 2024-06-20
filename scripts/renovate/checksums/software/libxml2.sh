#!/usr/bin/env bash

# Fetch and replace the libxml2 checksum.
# Dependencies: curl, sed, awk

set -eo pipefail

libxml2_build_file="config/software/libxml2.rb"

get_target_version() {
  sed -nr "s|default_version '(.*)'|\1|p" "$libxml2_build_file"
}

get_checksum() {
  local version="$1"
  local minor_version=$(sed -nr 's|(\w*).(\w*).(\w*)|\1.\2|p' <<< "$version")

  local checksum_file_url="https://download.gnome.org/sources/libxml2/${minor_version}/libxml2-${version}.sha256sum"
  local archive_name="libxml2-${version}.tar.xz"

  wget -q -O - "$checksum_file_url" | awk -v file="$archive_name" '{if($2==file){print $1}}'
}

replace_checksum() {
  local new_checksum="$1"
  local libxml2_build_file="config/software/libxml2.rb"

  sed -i "s|sha256: '\w*'|sha256: '${new_checksum}'|" "$libxml2_build_file"
}

version=$(get_target_version)
checksum=$(get_checksum "$version")
replace_checksum "$checksum"
