---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Managing PostgreSQL versions

The PostgreSQL Global Development Group typically releases [one major version of PostgreSQL each year](https://www.postgresql.org/support/versioning/), usually in the third quarter. Our goal is to balance supporting and adopting new PostgreSQL features with the downtime and administrative costs of having our users upgrade. GitLab aims to support two versions of PostgreSQL at any given time. This means that prior to adding a new version of PostgreSQL, we will remove the oldest version of PostgreSQL that we support, and bump the minimally required PostgreSQL version up by one major version. PostgreSQL removals are only done in major GitLab releases.

## Software definitions

The software definitions are in:

- `config/software/postgresql_old.rb`
- `config/software/postgresql.rb`
- `config/software/postgresql_new.rb`

## Default version

The version that should be installed by default is controlled by using the 'link bin files' step. The software definition with this step will be used on a new installation.

## Upgrading

The [`gitlab-ctl pg-upgrade` command](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-ctl-commands/pg-upgrade.rb) is used to upgrade from `postgresql_old` or `postgresql` to `postgresql_new`. See our [documentation for how to use it](../settings/database.md#upgrade-packaged-postgresql-server)

### Automatic upgrades

The [`gitlab-ctl pg-upgrade` command](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-ctl-commands/pg-upgrade.rb) is run on every upgrade. The default version used in the upgrade and revert command need to changed when wanting to change with PostgreSQL version gets automatically upgraded to during install.

## Removing an older version

When it is time to remove an older version, create an epic with issues to track the following:

1. Remove the old version from Omnibus.
1. Remove the old version from the Helm install.
1. To minimize CI costs, remove the older version from test suites (before doing this, check that .com is not using the old version still).
1. Remove references to that version of PostgreSQL in the GitLab user documentation.
1. Start printing deprecation notices in the release post three GitLab versions before a major PostgreSQL version is removed. If the PostgreSQL version is a version that will be removed within three releases, print deprecation notices in the Admin UI and during the GitLab upgrade process, regardless of whether it is an Omnibus-managed PostgreSQL database or an external database.

For removals, perform the following steps:

1. Run `git rm config/software/postgresql_old.rb`
1. Run `git mv config/software/postgresql{,_old}.rb`
1. Edit `config/software/postgresql_old.rb` and change name from `postgresql` to `postgresql_old`
1. Run `git mv config/software/postgresql{_new,}.rb`
1. Edit `config/software/postgresql.rb` and change name from `postgresql_new` to `postgresql`

## Adding a new version

1. Run `git cp config/software/postgresql{,_new}.rb`
1. Edit `config/software/postgresql_new.rb`. Update:

   1. `name` to `postgresql_new`
   1. `default_version` to the new version
   1. `version` to have the new version, and the `sha256`
   1. `major_version` if necessary

1. Add the new PostgreSQL version to the full test suite.
1. Run a nightly test of the `gitlab-org/gitlab` repo against the new version of PostgreSQL.
1. Ensure that the package build includes both versions of PostgreSQL.
1. For Helm installs, update the default PostgreSQL chart version if the default is changing.
1. Update user documentation.

### Testing

1. GitLab runs on the new version of PostgreSQL.
1. Test running GitLab on the new PostgreSQL version at the 10k reference architecture scale and check for performance regressions.

Test upgrades and fresh installs for the following environments:

1. Single node.
1. Install with a separate database node managed by Omnibus.
1. HA database cluster with 3 or more database nodes in the cluster.
1. Geo installations with a single node primary and single node secondary (`postgresql` and `geo-postgresql` on the same secondary node).
1. Geo installations with a HA database cluster on the primary.
1. Geo installations with a separate database and a separate tracking database on the secondary.
1. Helm installs.
1. After testing that upgrades to the newest version work, confirm that `revert-pg-upgrade` successfully downgrades to the previously used version, including on a Geo secondary standalone tracking database.
1. If the default PostgreSQL version changes, test GitLab upgrades with external PostgreSQL databases.
1. Back up and restore.
If the default PostgreSQL version is changing:

1. Auto upgrades on a single node install, separate database node, HA cluster.
1. Auto upgrades where an external PostgreSQL database is being used.
1. Geo installs are not auto upgraded.

If the minimally required version is changing:

1. GitLab upgrade errors out if an old version of Omnibus-managed PostgreSQL is still installed.

If the above tests are manual, we risk missing a breaking change that is introduced after the manual tests have been performed. We should automate as many of these tests as possible.

1. The package build includes both versions of PostgreSQL
1. Running `gitlab-ctl pg-upgrade` works

### The case of `libpq`

Some modules, including `pyscopg2`, depend on PostgreSQL client library, i.e. `libpq`. It should be always linked to the
latest bundled version. By using the latest version we rely on backward compatibility of `libpq`.

## Known issues

Geo uses streaming replication, which requires that the entire secondary database be resynced after a major PostgreSQL upgrade. This can cause hours or days of downtime, and as such, we do not recommend auto upgrades for Geo customers. Starting in 12.10, automatic PostgreSQL upgrades are disabled if Geo is detected.
