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

#### Removing unused layers not referenced by manifests

GitLab Container Registry follows the same default workflow as Docker Distribution:
retain all layers, even ones that are unreferenced directly to allow all content
to be accessed using context addressable identifiers.

#### Content-addressable layers

Consider the following example, where you first build the image:

```bash
docker build -t my.registry.com/my.group/my.project:latest .
# this builds a image with content of sha256:111111
docker push my.registry.com/my.group/my.project:latest
```

Now, you do overwrite `:latest` with a new version:

```bash
docker build -t my.registry.com/my.group/my.project:latest .
# this builds a image with content of sha256:222222
docker push my.registry.com/my.group/my.project:latest
```

Now, the `:latest` points to manifest of `sha256:222222`. However, due to architecture
of registry this data is still accessible via:
`docker pull my.registry.com/my.group/my.project@sha256:111111` even though it is
no longer directly accessible via `:latest` tag.

#### Recycle unreference manifests

However, in most of workflows you do not care about old layers, if they are not directly
referenced by registry tag. The `registry-garbage-collect` supports the `-m` switch
to allow you to remove all unreferenced manifests and layers, that are not directly
accessible via `tag`.

Since this is a way more destrictive operation, this behavior is disabled by default.
You are likely expecting this way of operation, but before doing that ensure
that you backup all registry data to ensure that you do not use the data.

This will allow you to recycle all registry space with the [Container Registry API](#administratively-recycling-unused-tags).

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
      'enabled' => true
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
      'enabled' => false
    }
  }
}
```

and run `sudo gitlab-ctl reconfigure`.

### Running on schedule

Ideally, you want to run garbage collect of registry regularly on weekly basis
during time when registry is not being in-use.

The simplest way is to add a new crontab job that it is gonna run periodically,
once a week.
Create a file under `/etc/cron.d/registry-garbage-collect`:

```bash
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Run every Sunday at 04:05am
5 4 * * 0  root gitlab-ctl registry-garbage-collect
```

### Administratively recycling unused tags

GitLab offers a set of APIs to manipulate Container Registry and aid the process
of removing unused tags. Currently, this is exposed using API, but in the future
these controls will be migrated to the GitLab Interface and be allowed by the
developer.

Project maintainers can
[delete container registry tags in bulk](https://docs.gitlab.com/ce/api/container_registry.html#delete-repository-tags-in-bulk)
periodically based on their own criteria.

However, this alone does not recycle data, it only unlinks tags from manifests
and image blobs. To recycle the container registry data in the whole GitLab instance run:

```sh
sudo gitlab-ctl registry-garbage-collect
```

You might also remove all unreferenced manifests with.
Since this is a way more destructive operation take a look
at [Recycle unreference manifests](#recycle-unreference-manifests)
to understand the implications.

```sh
sudo gitlab-ctl registry-garbage-collect -m
# or
sudo gitlab-ctl registry-garbage-collect /path/to/config.yml -m
```
