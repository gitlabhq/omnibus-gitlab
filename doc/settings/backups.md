# Backups

## Backup and restore Omnibus GitLab configuration

It is recommended to keep a copy of `/etc/gitlab`, or at least of
`/etc/gitlab/gitlab-secrets.json`, in a safe place. If you ever
need to restore a GitLab application backup you need to also restore
`gitlab-secrets.json`. If you do not, GitLab users who are using
two-factor authentication will lose access to your GitLab server
and 'secure variables' stored in GitLab CI will be lost.

It is not recommended to store your configuration backup in the
same place as your application data backup, see below.

All configuration for Omnibus GitLab is stored in `/etc/gitlab`. To backup your
configuration, just run `sudo gitlab-ctl backup-etc`. It will create a tar
archive in `/etc/gitlab/config_backup/`. Directory and backup files will be
readable only to root.

NOTE: **Note**: Running `sudo gitlab-ctl backup-etc <DIRECTORY>` will place
the backup in the specified directory. The directory will be created if it
does not exist. Absolute paths are recommended.

NOTE: **Note:** `backup-etc` introduced in GitLab 12.3.

To create a daily application backup, edit the cron table for user root:

```shell
sudo crontab -e -u root
```

The cron table will appear in an editor.

Enter the command to create a compressed tar file containing the contents of
`/etc/gitlab/`. For example, schedule the backup to run every morning after a
weekday, Tuesday (day 2) through Saturday (day 6):

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

[cron is rather particular](http://www.pantz.org/software/cron/croninfo.html)
about the cron table. Note:

- The empty line after the command
- The escaped percent character:  \%

You can extract the .tar file as follows.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

Remember to run `sudo gitlab-ctl reconfigure` after restoring a configuration
backup.

NOTE: Your machines SSH host keys are stored in a separate location at `/etc/ssh/`. Be sure to also [backup and restore those keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

### Separate configuration backups from application data

Do not store your GitLab application backups (Git repositories, SQL
data) in the same place as your configuration backup (`/etc/gitlab`).
The `gitlab-secrets.json` file (and possibly also the `gitlab.rb`
file) contain database encryption keys to protect sensitive data
in the SQL database:

- GitLab two-factor authentication (2FA) user secrets ('QR codes')
- GitLab CI 'secure variables'

If you separate your configuration backup from your application data backup,
you reduce the chance that your encrypted application data will be
lost/leaked/stolen together with the keys needed to decrypt it.

## Creating an application backup

To create a backup of your repositories and GitLab metadata, follow the
[backup create documentation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#creating-a-backup-of-the-gitlab-system).

Backup create will store a tar file in `/var/opt/gitlab/backups`.

If you want to store your GitLab backups in a different directory, add the
following setting to `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl
reconfigure`:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Creating backups for GitLab instances in Docker containers

Backups can be scheduled on the host by prepending `docker exec -t <your container name>` to the commands.

Backup application:

```shell
docker exec -t <your container name> gitlab-backup
```

Backup configuration and secrets:

```shell
docker exec -t <your container name> /bin/sh -c 'umask 0077; tar cfz /secret/gitlab/backups/$(date "+etc-gitlab-\%s.tgz") -C / etc/gitlab'
```

>**Note:**
You need to have volumes mounted at `/secret/gitlab/backups` and `/var/opt/gitlab`
in order to have these backups persisted outside the container.

## Restoring an application backup

See [backup restore documentation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-installations).

## Backup and restore using non-packaged database

If you are using non-packaged database see [documentation on using non-packaged database](database.md#using-a-non-packaged-postgresql-database-management-server).

## Upload backups to remote (cloud) storage

For details check [backup restore document of GitLab CE](https://docs.gitlab.com/ee/raketasks/backup_restore.html#uploading-backups-to-a-remote-cloud-storage).

## Manually manage backup directory

Omnibus GitLab creates the backup directory set with `gitlab_rails['backup_path']`. The directory is owned by the user that is running GitLab and it has strict permissions set to be accessible to only that user.
That directory will hold backup archives and they contain sensitive information.
In some organizations permissions need to be different because of, for example, shipping the backup archives offsite.

To disable backup directory management, in `/etc/gitlab/gitlab.rb` set:

```ruby
gitlab_rails['manage_backup_path'] = false
```

*Warning* If you set this configuration option, it is up to you to create the directory specified in `gitlab_rails['backup_path']` and to set permissions
which will allow user specified in `user['username']` to have correct access. Failing to do so will prevent GitLab from creating the backup archive.
