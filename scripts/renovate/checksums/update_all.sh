#!/usr/bin/env bash
#
# Update all checksums managed by renovate.

SCRIPT_DIR=$(dirname "$0")

for checksum_script in "${SCRIPT_DIR}"/software/*.sh; do
  echo "Running ${checksum_script}"
  ./"${checksum_script}"
done
