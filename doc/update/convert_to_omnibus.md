---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Convert a self-compiled installation to a Linux package installation

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

If you installed GitLab by using the self-compiled installation method, you can convert your instance to a Linux
package instance.

When converting a self-compiled installation:

- You must convert to the exact same version of GitLab.
- You must [configure settings in `/etc/gitlab/gitlab.rb`](../index.md#configuring) because settings in files such as
  `gitlab.yml`, `puma.rb` and `smtp_settings.rb` are lost.

WARNING:
Converting from self-compiled installations has not been tested by GitLab.

To convert your self-compiled installation to a Linux package installation:

1. Create a backup from your current self-compiled installation:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
   ```

1. [Install GitLab using a Linux package](https://about.gitlab.com/install/).
1. Copy the backup file to the directory `/var/opt/gitlab/backups/` of the new server.
1. Restore the backup in the new installation ([detailed instructions](https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html#restore-for-linux-package-installations)):

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=<FILE_NAME>
   ```

   The restore takes a few minutes depending on the size of your database and Git data.

1. Because all settings are stored in `/etc/gitlab/gitlab.rb` in Linux package installations, you must reconfigure
   the new installation . Individual settings must be manually moved from self-compiled installation files such as
   `gitlab.yml`, `puma.rb`, and `smtp_settings.rb`. For all available options, see the
   [`gitlab.rb` template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
1. Copy the secrets from the old self-compiled installation to the new Linux package installation:
   1. Restore secrets related to Rails. Copy the values of `db_key_base`, `secret_key_base` and `otp_key_base` from
      `/home/git/gitlab/config/secrets.yml` (self-compiled installation) to the equivalent
      ones in `/etc/gitlab/gitlab-secrets.json` (Linux package installation).
   1. Copy the contents of `/home/git/gitlab-shell/.gitlab_shell_secret` (self-compiled installation) to `secret_token`
      in `/etc/gitlab/gitlab-secrets.json` (Linux package installation). It looks something like:

       ```json
       {
         "gitlab_workhorse": {
           "secret_token": "..."
         },
         "gitlab_shell": {
           "secret_token": "..."
         },
         "gitlab_rails": {
           "secret_key_base": "...",
           "db_key_base": "...",
           "otp_key_base": "...",
         }
         ...
       }
       ```

1. Reconfigure GitLab to apply the changes:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. If you migrated `/home/git/gitlab-shell/.gitlab_shell_secret`, you [must restart Gitaly](https://gitlab.com/gitlab-org/gitaly/-/issues/3837):

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

## Convert an external PostgreSQL to a Linux package installation by using a backup

You can convert an [external PostgreSQL installation](https://docs.gitlab.com/ee/administration/postgresql/external.html)
to a Linux package PostgreSQL installation by using a backup. You must use the same GitLab version when you do this.

To convert an external PostgreSQL installation to a Linux package PostgreSQL installation by using a backup:

1. [Create a backup from the non-Linux package installation](https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html)
1. [Restoring the backup in the Linux package installation](https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html#restore-for-linux-package-installations).
1. Run the `check` task:

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. If you receive an error similar to `No such file or directory @ realpath_rec - /home/git`, run:

   ```shell
   find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
   ```

This assumes that `gitlab-shell` is located in `/home/git`.

## Convert an external PostgreSQL to a Linux package installation in-place

You can convert an [external PostgreSQL installation](https://docs.gitlab.com/ee/administration/postgresql/external.html)
to a Linux package PostgreSQL installation in-place.

These instructions assume:

- You are using PostgreSQL on Ubuntu.
- You have an Linux package matching your current GitLab version.
- Your self-compiled installation of GitLab uses all the default paths and users.
- The existing home directory of the Git user (`/home/git`) will be changed to `/var/opt/gitlab`.

To convert an external PostgreSQL installation to a Linux package PostgreSQL installation in-place:

1. Stop and disable GitLab, Redis, and NGINX:

   ```shell
   # Ubuntu
   sudo service gitlab stop
   sudo update-rc.d gitlab disable

   sudo service nginx stop
   sudo update-rc.d nginx disable

   sudo service redis-server stop
   sudo update-rc.d redis-server disable
   ```

1. If you are using a configuration management system to manage GitLab on your server, disable GitLab and its
   related services there.
1. Create a `gitlab.rb` file for your new setup:

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

1. Now install the Linux package and reconfigure the installation:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Because the `gitlab-ctl reconfigure` run has changed the home directory of the Git user and OpenSSH can no longer
   find its `authorized_keys` file, rebuild the keys file:

   ```shell
   sudo gitlab-rake gitlab:shell:setup
   ```

   You should now have HTTP and SSH access to your GitLab server with the repositories and users that were there before.

1. If you can log into the GitLab web interface, reboot your server to make sure none of the old services interfere with
   the Linux package installation.
1. If you are using special features such as LDAP, you must put your settings in `gitlab.rb`. For more information,
   see the [settings documentation](../settings/index.md).
