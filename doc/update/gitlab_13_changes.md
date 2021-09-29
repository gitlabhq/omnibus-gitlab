---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab 13 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 13.0

### Puma becoming default web server instead of Unicorn

Starting with GitLab 13.0, Puma will be the default web server used in
`omnibus-gitlab` based installations. This will be the case for both fresh
installations as well as upgrades, unless users have explicitly disabled Puma
and enabled Unicorn. Users who have Unicorn configuration are recommended to
refer to [the docs on how to convert them to Puma ones](https://docs.gitlab.com/ee/administration/operations/puma.html#convert-unicorn-settings-to-puma).

### PostgreSQL 11 becoming minimum required version

To upgrade to GitLab 13.0 or later, users must be already running PostgreSQL 11.
PostgreSQL 9.6 and 10 [have been removed from](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4186)
the package. Follow [the documentation](../settings/database.md#upgrade-packaged-postgresql-server)
on how to upgrade the packaged PostgreSQL server to required version.

### Alertmanager moved from the `gitlab` namespace to `monitoring`

In `/etc/gitlab/gitlab.rb`, change:

```ruby
alertmanager['flags'] = {
  'cluster.advertise-address' => "127.0.0.1:9093",
  'web.listen-address' => "#{node['gitlab']['alertmanager']['listen_address']}",
  'storage.path' => "#{node['gitlab']['alertmanager']['home']}/data",
  'config.file' => "#{node['gitlab']['alertmanager']['home']}/alertmanager.yml"
}
```

to:

```ruby
alertmanager['flags'] = {
  'cluster.advertise-address' => "127.0.0.1:9093",
  'web.listen-address' => "#{node['monitoring']['alertmanager']['listen_address']}",
  'storage.path' => "#{node['monitoring']['alertmanager']['home']}/data",
  'config.file' => "#{node['monitoring']['alertmanager']['home']}/alertmanager.yml"
}
```

## 13.3

### PostgreSQL 12.3 support

PostgreSQL 12.3 is being shipped with the package in addition to 11.7 which is still the default version.
Both fresh installs and upgrades will still continue to use 11.7, but users can manually upgrade to 12.3 following the
[upgrade docs](../settings/database.md#upgrade-packaged-postgresql-server). Note that PostgreSQL 12 is not supported
for Geo deployments in GitLab 13.3 and is planned for the 13.4 release.

## 13.5

### Default workhorse listen socket moved

The path for the Workhorse socket changed from `/var/opt/gitlab/workhorse/socket` to `/var/opt/gitlab/workhorse/sockets/socket` in 13.5. This change will automatically get applied and Workhorse will be restarted during an upgrade, unless you have set your system to skip `reconfigure` (`/etc/gitlab/skip-auto-reconfigure`).

If you use SELinux and have set `gitlab_workhorse['listen_addr']` to a custom socket path, some manual steps are required. If you want Omnibus to manage SELinux Contexts, set `gitlab_workhorse['sockets_directory'] = "/var/opt/my_workhorse_socket_home"` and run `gitlab-ctl reconfigure`. Alternatively, if you want to manage the SELinux Context yourself, run `semanage fcontext -a -t gitlab_shell_t '/var/opt/my_workhorse_socket_home'` and then `restorecon -v '/var/opt/my_workhorse_socket_home'`. Note that if you are managing the SELinux Context yourself, you will need to repeat these steps if you move the directory.

If you are using a custom listen address but you are not using SELinux, you will not be affected by this change.

If you are using your own NGINX rather than the bundled version, and are proxying to the workhorse socket, you will need to update your NGINX config.

## 13.7

### CentOS/RHEL 6 packages no longer provided

With these operating systems reaching their end-of-life for support, we are no longer providing packages for them. See the [supported operating systems](https://docs.gitlab.com/ee/administration/package_information/deprecated_os.html) page for details.

This change also impacts [the packages available for Amazon Linux 2](https://docs.gitlab.com/ee/update/package/#gitlab-137-and-later-unavailable-on-amazon-linux-2).

### PostgreSQL 12.4 support

PostgreSQL 12.4 is being shipped as the default version for fresh installs.

Users can manually upgrade to 12.4 following the  [upgrade docs](../settings/database.md#gitlab-133-and-later).

### New encrypted_settings_key_base secret added to the GitLab secrets

In 13.7, a new secret is generated in `/etc/gitlab/gitlab-secrets.json`. In an HA GitLab environment, secrets need to
be the same on all nodes. Ensure this new secret is also accounted for if you are manually syncing the file across
nodes, or manually specifying secrets in `/etc/gitlab/gitlab.rb`.

## 13.8

### PostgreSQL 12.4 upgrades

PostgreSQL will automatically be upgraded to 12.x except for the following cases:

- you are running the database in high_availability using Repmgr or Patroni.
- your database nodes are part of GitLab Geo configuration.
- you have specifically opted out using the `/etc/gitlab/disable-postgresql-upgrade` file outlined below.

To opt out you must execute the following before performing the upgrade of GitLab.

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

<!-- disabling this rule because it fails on gitlab-exporter -->
<!-- markdownlint-disable MD044 -->
### Removal of process metrics from gitlab-exporter

Process-related metrics emitted from gitlab-exporter have been retired. These metrics are now exported
from application processes directly.
Similarly, process metrics for particular git processes such as `git upload-pack`,
`git fetch`, `git cat-file`, `git gc` emitted from gitlab-exporter have been removed.
Git-related process metrics are already being exported by Gitaly.
No further action is required, unless an installation is purely
ingesting metrics from gitlab-exporter, which is not the default behavior. In that case,
[change your scrape configuration](https://docs.gitlab.com/ee/administration/monitoring/prometheus/#adding-custom-scrape-configurations)
to ingest metrics from the [application's own metrics endpoints](https://docs.gitlab.com/ee/administration/monitoring/prometheus/gitlab_metrics.html)
instead.
<!-- markdownlint-enable MD044 -->

## 13.9

### Redis 6.0.10

In 13.9, we are upgrading Redis from 5.0.9 to 6.0.10. This upgrade is expected
to be fully backwards compatible.

One of the new features it introduces, is threaded I/O. That can be enabled by
setting the following values:

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

If your instance has Redis HA with Sentinel, follow the upgrade steps documented in
[Update GitLab installed with the Omnibus GitLab package](https://docs.gitlab.com/ee/update/zero_downtime.md#use-redis-ha-using-sentinel)
