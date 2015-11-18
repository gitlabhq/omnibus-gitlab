# Database settings

## Connecting to the bundled Postgresql database

If you need to connect to the bundled Postgresql database and are using default omnibus-gitlab database configuration,
you can connect using:

```bash
sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production
```

## Using a MySQL database management server (Enterprise Edition only)

If you want to use MySQL or MariaDB and are using the **GitLab Enterprise Edition packages** please do the following:

Important note: if you are connecting omnibus-gitlab to an existing GitLab
database you should create a backup before attempting this procedure.

### Create a user and database for GitLab

First, set up your database server according to the [upstream GitLab
instructions](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md#5-database).

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

If you want to specify a password for the default `root` user, in `gitlab.rb`
specify the `initial_root_password` setting:

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

and then run the `gitlab:setup` command.

**This is a destructive command; do not run it on an existing database!**

## Using a non-packaged PostgreSQL database management server

If you do not want to use the packaged PostgreSQL server you can configure external one similar to configuring a MySQL server (shown above).

```ruby
# Disable the built-in Postgres
postgresql['enable'] = false

# Fill in the connection details for database.yml
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '127.0.0.1'
gitlab_rails['db_port'] = '3306'
gitlab_rails['db_username'] = 'git'
gitlab_rails['db_password'] = 'password'

# For GitLab CI, you can use the same parameters:
gitlab_ci['db_host'] = '127.0.0.1'
# etc.
```

When using [backup create and restore task](http://doc.gitlab.com/ce/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system), GitLab will attempt using the `pg_dump` command to create a database backup file and `psql` to restore a backup from the previously created file. In omnibus-gitlab, the PATH env. variable is setup in a way that puts omnibus required paths first. This means that backup will be using the packaged `pg_dump` and `psql`.

To go around this issue and use the external `pg_dump` and `psql` commands you can symlink the executables to `/opt/gitlab/bin`. The executable location depends on the OS. As an example, for Debian:

```bash
# Find the location of psql and pg_dump
which pg_dump psql
# This will output something like:
# /usr/bin/pg_dump
# /usr/bin/psql

# Symlink to /opt/gitlab/bin
ln -s /usr/bin/pg_dump /usr/bin/psql /opt/gitlab/bin/
```
After this is done, ensure that backup and restore tasks are using the correct executables by running both [backup](http://doc.gitlab.com/ce/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system) and [backup restore](http://doc.gitlab.com/ce/raketasks/backup_restore.html#omnibus-installations) tasks.
