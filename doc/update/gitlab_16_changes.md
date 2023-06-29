---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 16 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

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
