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

#### Starting a Postgres superuser psql session in Geo tracking database

Similar to the previous command, if you need superuser access to the bundled
Geo tracking database (`geo-postgresql`), you can use the `gitlab-geo-psql`.
It takes the same arguments as the regular `psql` command.

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

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
