# Managing PostgreSQL versions

Usually, we are shipping two versions of PostgreSQL. We need to support running on both versions, as well as upgrading from the older to the newer.

## Software definitions

The software definitions are in:

```
config/software/postgresql.rb
config/software/postgresql_new.rb
```

## Default version

The version that should be installed by default is controlled by using the 'link bin files' step. The software definition with this step will be used on a new installation.

## Upgrading

The [pg-upgrade gitlab-ctl command](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-ctl-commands/pg-upgrade.rb) is used to upgrade from `postgresql` to `postgresql_new`. See our [documentation for how to use it](../settings/database.md#upgrade-packaged-postgresql-server)

## Removing an older version

When it is time to remove an older version, perform the following steps:

1. Run `git rm config/software/postgresql.rb`
1. Run `git mv config/software/postgresql{_new,}.rb`
1. Edit `config/software/postgresql.rb` and change name from `postgresql_new` to `postgresql`

## Adding a new version

We currently only support shipping two versions:

1. Run `git cp config/software/postgresql{,_new}.rb`
1. Edit `config/software/postgresql_new.rb`. Update:

   1. `name` to `postgresql_new`
   1. `default_version` to the new version
   1. `version` to have the new version, and the `sha256`
   1. `major_version` if necessary

Additionally, ensure that:

1. The package build includes both versions of PostgreSQL
1. Running `gitlab-ctl pg-upgrade` works
