---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 16 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 16.2

### Redis 7.0.12

In 16.2, we are upgrading Redis from 6.2.11 to 7.0.12. This upgrade is expected
to be fully backwards compatible.

Redis will not be automatically restarted as part of `gitlab-ctl reconfigure`.
Hence, users are manually required to run `sudo gitlab-ctl restart redis` after
the reconfigure run so that the new Redis version gets used. A warning
mentioning that the installed Redis version is different than the one running is
displayed at the end of reconfigure run until the restart is performed.

If your instance has Redis HA with Sentinel, follow the upgrade steps mentioned in
[Zero Downtime documentation](https://docs.gitlab.com/ee/update/zero_downtime.html#redis-ha-using-sentinel).

## 16.0

### PostgreSQL 12 removal

The binaries for PostgreSQL 12 have been removed.

Prior to upgrading, administrators using Omnibus GitLab must:

1. Ensure the installation is using [PostgreSQL 13](../settings/database.md#upgrade-packaged-postgresql-server)

### Deprecating bundled Grafana

Bundled Grafana is deprecated and is no longer supported. It will be removed in GitLab 16.3.

For more information, see [deprecation notes](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#deprecation-of-bundled-grafana).

### Upgrade GitLab Docker image to use Ubuntu 22.04 as base

This upgrades `openssh-server` to `1:8.9p1-3`.

Using `ssh-keyscan -t rsa` with older OpenSSH clients to obtain public key information will no longer
be viable due to deprecations listed in [OpenSSH 8.7 Release Notes](https://www.openssh.com/txt/release-8.7).  

Workaround is to make use of a different key type, or upgrade the client OpenSSH to a version >= 8.7
