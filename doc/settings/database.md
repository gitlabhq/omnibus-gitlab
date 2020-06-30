---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Database settings

NOTE: **Note:**
Omnibus GitLab has a bundled PostgreSQL server and PostgreSQL is the preferred
database for GitLab.

GitLab supports only PostgreSQL database management system.

Thus you have two options for database servers to use with Omnibus GitLab:

- Use the packaged PostgreSQL server included with Omnibus GitLab (no configuration required, recommended)
- Use an [external PostgreSQL server](#using-a-non-packaged-postgresql-database-management-server)

## Using the PostgreSQL Database Service shipped with Omnibus GitLab

### Configuring SSL

Omnibus automatically enables SSL on the PostgreSQL server, but it will accept
both encrypted and unencrypted connections by default. Enforcing SSL requires
using the `hostssl` configuration in `pg_hba.conf`.
See the [`pg_hba.conf` documentation](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html)
for more details.

SSL support depends on a number of files:

1. The public SSL certificate for the database (`server.crt`).
1. The corresponding private key for the SSL certificate (`server.key`).
1. A root certificate bundle that validates the server's certificate
   (`root.crt`). By default, Omnibus GitLab will use the embedded certificate
   bundle in `/opt/gitlab/embedded/ssl/certs/cacert.pem`. This is not required for
   self-signed certificates.

A self-signed certificate and private key will be automatically generated for
use. If you'd prefer to use a CA-signed certificate, follow the steps below.

Note that the location of these files can be configurable, but the private key
MUST be readable by the `gitlab-psql` user. Omnibus will automatically manage
the permissions of the files for you, but you *must* ensure that the
`gitlab-psql` can access the directory the files are placed in, if the paths
are customized.

For more details, see the [PostgreSQL documentation](https://www.postgresql.org/docs/11/ssl-tcp.html).

Note that `server.crt` and `server.key` may be different from the default SSL
certificates used to access GitLab. For example, suppose the external hostname
of your database is `database.example.com`, and your external GitLab hostname
is `gitlab.example.com`. You will either need a wildcard certificate for
`*.example.com` or two different SSL certificates.

With these files in hand, enable SSL:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   postgresql['ssl_cert_file'] = '/custom/path/to/server.crt'
   postgresql['ssl_key_file'] = '/custom/path/to/server.key'
   postgresql['ssl_ca_file'] = '/custom/path/to/bundle.pem'
   postgresql['internal_certificate'] = "-----BEGIN CERTIFICATE-----
   ...base64-encoded certificate...
   -----END CERTIFICATE-----
   "
   postgresql['internal_key'] = "-----BEGIN RSA PRIVATE KEY-----
   ...base64-encoded private key...
   -----END RSA PRIVATE KEY-----
   "
   ```

   Relative paths will be rooted from the PostgreSQL data directory
   (`/var/opt/gitlab/postgresql/data` by default).

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) to apply the configuration changes.

1. Restart PostgreSQL for the changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

   If PostgreSQL fails to start, check the logs
   (e.g. `/var/log/gitlab/postgresql/current`) for more details.

#### Require SSL

1. Add the following to `/etc/gitlab/gitlab.rb`:

    ```ruby
    postgresql['db_sslmode'] = 'require'
    ```

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) to apply the configuration changes.

1. Restart PostgreSQL for the changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

   If PostgreSQL fails to start, check the logs
   (e.g. `/var/log/gitlab/postgresql/current`) for more details.

#### Disabling SSL

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   postgresql['ssl'] = 'off'
   ```

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) to apply the configuration changes.

1. Restart PostgreSQL for the changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

   If PostgreSQL fails to start, check the logs
   (e.g. `/var/log/gitlab/postgresql/current`) for more details.

#### Verifying that SSL is being used

To check whether SSL is being used by clients, you can run:

```shell
gitlab-rails dbconsole
```

At startup, you should see a banner as the following:

```plaintext
psql (9.6.5)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: on)
Type "help" for help.
```

To check whether clients are using SSL, you can issue this SQL query:

```sql
SELECT * FROM pg_stat_ssl;
```

For example:

```plaintext
gitlabhq_production=> SELECT * FROM pg_stat_ssl;
  pid  | ssl | version |           cipher            | bits | compression | clientdn
-------+-----+---------+-----------------------------+------+-------------+----------
 47506 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47509 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47510 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47527 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47528 | f   |         |                             |      |             |
 47537 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47560 | f   |         |                             |      |             |
 47561 | f   |         |                             |      |             |
 47563 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47564 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47565 | f   |         |                             |      |             |
 47569 | f   |         |                             |      |             |
 47570 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47573 | f   |         |                             |      |             |
 47585 | f   |         |                             |      |             |
 47586 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47618 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 47628 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
 55812 | t   | TLSv1.2 | ECDHE-RSA-AES256-GCM-SHA384 |  256 | t           |
(19 rows)
```

Rows that have `t` listed under the `ssl` column are enabled.

### Configure packaged PostgreSQL server to listen on TCP/IP

The packaged PostgreSQL server can be configured to listen for TCP/IP connections,
with the caveat that some non-critical scripts expect UNIX sockets and may misbehave.

In order to configure the use of TCP/IP for the database service, changes will
need to be made to both `postgresql` and `gitlab_rails` sections of `gitlab.rb`.

#### Configure PostgreSQL block

The following settings are affected in the `postgresql` block:

- `listen_address` controls the address on which PostgreSQL will listen.
- `port` controls the port on which PostgreSQL will listen, and _must be set_ if `listen_address` is.
- `md5_auth_cidr_addresses` is a list of CIDR address blocks which are allowed to
  connect to the server, after authentication via password.
- `trust_auth_cidr_addresses` is a list of CIDR address blocks which are allowed
  to connect to the server, without authentication of any kind. _Be very careful
  with this setting._ It is suggest that this be limited to the loopback address of
  `127.0.0.1/24` or even `127.0.0.1/32`.
- `sql_user` controls the expected username for MD5 authentication. This defaults
  to `gitlab`, and is not a required setting.
- `sql_user_password` sets the password that PostgreSQL will accept for MD5
  authentication. Replace `securesqlpassword` in the example below with an acceptable
  password.

```ruby
postgresql['listen_address'] = '0.0.0.0'
postgresql['port'] = 5432
postgresql['md5_auth_cidr_addresses'] = %w()
postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/24)
postgresql['sql_user'] = "gitlab"

##! SQL_USER_PASSWORD_HASH can be generated using the command `gitlab-ctl pg-password-md5 gitlab`,
##! where `gitlab` is the name of the SQL user that connects to GitLab.
postgresql['sql_user_password'] = "SQL_USER_PASSWORD_HASH"

# force ssl on all connections defined in trust_auth_cidr_addresses and md5_auth_cidr_addresses
postgresql['hostssl'] = true
```

Any client or GitLab service which will connect over the network will need to
provide the values of `sql_user` for the username, and password provided to the
configuration when connecting to the PostgreSQL server. They must also be within the network block provided to `md5_auth_cidr_addresses`

#### Configure GitLab Rails block

To configure the `gitlab-rails` application to connect to the PostgreSQL database
over the network, several settings must be configured.

- `db_host` needs to be set to the IP address of the database sever. If this is
  on the same instance as the PostgrSQL service, this can be `127.0.0.1` and _will
  not require_ password authentication.
- `db_port` sets the port on the PostgreSQL server to connect to, and _must be set_
  if `db_host` is set.
- `db_username` configures the username with which to connect to PostgreSQL. This
  defaults to `gitlab`.
- `db_password` must be provided if connecting to PostgreSQL over TCP/IP, and from
  an instance in the `postgresql['md5_auth_cidr_addresses']` block from settings
  above. This is not required if you are connecting to `127.0.0.1` and have configured
  `postgresql['trust_auth_cidr_addresses']` to include it.

```ruby
gitlab_rails['db_host'] = '127.0.0.1'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "securesqlpassword"
```

#### Apply and restart services

After making the changes above, an administrator should run `gitlab-ctl reconfigure`.
If you experience any issues in regards to the service not listening on TCP, try
directly restarting the service with `gitlab-ctl restart postgresql`.

NOTE: **Note:**
Some included scripts of the Omnibus package, such as `gitlab-psql` expect the
connections to PostgreSQL to be handled over the UNIX socket, and may not function
properly. You can enable TCP/IP without disabling UNIX sockets.

### Enabling PostgreSQL WAL (Write Ahead Log) Archiving

By default WAL archiving of the packaged PostgreSQL is not enabled. Please consider the following when
seeking to enable WAL archiving:

- The WAL level needs to be 'replica' or higher (9.6+ options are `minimal`, `replica`, or `logical`)
- Increasing the WAL level will increase the amount of storage consumed in regular operations

To enable WAL Archiving:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Replication settings
   postgresql['sql_replication_user'] = "gitlab_replicator"
   postgresql['wal_level'] = "replica"
       ...
       ...
   # Backup/Archive settings
   postgresql['archive_mode'] = "on"
   postgresql['archive_command'] = "/your/wal/archiver/here"
   postgresql['archive_timeout'] = "60"
   ```

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) for the changes to take effect. This will result in a database restart.

### Store PostgreSQL data in a different directory

By default, everything is stored under `/var/opt/gitlab/postgresql`, controlled by the `postgresql['dir']` attribute.

This consists of:

1. The database socket will be `/var/opt/gitlab/postgresql/.s.PGSQL.5432`. This is controlled by `postgresql['unix_socket_directory']`
1. The `gitlab-psql` system user will have its `HOME` directory set to this. This is controlled by `postgresql['home']`
1. The actual data will be stored in `/var/opt/gitlab/postgresql/data`

To change the location of the PostgreSQL data

CAUTION: **Caution:**
If you have an existing database, you need to move the data to the new location first

CAUTION: **Caution:**
This is an intrusive operation. It cannot be done without downtime on an existing installation

1. Stop GitLab if this is an existing installation: `gitlab-ctl stop`.
1. Update `postgresql['dir']` to the desired location.
1. Run `gitlab-ctl reconfigure`.
1. Start GitLab `gitlab-ctl start`.

### Upgrade packaged PostgreSQL server

`omnibus-gitlab` provides a command `gitlab-ctl pg-upgrade` to update the packaged
PostgreSQL server to a later version (if one is included in the package). `omnibus-gitlab`
will automatically update PostgreSQL to the [default shipped version](../package-information/postgresql_versions.md)
during packages, upgrades, unless specifically opted out.

To opt out of automatic PostgreSQL upgrade during GitLab package upgrades, run:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

If you want to manually upgrade without upgrading GitLab, you can follow these instructions:

**Note:**

- Please fully read this section before running any commands.
- Please plan ahead as upgrade involves downtime.
- If you encounter any problems during upgrade, please raise an issue
  with a full description at the [Omnibus GitLab issue tracker](https://gitlab.com/gitlab-org/omnibus-gitlab).

Before upgrading, please check the following:

- You're currently running the latest version of GitLab and it is working.
- If you recently upgraded, make sure that `sudo gitlab-ctl reconfigure` ran successfully before you proceed.
- You will need to have sufficient disk space for two copies of your database. **Do not attempt to upgrade unless you have enough free space available.** Check your database size using `sudo du -sh /var/opt/gitlab/postgresql/data` (or update to your database path) and space available using `sudo df -h`. If the partition where the database resides does not have enough space, you can pass the argument `--tmp-dir $DIR` to the command.

NOTE: **Note:**
This upgrade requires downtime as the database must be down while the upgrade is being performed.
The length of time depends on the size of your database.
If you would rather avoid downtime, it is possible to upgrade to a new database using [Slony](https://www.slony.info/).
Please see our [guide](https://docs.gitlab.com/ee/update/upgrading_postgresql_using_slony.html) on how to perform the upgrade.

Once you have confirmed that the above checklist is satisfied,
you can proceed.
To perform the upgrade, run the command:

```shell
sudo gitlab-ctl pg-upgrade
```

NOTE: **Note:**
In GitLab 12.8 or later, you can pass the `-V 11` flag to upgrading to PostgreSQL 11. PostgreSQL 11 became the default for
`pg-upgrade` in GitLab 12.10.

This command performs the following steps:

1. Checks to ensure the database is in a known good state
1. Shuts down the existing database, any unnecessary services, and enables the GitLab deploy page.
1. Changes the symlinks in `/opt/gitlab/embedded/bin/` for PostgreSQL to point to the newer version of the database
1. Creates a new directory containing a new, empty database with a locale matching the existing database
1. Uses the `pg_upgrade` tool to copy the data from the old database to the new database
1. Moves the old database out of the way
1. Moves the new database to the expected location
1. Calls `sudo gitlab-ctl reconfigure` to do the required configuration changes, and start the new database server.
1. Start the remaining services, and remove the deploy page.
1. If any errors are detected during this process, it should immediately revert to the old version of the database.

Once this step is complete, verify everything is working as expected.

**Once you have verified that your GitLab instance is running correctly**,
you can clean up the old database files with:

```shell
sudo rm -rf /var/opt/gitlab/postgresql/data.<old_version>
sudo rm -f /var/opt/gitlab/postgresql-version.old
```

You can find details of PostgreSQL versions shipped with various GitLab versions in
[PostgreSQL versions shipped with Omnibus GitLab](../package-information/postgresql_versions.md).
The following section details their update policy.

#### GitLab 12.10 and later

The default PostgreSQL version is set to 11.x, and an automatic upgrade of the
database is done on package upgrades for installs that are not using repmgr or Geo.

The automatic upgrade is skipped in any of the following cases:

- you are running the database in high_availability using repmgr.
- your database nodes are part of GitLab Geo configuration.
- you have specifically opted out using the `/etc/gitlab/disable-postgresql-upgrade` file outlined above.

Users can manually upgrade using `gitlab-ctl pg-upgrade`. To upgrade PostgreSQL on installs with HA or Geo, see [Packaged PostgreSQL deployed in an HA/Geo Cluster](#packaged-postgresql-deployed-in-an-hageo-cluster).

#### GitLab 12.8 and later

**As of GitLab 12.8, PostgreSQL 9.6.17, 10.12, and 11.7 are shipped with
Omnibus GitLab.**

Automatically during package upgrades (unless opted out) and when user manually
runs `gitlab-ctl pg-upgrade`, `omnibus-gitlab` will still be attempting to
upgrade the database only to 10.x, while 11.x will be available for users to
manually upgrade to. To manually update PostgreSQL to version 11.x , the `pg-upgrade`
command has to be passed with a version argument (`-V` or `--target-version`)

```shell
sudo gitlab-ctl pg-upgrade -V 11
```

#### GitLab 12.0 and later

**As of GitLab 12.0, PostgreSQL 9.6.11 and 10.7 are shipped with Omnibus
GitLab.**

On upgrades, we will be automatically upgrading the database to 10.7 unless
specifically opted out as described above.

#### GitLab 11.11 and later

**As of GitLab 11.11, PostgreSQL 9.6.X and 10.7 are shipped with Omnibus
GitLab.**

Fresh installs will be getting PostgreSQL 10.7 while GitLab package upgrades
will retain the existing version of PostgreSQL. Users can manually upgrade to
the 10.7 using the `pg-upgrade` command as mentioned above.

### Downgrade packaged PostgreSQL server

DANGER: **Danger:**
This operation will revert your current database, *including its data*, to its state
before your last upgrade. Be sure to create a backup before attempting to downgrade
your packaged PostgreSQL database.

On GitLab versions which ship multiple PostgreSQL versions, users can downgrade
an already upgraded PostgreSQL version to the earlier version using the `gitlab-ctl
revert-pg-upgrade` command. This command also supports the `-V` flag to specify
a target version for scenarios where more than two PostgreSQL versions are shipped in
the package (for example: GitLab 12.8 where PostgreSQL 9.6.x, 10.x, and 11.x are
shipped).

If the target version is not specified, it will use the version in `/var/opt/gitlab/postgresql-version.old`
if available. Otherwise it falls back to the default version shipped with GitLab.

On other GitLab versions which ship only one PostgreSQL version, you can't
downgrade your PostgreSQL version. You must downgrade GitLab to an older version for
this.

### Connecting to the bundled PostgreSQL database

If you need to connect to the bundled PostgreSQL database and are
using the default Omnibus GitLab database configuration, you can
connect as the application user:

```shell
sudo gitlab-rails dbconsole
```

or as a PostgreSQL superuser:

```shell
sudo gitlab-psql -d gitlabhq_production
```

## Using a non-packaged PostgreSQL database management server

By default, GitLab is configured to use the PostgreSQL server that is included
in Omnibus GitLab. You can also reconfigure it to use an external instance of
PostgreSQL.

CAUTION: **Caution:**
If you are using non-packaged PostgreSQL server, you need to make
sure that PostgreSQL is set up according to the [database requirements document](https://docs.gitlab.com/ee/install/requirements.html#database).

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = 'USERNAME'
   gitlab_rails['db_password'] = 'PASSWORD'
   ```

   Don't forget to remove the `#` comment characters at the beginning of these
   lines.

   **Note:**

   - `/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains
     plain-text passwords.
   - PostgreSQL allows to listen on [multiple addresses](https://www.postgresql.org/docs/11/runtime-config-connection.html)

     If you use multiple addresses in `gitlab_rails['db_host']`, comma-separated, the first address in the list will be used for connection.

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) for the changes to take effect.

1. [Seed the database](#seed-the-database-fresh-installs-only).

### UNIX socket configuration for non-packaged PostgreSQL

If you want to use your system's PostgreSQL server (installed on the same machine as GitLab)
instead of the one bundled with GitLab, you can do so by using a UNIX socket:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   # The path where the socket lives
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   ```

   NOTE: **Note:** `gitlab_rails['db_socket']` is a setting for Mysql and it won't have any effect on PostgreSQL.

1. Reconfigure GitLab for the changes to take effect:

   ```ruby
   sudo gitlab-ctl-reconfigure
   ```

### Configuring SSL

#### Require SSL

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   postgresql['db_sslmode'] = 'require'
   ```

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) to apply the configuration changes.

1. Restart PostgreSQL for the changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

   If PostgreSQL fails to start, check the logs
   (e.g. `/var/log/gitlab/postgresql/current`) for more details.

#### Require SSL and verify server certificate against CA bundle

PostgreSQL can be configured to require SSL and verify the server certificate
against a CA bundle in order to prevent spoofing.

NOTE: **Note:**
The CA bundle that is specified in `gitlab_rails['db_sslrootcert']` must contain
both the root and intermediate certificates.

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['db_sslmode'] = "verify-full"
   gitlab_rails['db_sslrootcert'] = "your-full-ca-bundle.pem"
   ```

   NOTE: **Note:**
   If you are using Amazon RDS for your PostgreSQL server, please ensure you
   download and use the [combined CA bundle](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem)
   for `gitlab_rails['db_sslrootcert']`. More information on this can be found
   in the [using SSL/TLS to Encrypt a Connection to a DB Instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)
   article on AWS.

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) to apply the configuration changes.

1. Restart PostgreSQL for the changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

   If PostgreSQL fails to start, check the logs
   (e.g. `/var/log/gitlab/postgresql/current`) for more details.

### Backup and restore a non-packaged PostgreSQL database

When using the [Rake backup create and restore task](https://docs.gitlab.com/ee/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system), GitLab will
attempt to use the packaged `pg_dump` command to create a database backup file
and the packaged `psql` command to restore a backup. This will only work if
they are the correct versions. Check the versions of the packaged `pg_dump` and
`psql`:

```shell
/opt/gitlab/embedded/bin/pg_dump --version
/opt/gitlab/embedded/bin/psql --version
```

If these versions are different from your non-packaged external PostgreSQL, you
will need to install tools that match your database version and then follow the
steps below. There are multiple ways to install PostgreSQL client tools. See
<https://www.postgresql.org/download/> for options.

Once the correct `psql` and `pg_dump` tools are available on your system, follow
these steps, using the correct path to the location you installed the new tools:

1. Add symbolic links to the non-packaged versions:

   ```shell
   ln -s /path/to/new/pg_dump /path/to/new/psql /opt/gitlab/bin/
   ```

1. Check the versions:

   ```shell
   /opt/gitlab/bin/pg_dump --version
   /opt/gitlab/bin/psql --version
   ```

   They should now be the same as your non-packaged external PostgreSQL.

After this is done, ensure that the backup and restore tasks are using the
correct executables by running both the [backup](https://docs.gitlab.com/ee/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system) and
[restore](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-a-previously-created-backup) tasks.

### Upgrade a non-packaged PostgreSQL database

NOTE: **Note:**
If you're using Amazon RDS and are seeing extremely high (near 100%) CPU utilization following a major version upgrade (i.e. from `10.x` to `11.x`), running an `ANALYZE VERBOSE;` query may be necessary to recreate query plans and reduce CPU utilization on the database server(s). [Amazon recommends this](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html) as part of a major version upgrade.

Before upgrading, check the [GitLab and PostgreSQL version compatibility table](../package-information/postgresql_versions.md) to determine your upgrade path.
When using GitLab backup/restore you **must** keep the same version of GitLab so upgrade PostgreSQL first then GitLab.

The [backup and restore Rake task](https://docs.gitlab.com/ee/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system) can be used to back up and
restore the database to a later version of PostgreSQL.

This example demonstrates upgrading from a database host running PostgreSQL 10 to another database host running PostgreSQL 11 and incurs downtime.

1. Spin up a new PostgreSQL 11 database server that is set up according to the [database requirements](https://docs.gitlab.com/ee/install/requirements.html#database).

1. You should ensure that the compatible versions of `pg_dump` and `pg_restore`
   are being used on the GitLab Rails instance. To amend GitLab configuration, edit `/etc/gitlab/gitlab.rb`
   and specify the value of `postgresql['version']`:

    ```ruby
    postgresql['version'] = 11
    ```

  NOTE: **Note:**
  Connecting to PostgreSQL v12 (alongside with amending `postgresql['version'] = 12`) will currently break the [GitLab Backup/Restore](https://docs.gitlab.com/ee/raketasks/backup_restore.html) functionality unless the v12 client binaries are available on the file system. More on this topic can be found under [backup and restore a non-packaged database](#backup-and-restore-a-non-packaged-postgresql-database).
  This problem with missing v12 client binaries will be tackled in this epic: [Add support for PostgreSQL 12](https://gitlab.com/groups/gitlab-org/-/epics/2374).

  NOTE: **Note:**
  If configuring a version number whose binaries are unavailable on the file system, GitLab/Rails will use the default database's version binaries (default as per [GitLab and PostgreSQL version compatibility table](../package-information/postgresql_versions.md)).

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Stop GitLab (note that this step will cause downtime):

   ```shell
   sudo gitlab-ctl stop
   ```

1. Run the backup Rake task using the SKIP options to back up only the database. Make a note of the backup file name, you'll use it later to restore:

   ```shell
   sudo gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,pages,registry
   ```

1. Shutdown the PostgreSQL 10 database host.

1. Edit `/etc/gitlab/gitlab.rb` and update the `gitlab_rails['db_host']` setting to point to
the PostgreSQL database 11 host.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restore the database using the database backup file created earlier, and make sure to answer **no** when asked "This task will now rebuild the authorized_keys file":

   ```shell
   sudo gitlab-backup restore BACKUP=<database-backup-filename>
   ```

1. Start GitLab:

   ```shell
   sudo gitlab-ctl start
   ```

### Seed the database (fresh installs only)

CAUTION: **Caution:**
This is a destructive command; do not run it on an existing database!

---

Omnibus GitLab will not automatically seed your external database. Run the
following command to import the schema and create the first administration user:

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

If you want to specify the initial registration token for shared GitLab Runners,
specify the `initial_shared_runners_registration_token` setting in `/etc/gitlab/gitlab.rb`
before running the `gitlab:setup` command:

```ruby
gitlab_rails['initial_shared_runners_registration_token'] = 'token'
```

### Troubleshooting

#### Set `default_transaction_isolation` into `read committed`

If you see errors similar to the following in your `production/sidekiq` log:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

Chances are your database's `default_transaction_isolation` configuration is not
in line with GitLab application requirement. You can check this configuration by
connecting to your PostgreSQL database and run `SHOW default_transaction_isolation;`.
GitLab application expects `read committed` to be configured.

This `default_transaction_isolation` configuration is set in your
`postgresql.conf` file. You will need to restart/reload the database once you
changed the configuration. This configuration comes by default in the packaged
PostgreSQL server included with Omnibus GitLab.

## Application Settings for the Database

### Disabling automatic database migration

If you have multiple GitLab servers sharing a database, you will want to limit the
number of nodes that are performing the migration steps during reconfiguration.

Edit `/etc/gitlab/gitlab.rb`:

```ruby
# Enable or disable automatic database migrations
gitlab_rails['auto_migrate'] = false
```

Don't forget to remove the `#` comment characters at the beginning of this
line.

NOTE: **Note:**
`/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains
plain-text passwords.

The next time a reconfigure is triggered, the migration steps will not be performed.

### Setting client statement_timeout

The amount time that Rails will wait for a database transaction to complete
before timing out can now be adjusted with the `gitlab_rails['db_statement_timeout']`
setting. By default, this setting is not used.

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['db_statement_timeout'] = 45000
```

In this case the client `statement_timeout` is set to 45 seconds. The value
is specified in milliseconds.

## Packaged PostgreSQL deployed in an HA/Geo Cluster

### Upgrading a GitLab HA cluster

If [PostgreSQL is configured for high availability](https://docs.gitlab.com/ee/administration/high_availability/database.html),
`pg-upgrade` should be run all the nodes running PostgreSQL. Other nodes can be
skipped, but must be running the same GitLab version as the database nodes.
Follow the steps below to upgrade the database nodes

1. Secondary nodes must be upgraded before the primary node.
   1. On the secondary nodes, edit `/etc/gitlab/gitlab.rb` to include the following:

   ```shell
   # Replace X with value of number of db nodes + 1
   postgresql['max_replication_slots'] = X
    ```

   1. Run `gitlab-ctl reconfigure` to update the configuration.
   1. Run `sudo gitlab-ctl restart postgresql` to get PostgreSQL restarted with the new configuration.
   1. On running `pg-upgrade` on a PostgreSQL secondary node, the node will be removed
      from the cluster.
   1. Once all the secondary nodes are upgraded using `pg-upgrade`, the user
      will be left with a single-node cluster that has only the primary node.
   1. `pg-upgrade`, on secondary nodes will not update the existing data to
      match the new version, as that data will be replaced by the data from
      primary node. It will, however move the existing data to a backup
      location.
1. Once all secondary nodes are upgraded, run `pg-upgrade` on primary node.
   1. On the primary node, edit `/etc/gitlab/gitlab.rb` to include the following:

   ```shell
   # Replace X with value of number of db nodes + 1
   postgresql['max_replication_slots'] = X
    ```

   1. Run `gitlab-ctl reconfigure` to update the configuration.
   1. Run `sudo gitlab-ctl restart postgresql` to get PostgreSQL restarted with the new configuration.
   1. On a primary node, `pg-upgrade` will update the existing data to match
      the new PostgreSQL version.
1. Recreate the secondary nodes by running the following command on each of them

   ```shell
   gitlab-ctl repmgr standby setup MASTER_NODE_NAME
   ```

1. Check if the repmgr cluster is back to the original state

   ```shell
   gitlab-ctl repmgr cluster show
   ```

NOTE: **Note:**
As of GitLab 12.8, you can opt into upgrading PostgreSQL 11 with `pg-upgrade -V 11`

### Troubleshooting upgrades in an HA cluster

If at some point, the bundled PostgreSQL had been running on a node before upgrading to an HA setup, the old data directory may remain. This will cause `gitlab-ctl reconfigure` to downgrade the version of the PostgreSQL utilities it uses on that node. Move (or remove) the directory to prevent this:

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

If you encounter the following error when recreating the secondary nodes with `gitlab-ctl repmgr standby setup MASTER_NODE_NAME`, ensure that you have `postgresql['max_replication_slots'] = X`, replacing `X` with value of number of db nodes + 1, is included in `/etc/gitlab/gitlab.rb`:

```shell
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.

```

### Upgrading a Geo instance

Since Geo depends on PostgreSQL streaming replication by default, there are
additional considerations when upgrading GitLab and/or when upgrading
PostgreSQL described below.

CAUTION: **Caution:**
If you are running a Geo installation using PostgreSQL 9.6.x, please upgrade to GitLab 12.4 or newer. Older versions were affected [by an issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4692) that could cause automatic upgrades of the PostgreSQL database to fail on the secondary. This issue is now fixed.

#### Caveats when upgrading PostgreSQL with Geo

CAUTION: **Caution:**
When using Geo, upgrading PostgreSQL **requires downtime on all secondaries**.

When using Geo, upgrading PostgreSQL **requires downtime on all secondaries**
because it requires re-initializing PostgreSQL replication to Geo
**secondaries**. This is due to the way PostgreSQL streaming replication works.
Re-initializing replication copies all data from the primary again, so it can
take a long time depending mostly on the size of the database and available
bandwidth. For example, at a transfer speed of 30 Mbps, and a database size of
100 GB, resynchronization could take approximately 8 hours. See
[PostgreSQL documentation](https://www.postgresql.org/docs/11/pgupgrade.html)
for more.

#### Disabling automatic PostgreSQL upgrades

From GitLab 12.1 through GitLab 12.9, GitLab package upgrades automatically try
to upgrade PostgreSQL to version 10.x. In GitLab 12.10+, upgrades of PostgreSQL do not happen automatically when using Geo.

Before upgrading to GitLab 12.1 through GitLab 12.9, we strongly recommend
disabling automatic upgrades of PostgreSQL and manually upgrading PostgreSQL
separately from upgrading the GitLab package to avoid any unintended downtime.

You can disable automatic upgrades of PostgreSQL by running the following on
all nodes running `postgresql` or `geo-postgresql`:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

#### How to upgrade PostgreSQL when using Geo

To upgrade PostgreSQL, you will need the name of the replication slot, and the
replication user's password.

1. Find the name of the existing replication slot on the Geo primary's database
   node, run:

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

   NOTE: **Note:**
   If you can't find your `slot_name` here, or there is no output returned, your Geo secondaries may not be healthy. In that case, make sure that [the secondaries are healthy and replication is working](https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html#check-the-health-of-the-secondary-node).

1. Gather the replication user's password. It was set while setting up Geo in
   [Step 1. Configure the primary server](https://docs.gitlab.com/ee/administration/geo/replication/database.html#step-1-configure-the-primary-server).

1. Manually upgrade PostgreSQL on the Geo primary. Run on the Geo primary's
   database node:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   NOTE: **Note:**
   As of GitLab 12.8, you can opt into upgrading PostgreSQL 11 with `pg-upgrade -V 11`

1. Manually upgrade PostgreSQL on the Geo secondaries. Run on the Geo
   **secondary database** and also on the **tracking database**:

   NOTE: **Note:**
   Please wait for the **primary database** to finish upgrading before
   beginning this step, so the secondary can remain ready as a backup.
   Afterward, you can upgrade the **tracking database** in parallel with the
   **secondary database**.

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. Restart the database replication on the Geo **secondary database** using the
   command:

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME
   ```

   You will be prompted for the replication user's password of the primary. Replace `SECONDARY_SLOT_NAME` with the slot name retrieved from the first step above.
   server.

1. [Reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) on the Geo **secondary database** to update the
   `pg_hba.conf` file. This is needed because `replicate-geo-database`
   replicates the primary's file to the secondary.

1. Refresh the foreign tables on the Geo secondary server by running this
   command on an application node (any node running `puma`/`unicorn`, `sidekiq`, or
   `geo-logcursor`).

   ```shell
   sudo gitlab-rake geo:db:refresh_foreign_tables
   ```

1. Restart `puma` (or `unicorn`), `sidekiq`, and `geo-logcursor`.

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. Navigate to `https://your_primary_server/admin/geo/nodes` and ensure that all nodes are healthy
