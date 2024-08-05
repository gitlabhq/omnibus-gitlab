#!/usr/bin/env bash

get_default_version() {
  sed -nr "s|default_version '(.*)'|\1|p" "${1}"
}

replace_sha256_checksum() {
  local new_checksum="${1}"
  local build_file="${2}"

  sed -i "s|sha256: '\w*'|sha256: '${new_checksum}'|" "$build_file"
}
