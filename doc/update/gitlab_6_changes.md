---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab 6 specific changes

## Updating from GitLab `6.6` and higher to the latest version

NOTE: **Note:**
The procedure can also be used to upgrade from a CE Omnibus package to an EE
Omnibus package.

First, download the latest [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
[EE (license key required)](https://about.gitlab.com/install/)
package to your GitLab server.

1. Stop services, but leave PostgreSQL running for the database migrations and
   create a backup:

   ```shell
   sudo gitlab-ctl stop unicorn
   sudo gitlab-ctl stop sidekiq
   sudo gitlab-ctl stop nginx
   sudo gitlab-rake gitlab:backup:create
   ```

1. Install the latest package:

   ```shell
   # Debian/Ubuntu:
   sudo dpkg -i gitlab_x.x.x-omnibus.xxx.deb

   # CentOS:
   sudo rpm -Uvh gitlab-x.x.x_xxx.rpm
   ```

1. Reconfigure GitLab (includes running database migrations) and restart all
   services:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

## Updating from GitLab `6.6.0.pre1` to `6.6.4`

1. First, download the latest package from <https://about.gitlab.com/install/>
   to your GitLab server.

1. Stop Unicorn and Sidekiq so we can do database migrations:

   ```shell
   sudo gitlab-ctl stop unicorn
   sudo gitlab-ctl stop sidekiq
   ```
