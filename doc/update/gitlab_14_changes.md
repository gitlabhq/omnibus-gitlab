---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 14 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 14.10

### Gitaly runtime directory

In 14.10, Gitaly has introduced a new runtime directory. This directory is
intended to hold all files and directories Gitaly needs to create at runtime in
order to operate correctly. This includes for example internal sockets, the Git
execution environment or the temporary hooks directory.

This new configuration can be set via `gitaly['runtime_dir']`. It replaces the
the old `gitaly['internal_socket_dir']` configuration: if the internal socket
directory is not explicitly configured, sockets will be created in the runtime
directory.

Support for `gitaly['internal_socket_dir']` will be removed in 15.0.

## 14.7

### Redis 6.2.6

In 14.8, we are upgrading Redis from 6.0.16 to 6.2.6. This upgrade is expected
to be fully backwards compatible.

If your instance has Redis HA with Sentinel, follow the upgrade steps documented in
[Update GitLab installed with the Omnibus GitLab package](https://docs.gitlab.com/ee/update/zero_downtime.html#use-redis-ha-using-sentinel)

## 14.4

### Downgrading Grafana from 8.1 to 7.5

In GitLab 14.4 the provided Grafana version is 7.5, this is a downgrade from
the Grafana 8.1 version introduced in GitLab 14.3. This was reverted to an
Apache-licensed Grafana release to allow time to consider the implications of
the newer AGPL-licensed releases.

Users that have customized their Grafana install with plugins or library
panels may experience errors in Grafana after the downgrade. If the errors
persist after a Grafana restart you may need to reset the Grafana db and
re-add the customizations. The Grafana database can be reset with
`sudo gitlab-ctl reset-grafana`.

## 14.0

### Removing support for running Sidekiq directly instead of `sidekiq-cluster`

In GitLab 13.0, `sidekiq-cluster` was enabled by default and the `sidekiq`
service ran `sidekiq-cluster` under the hood. However, users could control this
behavior using `sidekiq['cluster']` setting to run Sidekiq directly instead.
Users could also run `sidekiq-cluster` separately using the various
`sidekiq_cluster[*]` settings available in `gitlab.rb`. However these features
were deprecated and are now being removed.

Starting with GitLab 14.0, `sidekiq-cluster` becomes the only way to run Sidekiq
in `omnibus-gitlab` installations. As part of this process, support for the
following settings in `gitlab.rb` is being removed:

1. `sidekiq['cluster']` setting. Sidekiq can only be run using `sidekiq-cluster`
   now.

1. `sidekiq_cluster[*]` settings. They should be set via respective `sidekiq[*]`
   counterparts.

1. `sidekiq['concurrency']` setting. The limits should be controlled using the
   two settings `sidekiq['min_concurrency']` and `sidekiq['max_concurrency']`.

### Removing support for using Unicorn as web server

In GitLab 13.0, Puma became the default web server for GitLab, but users were
still able to continue using Unicorn if needed. Starting with GitLab 14.0,
Unicorn is no longer supported as a webserver for GitLab and is no longer
shipped with the `omnibus-gitlab` packages. Users must migrate to Puma following
[documentation](https://docs.gitlab.com/ee/administration/operations/puma.html)
to upgrade to GitLab 14.0.

### Consul upgrade

The Consul version has been updated from `1.6.10` to `1.9.6` for Geo and multi-node PostgreSQL installs. Its important
that Consul nodes be upgraded and restarted one at a time.

See our [Consul upgrade instructions](https://docs.gitlab.com/ee/administration/consul.html#upgrade-the-consul-nodes).

### Automatically generating an initial root password

Starting with GitLab 14.0, GitLab automatically generates a password for initial
administrator user (`root`) and stores this value to
`/etc/gitlab/initial_root_password`. For details, see the
[documentation on initial login](../installation/index.md#set-up-the-initial-password).

### PostgreSQL 11 and repmgr removal

The binaries for PostgreSQL 11 and repmgr have been removed.

Prior to upgrading, administrators using Omnibus GitLab must:

1. Ensure the installation is using [PostgreSQL 12](../settings/database.md#upgrade-packaged-postgresql-server)
1. If using repmgr, [convert to using patroni](https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#switching-from-repmgr-to-patroni)

### Redis configuration changes

Two configuration options for Redis were deprecated in GitLab 13 and removed in GitLab 14:

- `redis_slave_role` is replaced with `redis_replica_role`
- `redis['client_output_buffer_limit_slave']` is replaced with `redis['client_output_buffer_limit_replica']`

Redis Cache nodes being upgraded from GitLab 13.12 to 14.0 that still refer to `redis_slave_role`
in `gitlab.rb` will encounter an error in the output of `gitlab-ctl reconfigure`:

```plaintext
There was an error running gitlab-ctl reconfigure:

The following invalid roles have been set in 'roles': redis_slave_role
```
