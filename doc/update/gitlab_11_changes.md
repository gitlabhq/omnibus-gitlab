---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab 11 specific changes **(FREE SELF)**

## TLS v1.1 Deprecation

Beginning with GitLab 12.0, TLS v1.1 will be disabled by default to improve security.

This mitigates numerous issues including, but not limited to, Heartbleed and makes
GitLab compliant out of the box with the PCI DSS 3.1 standard.
[Learn more about why TLS v1.1 is being deprecated in our blog.](https://about.gitlab.com/blog/2018/10/15/gitlab-to-deprecate-older-tls/)

## Clients supporting TLS v1.2

- **Git-Credential-Manager** - support since **1.14.0**
- **Git on Red Hat Enterprise Linux 6** - support since **6.8**
- **Git on Red Hat Enterprise Linux 7** - support since **7.2**
- **JGit / Java** - support since **JDK 7**
- **Visual Studio** - support since version **2017**

Modify or add these entries to `gitlab.rb` and run `gitlab-ctl reconfigure` to disable TLS v1.1 immediately:

```ruby
nginx['ssl_protocols'] = "TLSv1.2"
```

## Upgrade prerequisites

For successfully upgrading to GitLab 11.0, users need to satisfy following
requirements:

1. Users should be running latest version in the 10.x series. At the time of
   writing this documentation, it is GitLab 10.8.7.

1. The configurations that were deprecated (list below) in the 10.x series have
   been now removed. Users needs to remove them from `/etc/gitlab/gitlab.rb`. Then run `gitlab-ctl reconfigure` to apply the configuration changes.

If either of the above requirements are not satisfied, upgrade process will
abort without making changes to user's existing installation. This is to ensure
that users does not end up with a broken GitLab due to these unsupported
configurations.

## Removed configurations

The following configurations were deprecated in the 10.x series and have now
been removed:

1. Mattermost related configurations - Support for most of the Mattermost
   related configuration have been removed, except for the essential ones that
   are needed for GitLab-Mattermost integration. [Check out the official documentation for details](https://docs.gitlab.com/ee/integration/mattermost/index.html#upgrading-gitlab-mattermost-from-versions-prior-to-110)

1. Legacy `git_data_dir` configuration, which was used to set location of where
   data was to be stored. It has been now replaced with `git_data_dirs`
   configuration. [Check out the official documentation for details](../settings/configuration.md#storing-git-data-in-an-alternative-directory)

1. Old format of `git_data_dirs` configuration has been replaced with a new
   format, allowing much more fine grain control. [Check out the official documentation for details](../settings/configuration.md#storing-git-data-in-an-alternative-directory)

## Changes introduced in minor versions

### 11.2

Rack Attack is disabled by default. To continue using Rack Attack, you must [enable it manually](https://docs.gitlab.com/ee/security/rack_attack.html#settings).

### 11.3

1. A [security patch](https://about.gitlab.com/releases/2018/11/28/security-release-gitlab-11-dot-5-dot-1-released/#improper-enforcement-of-token-scope)
   removed the ability to get files from a repository by passing
   a `private_token` URL parameter.
   Instead, a redirect to `/users/sign_in` is now served.
   Update any CI scripts, custom automations, etc. to use the
   [repository files API](https://docs.gitlab.com/ee/api/repository_files.html#get-raw-file-from-repository).

### 11.4

1. Version of bundled Redis has been upgraded to 3.2.12. This is a critical
   security update that fixes multiple vulnerabilities. After upgrading to 11.4,
   run `gitlab-ctl restart redis` to ensure the new version is loaded.

1. The [bundled version of Prometheus](https://docs.gitlab.com/ee/administration/monitoring/prometheus/index.html)
   has been upgraded to 2.4.2 and fresh installations will use it by default.
   Version 2 of Prometheus uses a data format incompatible with version 1.

   For users looking for preserving the Prometheus version 1 data, a command
   line tool is provided to upgrade their Prometheus service and migrate data to
   the format supported by new Prometheus version. This tool can be invoked
   using the following command:

   ```shell
   sudo gitlab-ctl prometheus-upgrade
   ```

   This tool will convert existing data to a format supported by the latest
   Prometheus version. Depending on the volume of data, this process can take
   hours. If users do not want to migrate the data, but start with a clean
   database, they can pass `--skip-data-migration` flag to the above command.

   NOTE:
   Prometheus service will be stopped during the migration process.

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
   during reconfigure. With GitLab 12.0 Prometheus will be upgraded to 2.x automatically,
   Prometheus 1.0 data will not be migrated.
1. A [security patch](https://about.gitlab.com/releases/2018/11/28/security-release-gitlab-11-dot-5-dot-1-released/#improper-enforcement-of-token-scope)
   removed the ability to get files from a repository by passing
   a `private_token` URL parameter.
   Instead, a redirect to `/users/sign_in` is now served.
   Update any CI scripts, custom automations, etc. to use the
   [repository files API](https://docs.gitlab.com/ee/api/repository_files.html#get-raw-file-from-repository).

### 11.5

1. A [security patch](https://about.gitlab.com/releases/2018/11/28/security-release-gitlab-11-dot-5-dot-1-released/#improper-enforcement-of-token-scope)
   removed the ability to get files from a repository by passing
   a `private_token` URL parameter.
   Instead, a redirect to `/users/sign_in` is now served.
   Update any CI scripts, custom automations, etc. to use the
   [repository files API](https://docs.gitlab.com/ee/api/repository_files.html#get-raw-file-from-repository).

### 11.6

1. [Sidekiq probe of GitLab Monitor](https://docs.gitlab.com/ee/administration/monitoring/prometheus/gitlab_exporter.html)
   will be disabled by default if GitLab is configured in [Redis for scaling](https://docs.gitlab.com/ee/administration/redis/index.html).
   To manually enable it, users can set `gitlab_monitor['probe_sidekiq'] = true`
   in `/etc/gitlab/gitlab.rb` file. However, when manually enabling it in Redis
   HA mode, users are expected to point the probe to a Redis instance connected
   to the instance using the `gitlab_rails['redis_*']` settings.

   A valid example configuration is:

   ```ruby
   gitlab_monitor['probe_sidekiq'] = true
   gitlab_rails['redis_host'] = <IP of Redis master node>
   gitlab_rails['redis_port'] = <Port where Redis runs in master node>
   gitlab_rails['redis_password'] = <Password to connect to Redis master>
   ```

   NOTE:
   In the above configuration, when a failover happens after the
   master node fails, GitLab Monitor will still be probing the original master
   node, since it is specified in `gitlab.rb`. Users will have to manually update
   `gitlab.rb` to point it to the new master node.

1. Ruby has been updated to 2.5.3. GitLab will be down during the upgrade until
   the Unicorn processes have been restarted. The restart is done automatically
   at the end of `gitlab-ctl reconfigure`, which is run by default on upgrade.

   NOTE:
   The application will throw 500 http errors until the Unicorn restart is completed.

### 11.8

1. The [runit](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/runit) cookbook was updated to be closer to the latest version of the upstream [runit cookbook](https://github.com/chef-cookbooks/runit). No user changes are necessary for this release.
