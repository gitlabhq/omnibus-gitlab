#!/bin/env bash

set -eo pipefail

package_name_version_dist=$(bundle exec rake build:package:name_version 2>&1 | tail -n1)
package_name=$(bundle exec rake build:package:name)
package_repository=${package_repository:-$package_name}

if [ -z "${package_repository}" ]; then
  echo "Unable to detect package repository. Exiting.";
  exit 1;
fi

if [ -z "${package_name}" ]; then
  echo "Unable to detect GitLab edition. Exiting.";
  exit 1;
fi

if [ -z "${package_type}" ]; then
  echo "Package type (deb/rpm) not specified. Exiting.";
  exit 1;
fi

if [ -z "${package_manager}" ]; then
  echo "Package manager (apt/yum/zypper) not specified. Exiting.";
  exit 1;
fi

# Feature flag to control package repository source (Pulp vs packagecloud)
# Set to 'false' to use the old packagecloud repository
USE_PULP_REPO=${USE_PULP_REPO:-true}

# Configure repository
if [ "${USE_PULP_REPO}" = "true" ]; then
  # Use Pulp repository (new behavior)
  PULP_URL=${PULP_URL:?"PULP_URL is required when USE_PULP_REPO=true. Exiting."}
  # Pulp install scripts support basic auth via `username` and `password` env vars.
  PULP_USER=${PULP_USER:?"PULP_USER is required when USE_PULP_REPO=true. Exiting."}
  PULP_PASSWORD=${PULP_PASSWORD:?"PULP_PASSWORD is required when USE_PULP_REPO=true. Exiting."}

  install_script_url="${PULP_URL}/install/repositories/gitlab/${package_repository}/script.${package_type}.sh"
  echo "Installing ${package_name} using ${install_script_url}"
  ( 
    export username="${PULP_USER}" password="${PULP_PASSWORD}"
    curl -L "${install_script_url}" | bash
  )
else
  # Use packagecloud repository (old behavior)
  if [ -z "${package_repo_token:-}" ]; then
    echo "package_repo_token is required when USE_PULP_REPO=false. Exiting.";
    exit 1;
  fi

  install_script_url="https://${package_repo_token}packages.gitlab.com/install/repositories/gitlab/${package_repository}/script.${package_type}.sh"
  echo "Installing ${package_name} using ${install_script_url}"
  curl "${install_script_url}" | bash
fi

# Add zypper-specific flag to auto-import GPG keys during package installation
# and to ensure non-interactive package install
if [ "${package_manager}" = "zypper" ]; then
  package_manager="zypper --gpg-auto-import-keys --non-interactive"
fi

# Install GitLab
${package_manager} install -y ${package_name_version_dist} || (echo "Failed to install ${package_name_version_dist}" && exit 1)
