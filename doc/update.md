# Updating GitLab via omnibus-gitlab

## Documentation version

Please make sure you are viewing this file on the master branch.

![documentation version](images/omnibus-documentation-version-update-md.png)

## Updating from GitLab 6.6 and higher to 7.10 or newer

In the 7.10 package we have added the `gitlab-ctl upgrade` command, and we
configured the packages to run this command automatically after the new package
is installed. If you are installing GitLab 7.9 or earlier, please see the
[procedure below](#updating-from-gitlab-66-and-higher-to-the-latest-version).

All you have to do is `dpkg -i gitlab-ce-XXX.deb` (for Debian/Ubuntu) or `rpm
-Uvh gitlab-ce-XXX.rpm` (for Centos/Enterprise Linux). After the package has
been unpacked, GitLab will automatically:

- Stop all GitLab services;
- Create a backup using your current, old GitLab version. This is a 'light'
  backup that **only backs up the SQL database**;
- Run `gitlab-ctl reconfigure`, which will perform any necessary database
  migrations (using the new GitLab version);
- Restart the services that were running when the upgrade script was invoked.

If you do not want the DB-only backup, automatic start/stop and DB migrations
to be performed automatically please run the following command before upgrading
your GitLab instance:

```
sudo touch /etc/gitlab/skip-auto-migrations
```

## Updating from GitLab 6.6 and higher to the latest version

The procedure can also be used to upgrade from a CE omnibus package to an EE omnibus package.

First, download the latest [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package to your GitLab server.

#### Stop services but leave postgresql running for the database migrations and create a backup

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop nginx
sudo gitlab-rake gitlab:backup:create
```

#### Install the latest package

```
# Ubuntu/Debian:
sudo dpkg -i gitlab_x.x.x-omnibus.xxx.deb

# CentOS:
sudo rpm -Uvh gitlab-x.x.x_xxx.rpm
```

#### Reconfigure GitLab (includes running database migrations) and restart all services

```
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

Done!

#### Troube? Check status details

```
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

## Updating from GitLab 6.6.0.pre1 to 6.6.4

First, download the latest package from https://www.gitlab.com/downloads/ to your GitLab server.


#### Stop unicorn and sidekiq so we can do database migrations

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
```

#### One-time migration because we changed some directories since 6.6.0.pre1

```
sudo mkdir -p /var/opt/gitlab/git-data
sudo mv /var/opt/gitlab/{repositories,gitlab-satellites} /var/opt/gitlab/git-data/
sudo mv /var/opt/gitlab/uploads /var/opt/gitlab/gitlab-rails/
```

#### Install the latest package

```
# Ubuntu:
sudo dpkg -i gitlab_6.6.4-omnibus.xxx.deb

# CentOS:
sudo rpm -Uvh gitlab-6.6.4_xxx.rpm
```

#### Reconfigure GitLab (includes database migrations)

```
sudo gitlab-ctl reconfigure
```

#### Start unicorn and sidekiq

```
sudo gitlab-ctl start
```

Done!

## Reverting to GitLab 6.6.x or later

First download a GitLab 6.x.x [CE](https://www.gitlab.com/downloads/archives/) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package.


#### Stop GitLab

```
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
```

#### Downgrade GitLab to 6.x

```
# Ubuntu
sudo dpkg -r gitlab
sudo dpkg -i gitlab-6.x.x-yyy.deb

# CentOS:
sudo rpm -e gitlab
sudo rpm -ivh gitlab-6.x.x-yyy.rpm
```

#### Prepare GitLab for receiving the backup restore

Due to a backup restore bug in versions earlier than GitLab 6.8.0, it is needed to drop the database
_before_ running `gitlab-ctl reconfigure`, only if you are downgrading to 6.7.x or less.

```
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production
```

#### Reconfigure GitLab (includes database migrations)

```
sudo gitlab-ctl reconfigure
```

#### Restore your backup

```
sudo gitlab-rake gitlab:backup:restore BACKUP=12345 # where 12345 is your backup timestamp
```

#### Start GitLab

```
sudo gitlab-ctl start
```

## Upgrading from a non-Omnibus installation to an Omnibus installation
Upgrading from non-Omnibus installations has not been tested by GitLab.com.

Please be advised that you lose your settings in files such as gitlab.yml, unicorn.rb and smtp_settings.rb.
You will have to [configure those settings in /etc/gitlab/gitlab.rb](/README.md#configuration).

### Upgrading from non-Omnibus PostgreSQL to an Omnibus installation using a backup
Upgrade by [creating a backup from the non-Omnibus install](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#create-a-backup-of-the-gitlab-system) and [restoring this in the Omnibus installation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#omnibus-installations).
Please ensure you are using exactly equal versions of GitLab (for example 6.7.3) when you do this.
You might have to upgrade your non-Omnibus installation before creating the backup to achieve this.

After upgrading make sure that you run the check task: `sudo gitlab-rake gitlab:check`.

If you receive an error similar to `No such file or directory @ realpath_rec - /home/git` run this one liner to fix the git hooks path:

```bash
find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
```

This assumes that `gitlab-shell` is located in `/home/git`

### Upgrading from non-Omnibus PostgreSQL to an Omnibus installation in-place
It is also possible to upgrade a source GitLab installation to omnibus-gitlab
in-place.  Below we assume you are using PostgreSQL on Ubuntu, and that you
have an omnibus-gitlab package matching your current GitLab version.  We also
assume that your source installation of GitLab uses all the default paths and
users.

First, stop and disable GitLab, Redis and Nginx.

```
# Ubuntu
sudo service gitlab stop
sudo update-rc.d gitlab disable

sudo service nginx stop
sudo update-rc.d nginx disable

sudo service redis-server stop
sudo update-rc.d redis-server disable
```

If you are using a configuration management system to manage GitLab on your
server, remember to also disable GitLab and its related services there. Also
note that in the following steps, the existing home directory of the git user
(`/home/git`) will be changed to `/var/opt/gitlab`.


Next, create a `gitlab.rb` file for your new setup.

```
sudo mkdir /etc/gitlab
sudo tee -a /etc/gitlab/gitlab.rb <<'EOF'
# Use your own GitLab URL here
external_url 'http://gitlab.example.com'

# We assume your repositories are in /home/git/repositories (default for source installs)
git_data_dir '/home/git'

# Re-use the Postgres that is already running on your system
postgresql['enable'] = false
# This db_host setting is for Debian Postgres packages
gitlab_rails['db_host'] = '/var/run/postgresql/'
gitlab_rails['db_port'] = 5432
# We assume you called the GitLab DB user 'git'
gitlab_rails['db_username'] = 'git'
EOF
```

Now install the omnibus-gitlab package and run `sudo gitlab-ctl reconfigure`.

You are not done yet! The `gitlab-ctl reconfigure` run has changed the home
directory of the git user, so OpenSSH can no longer find its authorized_keys
file. Rebuild the keys file with the following command:

```
sudo gitlab-rake gitlab:shell:setup
```

You should now have HTTP and SSH access to your GitLab server with the
repositories and users that were there before.

If you can log into the GitLab web interface, the next step is to reboot your
server to make sure none of the old services interferes with omnibus-gitlab.

If you are using special features such as LDAP you will have to put your
settings in gitlab.rb; see the [omnibus-gitlab
README](/README.md#configuration).

### Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)
Unlike the previous chapter, the non-Omnibus installation is using MySQL while the Omnibus installation is using PostgreSQL.

Option #1: Omnibus packages for EE can be configured to use an external [non-packaged MySQL database](/README.md#using-a-mysql-database-management-server-enterprise-edition-only).

Option #2: Convert to PostgreSQL and use the built-in server as the instructions below.

* [Create a backup of the non-Omnibus MySQL installation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#create-a-backup-of-the-gitlab-system)
* [Export and convert the existing MySQL database in the GitLab backup file](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/mysql_to_postgresql.md#converting-a-gitlab-backup-file-from-mysql-to-postgres)
* [Restore this in the Omnibus installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/98b1bfb0d70082953d63abbc329cd6f2c628d3bc/README.md#restoring-an-application-backup)
* [Rebuild database indexes](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/mysql_to_postgresql.md#for-omnibus-gitlab-installations)
* Enjoy!

## RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```
rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

# Updating GitLab CI via omnibus-gitlab
## Updating from GitLab CI version prior to 5.4.0 to the latest version

In GitLab CI 5.4.0 we changed the way GitLab CI authorizes with GitLab.

In order to use GitLab CI 5.4.x, GitLab 7.7.x is required.

Make sure that GitLab 7.7.x is installed and running and then go to Admin section of GitLab.
Under Applications create a new a application which will generate the `app_id` and `app_secret`.

In `/etc/gitlab/gitlab.rb`:

```
gitlab_ci['gitlab_server'] = { "url" => 'http://gitlab.example.com', "app_id" => '12345678', "app_secret" => 'QWERTY12345' }

```

where `url` is the url to the GitLab instance.

Make sure to run `sudo gitlab-ctl reconfigure` after saving the configuration.
