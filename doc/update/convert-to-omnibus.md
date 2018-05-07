## Upgrading from a non-Omnibus installation to an Omnibus installation

Upgrading from non-Omnibus installations has not been tested by GitLab.com.

Please be advised that you lose your settings in files such as gitlab.yml, unicorn.rb and smtp_settings.rb.
You will have to [configure those settings in /etc/gitlab/gitlab.rb](../README.md#configuring).

### Upgrading from non-Omnibus PostgreSQL to an Omnibus installation using a backup

Upgrade by [creating a backup from the non-Omnibus install](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#creating-a-backup-of-the-gitlab-system) and [restoring this in the Omnibus installation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md#restore-for-omnibus-installations).
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
git_data_dirs({ 'default' => { 'path' => '/home/git' } })

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
settings in gitlab.rb; see the [omnibus-gitlab README](../settings/README.md).

### Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)

Unlike the previous chapter, the non-Omnibus installation is using MySQL while the Omnibus installation is using PostgreSQL.

Option \#1: Omnibus packages for EE can be configured to use an external [non-packaged MySQL database](../settings/database.md#using-a-mysql-database-management-server-enterprise-edition-only).

Option \#2: Convert to PostgreSQL and use the built-in server as the instructions below.

* [Create a backup of the non-Omnibus MySQL installation](https://docs.gitlab.com/ce/raketasks/backup_restore.html#creating-a-backup-of-the-gitlab-system)
* [Export and convert the existing MySQL database in the GitLab backup file](https://docs.gitlab.com/ee/update/mysql_to_postgresql.html#converting-a-gitlab-backup-file-from-mysql-to-postgres)
* [Restore this in the Omnibus installation](https://docs.gitlab.com/ce/raketasks/backup_restore.html#restore-for-omnibus-installations)
* Enjoy!
