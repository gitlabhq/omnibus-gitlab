# Database settings

_**Note:**
Omnibus GitLab has a bundled PostgreSQL server and it is the preferred DBMS to
be used with GitLab._

---

GitLab supports the following DBMSs:

- PostgreSQL
- MySQL

All in all, you have three options of database servers to use with Omnibus
GitLab:

- Use the PostgreSQL bundled server (no configuration required)
- Use an [external PostgreSQL server](#using-a-non-packaged-postgresql-database-management-server)
- Use an [external MySQL server](#using-a-mysql-database-management-server-enterprise-edition-only)

## Using a non-packaged PostgreSQL database management server

If you do not want to use the packaged PostgreSQL server, you can configure an
external one:

1.  Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    # Disable the built-in Postgres
    postgresql['enable'] = false

    # Fill in the connection details for database.yml
    gitlab_rails['db_adapter'] = 'postgresql'
    gitlab_rails['db_encoding'] = 'utf8'
    gitlab_rails['db_host'] = '127.0.0.1'
    gitlab_rails['db_port'] = '3306'
    gitlab_rails['db_username'] = 'git'
    gitlab_rails['db_password'] = 'password'
    ```

1.  [Reconfigure GitLab][] for the changes to take effect.

1.  [Seed the database](#seed-the-database-fresh-installs-only).

**Note:**
`/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains
plain-text passwords.

---

When using the [backup create and restore task][rake-backup], GitLab will
attempt to use the `pg_dump` command to create a database backup file and `psql`
to restore a backup from the previously created file. In Omnibus GitLab, the
`PATH` environment variable is set up in a way that puts Omnibus required paths
first. This means that backup will be using the packaged `pg_dump` and `psql`.

To go around this issue and use the external `pg_dump` and `psql` commands, you
can symlink the executables to `/opt/gitlab/bin/`. The executable location
depends on the OS. As an example, for Debian:

1.  Find the location of `psql` and `pg_dump`:

    ```bash
    which pg_dump psql
    ```

    This will output something like:

    ```
    /usr/bin/pg_dump
    /usr/bin/psql
    ```

1.  Symlink to `/opt/gitlab/bin`:

    ```bash
    ln -s /usr/bin/pg_dump /usr/bin/psql /opt/gitlab/bin/
    ```
---

After this is done, ensure that the backup and restore tasks are using the
correct executables by running both the [backup][rake-backup] and
[restore][rake-restore] tasks.

## Using a MySQL database management server (Enterprise Edition only)

_**Important note:**
If you are connecting Omnibus GitLab to an existing GitLab database you should
[create a backup][rake-backup] before attempting this procedure._

---

GitLab Enterprise Edition supports setting an external MySQL server instead of
the PostgreSQL bundled one. The MySQL server itself is _not_ shipped with
Omnibus.

Make sure that GitLab's MySQL database collation is UTF-8, otherwise you could
hit [collation issues][ee-245]. See ['Set MySQL collation to UTF-8']
(#set-mysql-collation-to-utf-8) to fix any relevant errors.

The following guide assumes that you want to use MySQL or MariaDB and are using
the **GitLab Enterprise Edition packages**.

1.  First, set up your database server according to the [upstream GitLab
    instructions][mysql-install].

    If you want to keep using an existing GitLab database you can skip this step.

1.  Next, add the following settings to `/etc/gitlab/gitlab.rb`:

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
    ```

    `db_adapter` and `db_encoding` should be like the example above. Change
    all other settings according to your MySQL setup.


1.  [Reconfigure GitLab][] for the changes to take effect.

1.  [Seed the database](#seed-the-database-fresh-installs-only).

**Note:**
`/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains
plain-text passwords.

## Seed the database (fresh installs only)

**This is a destructive command; do not run it on an existing database!**

---

Omnibus GitLab will not automatically seed your external database. Run the
following command to import the schema and create the first admin user:

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:setup
```

If you want to specify a password for the default `root` user, specify the
`initial_root_password` setting in `/etc/gitlab/gitlab.rb` before running the
`gitlab:setup` command above:

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

## Troubleshooting

### Set MySQL collation to UTF-8

If you are hit by an error similar as described in [this issue][ee-245]
(_Mysql2::Error: Incorrect string value (\`st_diffs\` field)_), you
can change the collation of the faulty table with:

```bash
ALTER TABLE merge_request_diffs default character set = utf8 collate = utf8_unicode_ci;
ALTER TABLE merge_request_diffs convert to character set utf8 collate utf8_unicode_ci;
```

In the above example the affected table is called `merge_request_diffs`.

### Connecting to the bundled PostgreSQL database

If you need to connect to the bundled PostgreSQL database and are using the
default Omnibus GitLab database configuration, you can connect using:

```bash
sudo gitlab-rails dbconsole
```

or use `psql` directly:

```bash
sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production
```

[ee-245]: https://gitlab.com/gitlab-org/gitlab-ee/issues/245 "MySQL collation issue"
[rake-backup]: http://doc.gitlab.com/ce/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system "Backup raketask documentation"
[Reconfigure GitLab]: http://doc.gitlab.com/ce/administration/restart_gitlab.html#omnibus-gitlab-reconfigure "Reconfigure GitLab"
[rake-restore]: http://doc.gitlab.com/ce/raketasks/backup_restore.html#restore-a-previously-created-backup "Restore raketask documentation"
[mysql-install]: http://doc.gitlab.com/ce/install/installation.html#database "MySQL documentation"
