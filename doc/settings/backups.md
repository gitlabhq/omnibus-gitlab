---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Backup
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

## Backup and restore configuration on a Linux package installation

All configuration for Linux package installations is stored in `/etc/gitlab`.
You should keep a copy of your [configuration and certificates](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#data-not-included-in-a-backup)
in a safe place, that's separate from your GitLab application backups.
This reduces the chance that your encrypted application data will be
lost or leaked or stolen together with the keys needed to decrypt it.

In particular, the `gitlab-secrets.json` file (and possibly also the `gitlab.rb`
file) contain database encryption keys to protect sensitive data
in the SQL database:

- [Two-factor authentication](https://docs.gitlab.com/security/two_factor_authentication/) (2FA) user secrets
- [Secure Files](https://docs.gitlab.com/ci/secure_files/)

If those files are lost, 2FA users will lose access to
their [GitLab account](https://docs.gitlab.com/user/profile/)
and 'secure variables' will be lost from CI configurations.

To back up your configuration, run `sudo gitlab-ctl backup-etc`. It creates a tar
archive in `/etc/gitlab/config_backup/`. Directory and backup files will be
readable only to root.

{{< alert type="note" >}}

Running `sudo gitlab-ctl backup-etc --backup-path <DIRECTORY>` will place
the backup in the specified directory. The directory will be created if it
does not exist. Absolute paths are recommended.

{{< /alert >}}

To create a daily application backup, edit the cron table for user root:

```shell
sudo crontab -e -u root
```

The cron table will appear in an editor.

Enter the command to create a tar file containing the contents of
`/etc/gitlab/`. For example, schedule the backup to run every morning after a
weekday, Tuesday (day 2) through Saturday (day 6):

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

{{< alert type="note" >}}

Make sure that `/secret/gitlab/backups/` exists.

{{< /alert >}}

You can extract the tar file as follows.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

Remember to run `sudo gitlab-ctl reconfigure` after restoring a configuration
backup.

{{< alert type="note" >}}

Your machines SSH host keys are stored in a separate location at `/etc/ssh/`. Be sure to also [backup and restore those keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

{{< /alert >}}

### Limit backup lifetime for configuration backups (prune old backups)

GitLab configuration backups can be pruned using the same `backup_keep_time` setting that is
[used for the GitLab application backups](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#limit-backup-lifetime-for-local-files-prune-old-backups)

To make use of this setting, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

The default `backup_keep_time` setting is `0`, which keeps all GitLab configuration and application backups.

After a `backup_keep_time` is set, you can run `sudo gitlab-ctl backup-etc --delete-old-backups` to prune all
backups older than the current time minus the `backup_keep_time`.

You can provide the parameter `--no-delete-old-backups` if you want to keep all existing backups.

{{< alert type="warning" >}}

If no parameter is provided the default is `--delete-old-backups`, which will delete any backups
older than the current time minus the `backup_keep_time`, if `backup_keep_time` is greater than 0.

{{< /alert >}}

## Creating an application backup

To create a backup of your repositories and GitLab metadata, follow the
[backup create documentation](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/).

Backup create will store a tar file in `/var/opt/gitlab/backups`.

If you want to store your GitLab backups in a different directory, add the
following setting to `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl
reconfigure`:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Creating backups for GitLab instances in Docker containers

{{< alert type="warning" >}}

The backup command requires [additional parameters](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)
when your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

{{< /alert >}}

Backups can be scheduled on the host by prepending `docker exec -t <your container name>` to the commands.

Backup application:

```shell
docker exec -t <your container name> gitlab-backup
```

Backup configuration and secrets:

```shell
docker exec -t <your container name> /bin/sh -c 'gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/'
```

{{< alert type="note" >}}

To persist these backups outside the container, mount volumes in the following directories:

{{< /alert >}}

1. `/secret/gitlab/backups`.
1. `/var/opt/gitlab` for [all application data](https://docs.gitlab.com/install/docker/installation/#create-a-directory-for-the-volumes), which includes backups.
1. `/var/opt/gitlab/backups` (optional). The `gitlab-backup` tool writes to this directory [by default](#creating-an-application-backup).
   While this directory is nested inside `/var/opt/gitlab`, [Docker sorts these mounts](https://github.com/moby/moby/pull/8055), allowing them to work in harmony.

   This configuration enables, for example:

   - Application data on regular local storage (through the second mount).
   - A backup volume on network storage (through the third mount).

## Restoring an application backup

See [restore documentation](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/).

## Backup and restore using non-packaged database

If you are using non-packaged database see [documentation on using non-packaged database](database.md#using-a-non-packaged-postgresql-database-management-server).

## Upload backups to remote (cloud) storage

For details check [backup documentation](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage).

## Manually manage backup directory

Linux package installations create the backup directory set with `gitlab_rails['backup_path']`. The directory is owned by the user that is running GitLab and it has strict permissions set to be accessible to only that user.
That directory will hold backup archives and they contain sensitive information.
In some organizations permissions need to be different because of, for example, shipping the backup archives offsite.

To disable backup directory management, in `/etc/gitlab/gitlab.rb` set:

```ruby
gitlab_rails['manage_backup_path'] = false
```

{{< alert type="warning" >}}

If you set this configuration option, it is up to you to create the directory specified in `gitlab_rails['backup_path']` and to set permissions
which will allow user specified in `user['username']` to have correct access. Failing to do so will prevent GitLab from creating the backup archive.

{{< /alert >}}
