# Maintenance commands

## After installation

### Get service status

Run `sudo gitlab-ctl status`; the output should look like this:

```
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: unicorn: (pid 961) 7s; run: log: (pid 960) 7s
```

### Tail process logs

See [settings/logs.md.](../settings/logs.md)

### Starting and stopping

After omnibus-gitlab is installed and configured, your server will have a Runit
service directory (`runsvdir`) process running that gets started at boot via
`/etc/inittab` or the `/etc/init/gitlab-runsvdir.conf` Upstart resource.  You
should not have to deal with the `runsvdir` process directly; you can use the
`gitlab-ctl` front-end instead.

You can start, stop or restart GitLab and all of its components with the
following commands.

```shell
# Start all GitLab components
sudo gitlab-ctl start

# Stop all GitLab components
sudo gitlab-ctl stop

# Restart all GitLab components
sudo gitlab-ctl restart
```

Note that on a single-core server it may take up to a minute to restart Unicorn
and Sidekiq. Your GitLab instance will give a 502 error until Unicorn is up
again.

It is also possible to start, stop or restart individual components.

```shell
sudo gitlab-ctl restart sidekiq
```

Unicorn supports zero-downtime reloads. These can be triggered as follows:

```shell
sudo gitlab-ctl hup unicorn
```

Note that you cannot use a Unicorn reload to update the Ruby runtime.

### Invoking Rake tasks

To invoke a GitLab Rake task, use `gitlab-rake`. For example:

```shell
sudo gitlab-rake gitlab:check
```

Leave out 'sudo' if you are the 'git' user.

Contrary to with a traditional GitLab installation, there is no need to change
the user or the `RAILS_ENV` environment variable; this is taken care of by the
`gitlab-rake` wrapper script.

### Starting a Rails console session

If you need access to a Rails production console for your GitLab installation
you can start one with the command below. Please be warned that it is very easy
to inadvertently modify, corrupt or destroy data from the console.

```shell
# start a Rails console for GitLab
sudo gitlab-rails console
```

This will only work after you have run `gitlab-ctl reconfigure` at least once.

### Starting a Postgres superuser psql session

If you need superuser access to the bundled Postgres service you can
use the `gitlab-psql` command. It takes the same arguments as the
regular `psql` command.

```shell
# Superuser psql access to GitLab's database
sudo gitlab-psql -d gitlabhq_production
```

This will only work after you have run `gitlab-ctl reconfigure` at
least once. The `gitlab-psql` command cannot be used to connect to a
remote Postgres server, nor to connect to a local non-Omnibus Postgres
server.

If you start gitlab-psql from a directory that is not world-readable
(like /root) then `psql` will print a warning message:

```
could not change directory to "/root"
```

This is normal behavior and it can be ignored.

### Container registry garbage collection

Container registry can use considerable amounts of disk space. To clear up
some unused layers, registry includes a garbage collect command.

There are a couple of considerations you need to note before running the
built in command:

* The built in command will stop the registry before it starts garbage collect
* The garbage collect command takes some time to complete, depending on the
amount of data that exists
* If you changed the location of registry configuration file, you will need to
specify the path
* After the garbage collect is done, registry should start up automatically

**Warning** The command below will cause Container registry downtime.

If you did not change the default location of the configuration file, to do
garbage collection:

```
sudo gitlab-ctl registry-garbage-collect
```

This command will take some time to complete, depending on the amount of
layers you have stored.

If you changed the location of the Container registry config.yml:

```
sudo gitlab-ctl registry-garbage-collect /path/to/config.yml
```

#### Doing garbage collect without downtime

You can do a garbage collect without stopping the Container registry by setting
it into a read only mode. During this time, you will be able to pull from
the Container registry but you will not be able to push.

These are the steps you need to take in order to complete the garbage collection:

In `/etc/gitlab/gitlab.rb` specify the read only mode:

```ruby
registry['storage'] = {
  'maintenance' => {
    'readonly' => {
      'enabled' => 'true'
    }
  }
}
```

Save and run `sudo gitlab-ctl reconfigure`. This will set the Container registry
into the read only mode.

Next, trigger the garbage collect command:

```
sudo /opt/gitlab/embedded/bin/registry garbage-collect /var/opt/gitlab/registry/config.yml
```

This will start the garbage collection. The command will take some time to complete.

Once done, in `/etc/gitlab/gitlab.rb` change the configuration to:

```ruby
registry['storage'] = {
  'maintenance' => {
    'readonly' => {
      'enabled' => 'false'
    }
  }
}
```

and run `sudo gitlab-ctl reconfigure`.

#### Upgrade postgresql database

Currently GitLab Omnibus runs PostgreSQL 9.2.18 by default. Version 9.6.1 is included as an option for users to manually upgrade. The next major release will ship with a newer PostgresQL by default, and will upgrade existing omnibus installations when they are upgraded.

In order to be able to manually upgrade, please check the folowing:
* You're currently running the latest version of GitLab and it is working. If you recently upgraded, make sure that `gitlab-ctl reconfigure` has successfully run before you proceed.
* You're using the bundled version of PostgreSQL. Look for `postgresql['enable']` to be `true`, commented out, or absent from `/etc/gitlab/gitlab.rb`
* You haven't already upgraded. Running `/opt/gitlab/embedded/bin/psql --version` should print `psql (PostgreSQL) 9.2.18`
* You will need to have sufficient disk space for two copies of your database. Do not attempt to upgrade unless you have enough free space available. If the partition where the database resides does not have enough space (default location is `/var/opt/gitlab/postgresql/data`), you can pass the argument `--tmp-dir $DIR` to the command.

Please note:
* This upgrade does require downtime as the database must be down while the upgrade is being performed. The length of time entirely depends on the size of your database.

To perform the ugprade, run the command:

```
sudo gitlab-ctl pg-upgrade
```
This command performs the following steps:
1. Checks to ensure the database is in a known good state
1. Shuts down the existing database
1. Changes the symlinks in `/opt/gitlab/embedded/bin/` for PostgreSQL to point to the newer version of the database
1. Creates a new directory containing a new, empty database with a locale matching the existing database
1. Uses the `pg_upgrade` tool to copy the data from the old database to the new database
1. Moves the old database out of the way
1. Moves the new database to the expected location
1. Calls `gitlab-ctl` reconfigure to make any needed changes, and start the new database server.
1. If any errors are detected during this process, it should immediately revert to the old version of the database.

Once this step is complete, verify everything is working as expected. If so, you can remove the old database with:

```
sudo rm -rf /var/opt/gitlab/postgresql/data.9.2.18
```

If you run into an issue, and wish to downgrade the version of PostgreSQL, run:

```
sudo gitlab-ctl revert-pg-upgrade
```
Please note:
This will revert your database and data to what was there before you upgraded the database. Any changes you have made since the ugprade will be lost.
