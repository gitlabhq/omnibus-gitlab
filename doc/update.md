# Updating GitLab via omnibus-gitlab

## Updating from GitLab 6.6.0.pre1 to 6.6.4

First, download the latest package from https://www.gitlab.com/downloads/ to your GitLab server.

```shell
# Stop unicorn and sidekiq so we can do database migrations
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# One-time migration because we changed some directories since 6.6.0.pre1
sudo mkdir -p /var/opt/gitlab/git-data
sudo mv /var/opt/gitlab/{repositories,gitlab-satellites} /var/opt/gitlab/git-data/
sudo mv /var/opt/gitlab/uploads /var/opt/gitlab/gitlab-rails/

# Install the latest package
# Ubuntu:
sudo dpkg -i gitlab_6.6.4-omnibus.xxx.deb
# CentOS:
sudo rpm -Uvh gitlab-6.6.4_xxx.rpm 

# Reconfigure GitLab (includes database migrations)
sudo gitlab-ctl reconfigure

# Start unicorn and sidekiq
sudo gitlab-ctl start
```

Done!
