# Updating GitLab via omnibus-gitlab

## Documentation version

Please make sure you are viewing this file on the master branch.

![documentation version](doc/images/omnibus-documentation-version-update-md.png)

## Updating from GitLab 6.6.x and higher to the latest version

The procedure can also be used to upgrade from a CE omnibus package to an EE omnibus package.

First, download the latest [CE](https://www.gitlab.com/downloads/) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package to your GitLab server.

```shell
# Stop unicorn and sidekiq so we can do database migrations
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# Create a database backup in case the upgrade fails
sudo gitlab-rake gitlab:backup:create

# Install the latest package
# Ubuntu/Debian:
sudo dpkg -i gitlab_x.x.x-omnibus.xxx.deb
# CentOS:
sudo rpm -Uvh gitlab-x.x.x_xxx.rpm

# Reconfigure GitLab (includes database migrations)
sudo gitlab-ctl reconfigure

# Restart all gitlab services
sudo gitlab-ctl restart
```

Done!

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

## Reverting to GitLab 6.6.x

First download a GitLab 6.6.x [CE](https://www.gitlab.com/downloads/archives/) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package.

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

# Due to a backup restore bug in GitLab 6.6, it is needed to drop the database
# _before_ running `gitlab-ctl reconfigure`.
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production

sudo gitlab-ctl reconfigure

# Restore your backup
sudo gitlab-rake gitlab:backup:restore BACKUP=12345 # where 12345 is your backup timestamp

# Start GitLab
sudo gitlab-ctl start
```

## Upgrading from a non-Omnibus installation to an Omnibus installation
Upgrading from non-Omnibus installations has not been tested by GitLab.com.

Please be advised that you lose your settings in files such as gitlab.yml, unicorn.rb and smtp_settings.rb.
You will have to [configure those settings in /etc/gitlab/gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#configuration).
SMTP is not supported in omnibus-gitlab at this time.

### Upgrading from non-Omnibus PostgreSQL to an Omnibus installation
Upgrade by [creating a backup from the non-Omnibus install](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#create-a-backup-of-the-gitlab-system) and [restoring this in the Omnibus installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#restoring-an-application-backup).
Please ensure you are using exactly equal versions of GitLab (for example 6.7.3) when you do this.
You might have to upgrade your non-Omnibus installation before creating the backup to achieve this.

### Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)
Unlike the previous chapter, the non-Omnibus installation is using MySQL while the Omnibus installation is using PostgreSQL.

Option #1: Omnibus can be configured to use an external [non-packaged MySQL database](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#using-a-non-packaged-database-management-server).

Option #2: Convert to PostgreSQL and use the built-in server as the instructions below.

* [create a backup of the non-Omnibus MySQL installation.](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#create-a-backup-of-the-gitlab-system)
* unpack the newly created backup.

```shell
mkdir unpacked_backup
tar -C unpacked_backup -xvf <TIMESTAMP>_gitlab_backup.tar
```

* [export and convert the existing MySQL database](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/mysql_to_postgresql.md)  (without importing to PostgreSQL).

```shell
mysqldump --compatible=postgresql --default-character-set=utf8 -r gitlab.mysql -u root gitlabhq_production
python db_converter.py gitlab.mysql gitlab.psql

```

* replace `unpacked_backup/db/database.sql` with the converted `gitlab.psql`

```shell
cp gitlab.pSql unpacked_backup/db/database.sql
```

* repack the modified backup.

```shell
cd unpacked_backup
tar cvf ../converted_gitlab_backup.tar *
```

* [restoring this in the Omnibus installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#restoring-an-application-backup)
* Enjoy!
