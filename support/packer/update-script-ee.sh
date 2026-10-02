#!/bin/bash -x
sleep 30

# Configuring repo for future updates
sudo apt-get update
sudo debconf-set-selections <<< 'postfix postfix/mailname string your.hostname.com'
sudo debconf-set-selections <<< 'postfix postfix/main_mailer_type string "Internet Site"'
sudo apt-get install -y curl openssh-server ca-certificates postfix libatomic1
apt_status=$?
if [ ${apt_status} -ne 0 ]; then
  echo "Failed to install prerequisite packages (apt-get exit code ${apt_status})" >&2
  exit ${apt_status}
fi
repo_setup_script="$(mktemp)"
mktemp_status=$?
if [ ${mktemp_status} -ne 0 ]; then
  echo "Failed to create a temp file for the GitLab repository setup script (mktemp exit code ${mktemp_status})" >&2
  exit ${mktemp_status}
fi
trap 'rm -f "${repo_setup_script}"' EXIT
curl -fsSL "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" -o "${repo_setup_script}"
curl_status=$?
if [ ${curl_status} -ne 0 ]; then
  echo "Failed to download GitLab repository setup script (curl exit code ${curl_status})" >&2
  exit ${curl_status}
fi
sudo bash "${repo_setup_script}"
repo_setup_status=$?
if [ ${repo_setup_status} -ne 0 ]; then
  echo "Failed to configure GitLab package repository (exit code ${repo_setup_status})" >&2
  exit ${repo_setup_status}
fi

# Downloading package from CI artifact
wget --no-verbose --header "JOB-TOKEN: ${CI_JOB_TOKEN}" "${DOWNLOAD_URL}" -O /tmp/gitlab.deb
wget_status=$?
if [ ${wget_status} -ne 0 ]; then
  echo "Failed to download GitLab package from ${DOWNLOAD_URL} (wget exit code ${wget_status})" >&2
  exit ${wget_status}
fi
# Explicitly passing EXTERNAL_URL to prevent automatic EC2 IP detection.
sudo EXTERNAL_URL="http://gitlab.example.com" dpkg -i /tmp/gitlab.deb
dpkg_status=$?
if [ ${dpkg_status} -ne 0 ]; then
  echo "Failed to install /tmp/gitlab.deb (dpkg exit code ${dpkg_status})" >&2
  exit ${dpkg_status}
fi
sudo rm /tmp/gitlab.deb

# Set install type to aws
echo "gitlab-aws-ami" | sudo tee /opt/gitlab/embedded/service/gitlab-rails/INSTALLATION_TYPE > /dev/null

# Cleanup
sudo rm -rf /var/lib/apt/lists/*
sudo find /root/.*history /home/*/.*history -exec rm -f {} \;
sudo rm -f /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys

sudo mv ~/ami-startup-script.sh /var/lib/cloud/scripts/per-instance/gitlab
sudo chmod +x /var/lib/cloud/scripts/per-instance/gitlab
