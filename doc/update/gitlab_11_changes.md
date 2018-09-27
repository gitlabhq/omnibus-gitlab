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
