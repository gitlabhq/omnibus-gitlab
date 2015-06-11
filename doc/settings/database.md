# Database settings

## Using a MySQL database management server (Enterprise Edition only)

If you want to use MySQL and are using the **GitLab Enterprise Edition packages** please do the following:

Important note: if you are connecting omnibus-gitlab to an existing GitLab
database you should create a backup before attempting this procedure.

### Create a user and database for GitLab

First, set up your database server according to the [upstream GitLab
instructions](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md#5-database).
For manual GitLab CI database setup instructions see [the GitLab CI manual installation instructions](https://gitlab.com/gitlab-org/gitlab-ci/blob/master/doc/install/installation.md#4-prepare-the-database).
If you want to keep using an existing GitLab database you can skip this step.

### Configure omnibus-gitlab to connect to it

Next, we add the following settings to `/etc/gitlab/gitlab.rb`.

```ruby
# Disable the built-in Postgres
postgresql['enable'] = false

# Fill in the values for database.yml
gitlab_rails['db_adapter'] = 'mysql2'
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '127.0.0.1'
gitlab_rails['db_port'] = '3306'
gitlab_rails['db_username'] = 'git'
gitlab_rails['db_password'] = 'password'

# For GitLab CI, you can use the same parameters:
gitlab_ci['db_adapter'] = 'mysql2'
# etc.
```

Parameters such as `db_adapter` correspond to `adapter` in `database.yml`; see the upstream GitLab for a [MySQL configuration example][database.yml.mysql].
We remind you that `/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains plaintext passwords.

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Seed the database (fresh installs only)

Omnibus-gitlab will not automatically seed your external database. Run the
following command to import the schema and create the first admin user:

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:setup
```

You can manually seed the GitLab CI database with the following command:

```shell
# Remove 'sudo' if you are the 'gitlab-ci' user
sudo gitlab-ci-rake setup
```

If you want to specify a password for the default `root` user, in `gitlab.rb` specify the `initial_root_password` setting:

```ruby
  gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

and then run the `gitlab:setup` command.

**This is a destructive command; do not run it on an existing database!**

## Using a non-packaged PostgreSQL database management server

If you do do not want to use the packaged Postgres server you can configure an external one similar to configuring a MySQL server (shown above).
Configuring a PostgreSQL server is possible both with GitLab Community Edition and Enterprise Edition packages.
Please see the upstream GitLab for a [PostgreSQL configuration example][database.yml.postgresql].

[database.yml.postgresql]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/database.yml.postgresql
