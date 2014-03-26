# Updating GitLab via omnibus-gitlab

## Updating from GitLab 6.6.x to 6.7.x

First, download the latest package from https://www.gitlab.com/downloads/ to your GitLab server.

```shell
# Stop unicorn and sidekiq so we can do database migrations
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# Create a database backup in case the upgrade fails
sudo gitlab-rake gitlab:backup:create

# Install the latest package
# Ubuntu:
sudo dpkg -i gitlab_6.7.y-omnibus.xxx.deb
# CentOS:
sudo rpm -Uvh gitlab-6.7.y_xxx.rpm

# Reconfigure GitLab (includes database migrations)
sudo gitlab-ctl reconfigure

# Start unicorn and sidekiq
sudo gitlab-ctl start
```

Done!

### Reverting to GitLab 6.6.x

First download a GitLab 6.6.x package from https://www.gitlab.com/downloads/archives/ .

```
# Stop GitLab
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# Downgrade GitLab to 6.6
# Ubuntu
sudo dpkg -r gitlab
sudo dpkg -i gitlab-6.6.x-yyy.deb

# CentOS:
sudo rpm -e gitlab
sudo rpm -ivh gitlab-6.6.x-yyy.rpm

# Prepare GitLab for receiving the backup restore

# Workaround for a backup restore bug in GitLab 6.6
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production

sudo gitlab-ctl reconfigure

# Restore your backup
sudo gitlab-rake gitlab:backup:restore BACKUP=12345 # where 12345 is your backup timestamp

# Start GitLab
sudo gitlab-ctl start
```

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
