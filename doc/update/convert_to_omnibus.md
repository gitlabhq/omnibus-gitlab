---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Upgrading from a non-Omnibus installation to an Omnibus installation

Upgrading from non-Omnibus installations has not been tested by GitLab.com.

Please be advised that you lose your settings in files such as `gitlab.yml`,
`puma.rb` and `smtp_settings.rb`. You will have to
[configure those settings in `/etc/gitlab/gitlab.rb`](../README.md#configuring).

## Upgrading from non-Omnibus PostgreSQL to an Omnibus installation using a backup

Upgrade by [creating a backup from the non-Omnibus install](https://docs.gitlab.com/ee/raketasks/backup_restore.html#creating-a-backup-of-the-gitlab-system)
and [restoring this in the Omnibus installation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-installations).
Ensure you are using **exactly equal versions** of GitLab (for example 6.7.3)
when you do this. You might have to upgrade your non-Omnibus installation before
creating the backup to achieve this.

After upgrading make sure that you run the check task:

```shell
sudo gitlab-rake gitlab:check
```

If you receive an error similar to `No such file or directory @ realpath_rec - /home/git`,
run this one liner to fix the Git hooks path:

```shell
find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
```

This assumes that `gitlab-shell` is located in `/home/git`.

## Upgrading from non-Omnibus PostgreSQL to an Omnibus installation in-place

It is also possible to upgrade a source GitLab installation to Omnibus GitLab
in-place. Below we assume you are using PostgreSQL on Ubuntu, and that you
have an Omnibus GitLab package matching your current GitLab version. We also
assume that your source installation of GitLab uses all the default paths and
users.

First, stop and disable GitLab, Redis and NGINX.

```shell
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
note that in the following steps, the existing home directory of the Git user
(`/home/git`) will be changed to `/var/opt/gitlab`.

Next, create a `gitlab.rb` file for your new setup:

```shell
sudo mkdir /etc/gitlab
sudo tee -a /etc/gitlab/gitlab.rb <<'EOF'
# Use your own GitLab URL here
external_url 'http://gitlab.example.com'

# We assume your repositories are in /home/git/repositories (default for source installs)
git_data_dirs({ 'default' => { 'path' => '/home/git' } })

# Re-use the PostgreSQL that is already running on your system
postgresql['enable'] = false
# This db_host setting is for Debian PostgreSQL packages
gitlab_rails['db_host'] = '/var/run/postgresql/'
gitlab_rails['db_port'] = 5432
# We assume you called the GitLab DB user 'git'
gitlab_rails['db_username'] = 'git'
EOF
```

Now install the Omnibus GitLab package and reconfigure it:

```shell
sudo gitlab-ctl reconfigure
```

You are not done yet! The `gitlab-ctl reconfigure` run has changed the home
directory of the Git user, so OpenSSH can no longer find its authorized_keys
file. Rebuild the keys file with the following command:

```shell
sudo gitlab-rake gitlab:shell:setup
```

You should now have HTTP and SSH access to your GitLab server with the
repositories and users that were there before.

If you can log into the GitLab web interface, the next step is to reboot your
server to make sure none of the old services interferes with Omnibus GitLab.

If you are using special features such as LDAP you will have to put your
settings in `gitlab.rb`, see the [settings docs](../settings/README.md).

## Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)

Starting with GitLab 12.1, PostgreSQL is the only support database management
system. So, if your non-Omnibus installation is running a GitLab version before
12.1 and is using MySQL, you will have to migrate to PostgreSQL before upgrading
to 12.1.

To convert to PostgreSQL and use the built-in server, follow the steps:

- [Create a backup of the non-Omnibus MySQL installation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#creating-a-backup-of-the-gitlab-system)
- [Export and convert the existing MySQL database in the GitLab backup file](https://docs.gitlab.com/ee/update/mysql_to_postgresql.html)
- [Restore this in the Omnibus installation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-installations)
