# Backups

### Backup and restore omnibus-gitlab configuration

It is recommended to keep a copy of `/etc/gitlab`, or at least of
`/etc/gitlab/gitlab-secrets.json`, in a safe place. If you ever
need to restore a GitLab application backup you need to also restore
`gitlab-secrets.json`. If you do not, GitLab users who are using
two-factor authentication will loose access to your GitLab server
and 'secure variables' stored in GitLab CI will be lost.

It is not recommended to store your configuration backup in the
same place as your application data backup, see below.

All configuration for omnibus-gitlab is stored in `/etc/gitlab`. To backup your
configuration, just backup this directory.

```shell
# Example backup command for /etc/gitlab:
# Create a time-stamped .tar file in the current directory.
# The .tar file will be readable only to root.
sudo sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%s.tar") -C / etc/gitlab'
```

You can extract the .tar file as follows.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf etc-gitlab-1399948539.tar -C /
```

Remember to run `sudo gitlab-ctl reconfigure` after restoring a configuration
backup.

NOTE: Your machines SSH host keys are stored in a separate location at `/etc/ssh/`. Be sure to also [backup and restore those keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

#### Separate configuration backups from application data

Do not store your GitLab application backups (Git repositories, SQL
data) in the same place as your configuration backup (`/etc/gitlab`).
The `gitlab-secrets.json` file (and possibly also the `gitlab.rb`
file) contain database encryption keys to protect sensitive data
in the SQL database:

- GitLab two-factor authentication (2FA) user secrets ('QR codes')
- GitLab CI 'secure variables'

If you keep your configuration backup in a different place from
your application data backup you reduce the chances of exposing the
sensitive data mentioned above in case one of your application
backups is lost/leaked/stolen.

### Creating an application backup

To create a backup of your repositories and GitLab metadata, follow the [backup create documentation](http://doc.gitlab.com/ce/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system).

Backup create will store a tar file in `/var/opt/gitlab/backups`.

Similarly for CI, backup create will store a tar file in `/var/opt/gitlab/ci-backups`.

If you want to store your GitLab backups in a different directory, add the
following setting to `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl
reconfigure`:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

### Restoring an application backup

See [backup restore documentation](http://doc.gitlab.com/ce/raketasks/backup_restore.html#omnibus-installations).

### Backup and restore using non-packaged database

If you are using non-packaged database see [documentation on using non-packaged database](doc/settings/database.md#using-a-non-packaged-postgresql-database-management-server).

### Upload backups to remote (cloud) storage

For details check [backup restore document of GitLab CE](https://gitlab.com/gitlab-org/gitlab-ce/blob/966f68b33e1f15f08e383ec68346ed1bd690b59b/doc/raketasks/backup_restore.md#upload-backups-to-remote-cloud-storage).
