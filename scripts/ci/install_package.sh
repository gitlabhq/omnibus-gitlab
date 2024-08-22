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

# Configure repository
echo "Installing ${package_name} using https://${package_repo_token}packages.gitlab.com/install/repositories/gitlab/${package_repository}/script.${package_type}.sh"
curl https://${package_repo_token}packages.gitlab.com/install/repositories/gitlab/${package_repository}/script.${package_type}.sh | bash

# Install GitLab
${package_manager} install -y ${package_name_version_dist} || (echo "Failed to install ${package_name_version_dist}" && exit 1)
