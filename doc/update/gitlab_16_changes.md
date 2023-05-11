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
