#!/bin/bash -x
sleep 30

# Configuring repo for future updates
sudo apt-get update
sudo debconf-set-selections <<< 'postfix postfix/mailname string your.hostname.com'
sudo debconf-set-selections <<< 'postfix postfix/main_mailer_type string "Internet Site"'
sudo apt-get install -y curl openssh-server ca-certificates postfix
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

# Placing license file to be used during installation
sudo mkdir -p /etc/gitlab
echo "$GITLAB_LICENSE_FILE" | sudo tee /etc/gitlab/predefined.gitlab-license > /dev/null

# Downloading package from S3 bucket and installing it
curl -o gitlab.deb "$DOWNLOAD_URL"
sudo dpkg -i gitlab.deb
sudo rm gitlab.deb

# Set install type to aws
echo "gitlab-aws-marketplace-ami" | sudo tee /opt/gitlab/embedded/service/gitlab-rails/INSTALLATION_TYPE > /dev/null

# Cleanup
sudo rm -rf /var/lib/apt/lists/*
sudo find /root/.*history /home/*/.*history -exec rm -f {} \;
sudo rm -f /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys

# Create startup scripts to set instance ID as initial password
cat <<EOF | sudo tee /var/lib/cloud/scripts/per-instance/gitlab
#!/bin/bash

export INSTANCE_ID=\$(curl http://169.254.169.254/latest/meta-data/instance-id)
sudo gitlab-rails runner "u = User.first; u.update!(password: '\${INSTANCE_ID}', password_confirmation: '\${INSTANCE_ID}', password_automatically_set: false) if u.password_automatically_set?"
EOF

sudo chmod +x /var/lib/cloud/scripts/per-instance/gitlab
