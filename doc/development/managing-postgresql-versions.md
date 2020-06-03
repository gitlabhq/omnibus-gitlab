---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Managing PostgreSQL versions

Usually, we are shipping three versions of PostgreSQL. We need to support running on all versions, as well as upgrading from the older versions to the newest.

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

When it is time to remove an older version, perform the following steps:

1. Run `git rm config/software/postgresql_old.rb`
1. Run `git mv config/software/postgresql{,_old}.rb`
1. Edit `config/software/postgresql_old.rb` and change name from `postgresql` to `postgresql_old`
1. Run `git mv config/software/postgresql{_new,}.rb`
1. Edit `config/software/postgresql.rb` and change name from `postgresql_new` to `postgresql`

## Adding a new version

We currently support shipping three versions:

1. Run `git cp config/software/postgresql{,_new}.rb`
1. Edit `config/software/postgresql_new.rb`. Update:

   1. `name` to `postgresql_new`
   1. `default_version` to the new version
   1. `version` to have the new version, and the `sha256`
   1. `major_version` if necessary

Additionally, ensure that:

1. The package build includes both versions of PostgreSQL
1. Running `gitlab-ctl pg-upgrade` works

### The case of `libpq`

Some modules, including `pyscopg2`, depend on PostgreSQL client library, i.e. `libpq`. It should be always linked to the
latest bundled version. By using the latest version we rely on backward compatibility of `libpq`.
