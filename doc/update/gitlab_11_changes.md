# GitLab 11 specific changes

## Upgrade prerequisites
For successfully upgrading to GitLab 11.0, users need to satisfy following
requirements
1. Users should be running latest version in the 10.x series. At the time of
   writing this documentation, it is GitLab 10.8.5.
2. The configurations that were deprecated (list below) in the 10.x series have
   been now removed. Users needs to remove them from `/etc/gitlab/gitlab.rb`.

If either of the above requirements are not satisfied, upgrade process will
abort without making changes to user's existing installation. This is to ensure
that users does not end up with a broken Gitlab due to these unsupported
configurations.

## Removed configurations
The following configurations were deprecated in the 10.x series and have now
been removed.
1. Mattermost related configurations - Support for most of the Mattermost
   related configuration have been removed, except for the essential ones that
   are needed for GitLab-Mattermost integration. [Check out the official documentation for details](https://docs.gitlab.com/omnibus/gitlab-mattermost/#upgrading-gitlab-mattermost-from-versions-prior-to-11-0)
2. Legacy `git_data_dir` configuration, which was used to set location of where
   data was to be stored. It has been now replaced with `git_data_dirs`
   configuration. [Check out the official documentation for details](https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory)
3. Old format of `git_data_dirs` configuration has been replaced with a new
   format, allowing much more fine grain control. [Check out the official documentation for details](https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory)

## Changes introduced in minor versions

### 11.4

1. Version of bundled Redis has been upgraded to 3.2.12. This is a critical
   security update that fixes multiple vulnerabilities. After upgrading to 11.4,
   run `gitlab-ctl restart redis` to ensure the new version is loaded.

1. The bundled version of Prometheus has been upgraded to 2.4.2 and fresh
   installations will use it by default. Version 2 of Prometheus uses a data
   format incompatible with version 1.

   For users looking for preserving the Prometheus version 1 data, a command
   line tool is provided to upgrade their Prometheus service and migrate data to
   the format supported by new Prometheus version.  This tool can be invoked
   using the following command

     ```bash
     sudo gitlab-ctl prometheus-upgrade
     ```

   This tool will convert existing data to a format supported by the latest
   Prometheus version. Depending on the volume of data, this process can take
   hours.  If users do not want to migrate the data, but start with a clean
   database, they can pass `--skip-data-migration` flag to the above command.

   **`Note`**: Prometheus service will be stopped during the migration process.

   To know about other supported options, pass `--help` flag to the above
   command.

   This tool **will not** be automatically invoked during package upgrades.
   Users will have to run it manually to migrate to latest version of
   Prometheus, and are advised to do it as soon as possible. Therefore, existing
   users who are upgrading to 11.4 will continue to use Prometheus 1.x until
   they manually migrate to the 2.x version.

   Support for Prometheus 1.x versions that were shipped with earlier versions
   of GitLab has been deprecated and will be removed completely in GitLab 12.0.
   Users still using those versions will be presented with a deprecation warning
   during reconfigure. With GitLab 12.0, upgrades will be aborted if Prometheus
   1.x is detected and users will not be able to upgrade without migrating to
   Prometheus 2.x first.
