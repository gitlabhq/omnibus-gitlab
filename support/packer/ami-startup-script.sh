#!/bin/bash

get_ec2_address()
{
  url=$1
  # Try collecting fqdn if it is set correctly
  fqdn=$(/opt/gitlab/embedded/bin/curl -s ${url})
  if [ -n "${fqdn}" ]; then
    # Checking if curl returned an XML message
    word="<?xml"
    if ! $(test "${fqdn#*$word}" != "$fqdn"); then
        EXTERNAL_URL="http://${fqdn}"
    fi
  fi
}

# Attempting to get public hostname. If that is not available, we get public
# IPv4
get_ec2_address "http://169.254.169.254/latest/meta-data/public-hostname"
if [ -z "${EXTERNAL_URL}" ]; then
  get_ec2_address "http://169.254.169.254/latest/meta-data/public-ipv4"
fi

# Replace external URL in gitlab.rb if user hasn't changed it by some other
# means.
EXISTING_EXTERNAL_URL=$(sudo awk '/^external_url/ { print $2 }' /etc/gitlab/gitlab.rb | xargs)
if [ "$EXISTING_EXTERNAL_URL" = "http://gitlab.example.com" ]; then
  sudo sed -i 's!^external_url .*!external_url "'$EXTERNAL_URL'"!g' /etc/gitlab/gitlab.rb
fi

# Setting initial root password to instance ID if user hasn't changed it by
# some other means.
EXISTING_ROOT_PASSWORD=$(sudo grep "^gitlab_rails.*initial_root_password.*" /etc/gitlab/gitlab.rb | cut -d '=' -f2- | xargs)
if [ -z "${EXISTING_ROOT_PASSWORD}" ] && [ -z "${GITLAB_ROOT_PASSWORD}" ]; then
  GITLAB_ROOT_PASSWORD=$(curl http://169.254.169.254/latest/meta-data/instance-id)
fi

sudo GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD} gitlab-ctl reconfigure
