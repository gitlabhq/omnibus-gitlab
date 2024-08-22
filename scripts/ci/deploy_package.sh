#!/bin/env bash

set -eo pipefail

if [ "${deploy_instance}" != "true" ]; then
  exit 0;
fi

# Install functional dependencies - procps (for sysctl) and hostname
# TODO: Can they be made runtime_dependency
${package_manager} install -y procps hostname

# Ensure a sysctl config file exists
touch /etc/sysctl.conf

echo "Starting runsv processes"
/opt/gitlab/embedded/bin/runsvdir-start &

echo "Running gitlab-ctl reconfigure"
gitlab-ctl reconfigure
