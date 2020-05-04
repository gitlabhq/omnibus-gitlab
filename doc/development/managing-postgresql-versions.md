# Managing PostgreSQL versions

The PostgreSQL Global Development Group typically releases [one major version of PostgreSQL each year](https://www.postgresql.org/support/versioning/), usually in the third quarter. Our goal is to add support for the newest PostgreSQL release in the next major release of GitLab, and to support two versions of PostgreSQL at any given time. This means that in each major release of GitLab, we will remove the oldest version of PostgreSQL that we support, bump the minimally required PostgreSQL version up by one major version, and add optional support for the newest PostgreSQL version. 

### Example

1.  GitLab 14.0 (May 2021) supports PostgreSQL 12 and 13, with the default version for new installs and upgrades being PostgreSQL 12
2.  PostgreSQL 14 is released in October 2021
3.  In GitLab 14.x, the default version for new installs and upgrades is bumped to PostgreSQL 13
3.  In GitLab 15.0 (May 2022) we remove PostgreSQL 12, minimally require PostgreSQL 13, and add support for PostgreSQL 14

We need to support running GitLab on both supported versions, as well as upgrading from the older versions to the newest.
**Note:** GitLab 13.0 to 13.3 will only have support for one version of PostgreSQL (11). This is an exception to the plan outlined above. 

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
1.  Remove the old version from Omnibus
2.  Remove the old version from the Helm install
3.  To minimize CI costs, remove the older version from test suites. (Before doing this, check that .com is not using the old version still)

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

Additionally, ensure that:

1. The package build includes both versions of PostgreSQL
1. Running `gitlab-ctl pg-upgrade` works on a single node, HA cluster, and Geo
2. After testing that upgrades to the newest version work, confirm that `revert-pg-upgrade` successfully downgrades to the previously used version, including on a Geo secondary standalone tracking database. 
