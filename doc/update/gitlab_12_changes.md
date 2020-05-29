# GitLab 12 specific changes

NOTE: **Note**
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

## Prometheus 1.x Removal

Prometheus 1.x was deprecated in GitLab 11.4, and
Prometheus 2.8.1 was installed by default on new installations. Users updating
from older versions of GitLab could manually upgrade Prometheus data using the
[`gitlab-ctl prometheus-upgrade`](gitlab_11_changes.md#114)
command provided. You can view current Prometheus version in use from the
instances Prometheus `/status` page.

With GitLab 12.0, support for Prometheus 1.x is completely removed, and as part
of the upgrade process, Prometheus binaries will be updated to version 2.8.1.
Existing data from Prometheus 1.x installation WILL NOT be migrated as part of
this automatic upgrade, and users who wish to retain that data should
[manually upgrade Prometheus version](gitlab_11_changes.md#114)
before upgrading to GitLab 12.0

For users who use `/etc/gitlab/skip-auto-reconfigure` file to skip automatic
migrations and reconfigures during upgrade, Prometheus upgrade will also be
skipped. However, since the package no longer contains Prometheus 1.x binary,
the Prometheus service will be non-functional due to the mismatch between binary
version and data directory. Users will have to manually run `sudo gitlab-ctl
prometheus-upgrade` command to get Prometheus running again.

Please note that `gitlab-ctl prometheus-upgrade` command automatically
reconfigures your GitLab instance, and will cause database migrations to run.
So, if you are on an HA instance, run this command only as the last step, after
performing all database related actions.

## Removal of support for `/etc/gitlab/skip-auto-migrations` file

Before GitLab 10.6, the file `/etc/gitlab/skip-auto-migrations` was used to
prevent automatic reconfigure (and thus automatic database migrations) as part
of upgrade. This file had been deprecated in favor of `/etc/gitlab/skip-auto-reconfigure`
since GitLab 10.6, and in 12.0 the support is removed completely. Upgrade
process will no longer take `skip-auto-migrations` file into consideration.

## Deprecation of TLS v1.1

With the release of GitLab 12, TLS v1.1 has been fully deprecated.
This mitigates numerous issues including, but not limited to,
Heartbleed and makes GitLab compliant out of the box with the PCI
DSS 3.1 standard.

[Learn more about why TLS v1.1 is being deprecated in our blog.](https://about.gitlab.com/blog/2018/10/15/gitlab-to-deprecate-older-tls/)

## Upgrade to PostgreSQL 10

CAUTION: **Caution:**
If you are running a Geo installation using PostgreSQL 9.6.x, please upgrade to GitLab 12.4 or newer. Older versions were affected [by an issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4692) that could cause automatic upgrades of the PostgreSQL database to fail on the secondary. This issue is now fixed.

PostgreSQL will automatically be upgraded to 10.x unless specifically opted
out during the upgrade. To opt out you must execute the following before
performing the upgrade of GitLab.

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Further details and procedures for upgrading a GitLab HA cluster can be
found in the [Database Settings notes](../settings/database.md#upgrade-packaged-postgresql-server).

### 12.1

#### Monitoring related node attributes moved to be under `monitoring` key

If you were using monitoring related node attributes like
`node['gitlab']['prometheus']` or `node['gitlab']['alertmanager']` in your
`gitlab.rb` file for configuring other settings, they are now under `monitoring`
key and should be renamed. The replacements are as follows

```plaintext
# Existing usage in gitlab.rb => Replacement

* node['gitlab']['prometheus'] => node['monitoring']['prometheus']
* node['gitlab']['alertmanager'] => node['monitoring']['alertmanager']
* node['gitlab']['redis-exporter'] => node['monitoring']['redis-exporter']
* node['gitlab']['node-exporter'] => node['monitoring']['node-exporter']
* node['gitlab']['postgres-exporter'] => node['monitoring']['postgres-exporter']
* node['gitlab']['gitlab-monitor'] => node['monitoring']['gitlab-monitor']
* node['gitlab']['grafana'] => node['monitoring']['grafana']
```

Also, it is recommended to use the actual values in `gitlab.rb` instead of
referring node values to avoid breakage when these attributes are moved in the
backend.

### 12.2

The default formula for calculating the number of Unicorn worker processes has been updated to increase the number of workers by 50% per CPU. This will increase the CPU and memory utilization slightly. This has been done to improve performance by reducing the amount of request queuing.

### 12.3

To prevent confusion with the broader GitLab Monitor feature set, the GitLab Monitor
tool has been renamed to GitLab Exporter. As a result, usage of `gitlab_monitor[*]`
keys in `gitlab.rb` file has been deprecated in favor of `gitlab_exporter[*]` ones.

The deprecated settings will be removed in GitLab 13.0. They will continue to
work till then, but warnings will be displayed at the end of reconfigure run.
Since upgrades to 13.0 will be prevented if removed settings are found in `gitlab.rb`,
users who are currently using those settings are advised to switch to `gitlab_exporter[*]`
ones at the earliest.

### 12.7

The Redis version packaged with Omnibus GitLab has been updated to Redis 5.0.7.
You will need to restart Redis after the upgrade so that the new version will be
active. To restart Redis, run `sudo gitlab-ctl restart redis`. If your instance
has Redis HA with Sentinel, follow the upgrade steps documented in [Updating GitLab installed with the Omnibus GitLab package](README.md#using-redis-ha-using-sentinel)
to avoid downtime.

Unicorn memory limits should also be adjusted to the following values:

```ruby
unicorn['worker_memory_limit_min'] = "1024 * 1 << 20"
unicorn['worker_memory_limit_max'] = "1280 * 1 << 20"
```

See our documentation on [unicorn-worker-killer](https://docs.gitlab.com/ee/administration/operations/unicorn.html#unicorn-worker-killer) for more information.

### 12.8

PostgreSQL 11.7 is being shipped with the package in addition to 10.12 and 9.6.17.
Both fresh installs and upgrades will still continue to use 10.12, but users can
manually upgrade to 11.7 following the [upgrade docs](../settings/database.md#upgrade-packaged-postgresql-server).

### 12.9

[Puma](https://github.com/puma/puma) is now available as an alternative web server to Unicorn.
If you are migrating from Unicorn, refer to [converting Unicorn settings to Puma](../settings/puma.md#converting-unicorn-settings-to-puma)
to make sure your web server settings carry over correctly.

### 12.10

NOTE: **NOTE:**
PostgreSQL 9.6 and PostgreSQL 10 will be removed from the Omnibus package in the next release: GitLab 13.0. The minimum
supported PostgreSQL version will be 11. In order to upgrade to GitLab 13.0, you will need to be upgrading from 12.10, and
already using a PostgreSQL 11 database.

PostgreSQL will automatically be upgraded to 11.x except for the following cases:

- you are running the database in high_availability using repmgr.
- your database nodes are part of GitLab Geo configuration.
- you have specifically opted out using the `/etc/gitlab/disable-postgresql-upgrade` file outlined below.

To opt out you must execute the following before performing the upgrade of GitLab.

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Further details and procedures for upgrading PostgreSQL after install if not completed automatically can be
found in the [Database Settings notes](../settings/database.md#upgrade-packaged-postgresql-server).
