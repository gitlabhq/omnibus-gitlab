---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# PostgreSQL versions shipped with Omnibus GitLab

NOTE: **Note:**
This table lists only GitLab versions where a significant change happened in the
package regarding PostgreSQL versions, not all.

Read more about update policies and warnings in the PostgreSQL
[upgrade docs](../settings/database.md#upgrade-packaged-postgresql-server).

| GitLab version | PostgreSQL versions | Default version for fresh installs | Default version for upgrades | Notes |
| -------------- | --------------------- | ---------------------------------- | ---------------------------- | ----- |
| 13.6 | 11.9, 12.4 | 12.4 | 11.9 | For upgrades users can manually upgrade to 12.4 following the [upgrade docs](../settings/database.md#gitlab-133-and-later). |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.0 | 11.7 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 12.10 | 9.6.17, 10.12, and 11.7 | 11.7 | 11.7 | Package upgrades automatically performed PostgreSQL upgrade for nodes that are not part of a Geo or repmgr cluster. |
| 12.8 | 9.6.17, 10.12, and 11.7 | 10.12 | 10.12 | Users can manually upgrade to 11.7 following the upgrade docs. |
| 12.0 | 9.6.11 and 10.7 | 10.7 | 10.7 | Package upgrades automatically performed PostgreSQL upgrade. |
| 11.11 | 9.6.11 and 10.7 | 9.6.11 | 9.6.11 | Users can manually upgrade to 10.7 following the upgrade docs. |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | Package upgrades aborted if users still on 9.2. |
| 9.0 | 9.2.18 and 9.6.1 | 9.6.1 | 9.6.1 | Package upgrades automatically performed PostgreSQL upgrade. |
| 8.14 | 9.2.18 and 9.6.1 | 9.2.18 | 9.2.18 | Users can manually upgrade to 9.6 following the upgrade docs. |
