# Maintenance commands

The following commands can be run after installation.

## Get service status

Run `sudo gitlab-ctl status`; the output should look like this:

```
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: unicorn: (pid 961) 7s; run: log: (pid 960) 7s
```

## Tail process logs

See [settings/logs.md.](../settings/logs.md)

## Starting and stopping

After omnibus-gitlab is installed and configured, your server will have a Runit
service directory (`runsvdir`) process running that gets started at boot via
`/etc/inittab` or the `/etc/init/gitlab-runsvdir.conf` Upstart resource. You
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

## Invoking Rake tasks

To invoke a GitLab Rake task, use `gitlab-rake`. For example:

```shell
sudo gitlab-rake gitlab:check
```

Leave out 'sudo' if you are the 'git' user.

Contrary to with a traditional GitLab installation, there is no need to change
the user or the `RAILS_ENV` environment variable; this is taken care of by the
`gitlab-rake` wrapper script.

## Starting a Rails console session

If you need access to a Rails production console for your GitLab installation
you can start one with the command below. Please be warned that it is very easy
to inadvertently modify, corrupt or destroy data from the console.

```shell
# start a Rails console for GitLab
sudo gitlab-rails console
```

This will only work after you have run `gitlab-ctl reconfigure` at least once.

## Starting a Postgres superuser psql session

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

### Starting a Postgres superuser psql session in Geo tracking database

Similar to the previous command, if you need superuser access to the bundled
Geo tracking database (`geo-postgresql`), you can use the `gitlab-geo-psql`.
It takes the same arguments as the regular `psql` command.

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

## Container Registry garbage collection

Container Registry can use considerable amounts of disk space. To clear up
some unused layers, registry includes a garbage collect command.

GitLab offers a set of APIs to manipulate the Container Registry and aid the process
of removing unused tags. Currently, this is exposed using the API, but in the future,
these controls will be migrated to the GitLab interface.

Project maintainers can
[delete Container Registry tags in bulk](https://docs.gitlab.com/ce/api/container_registry.html#delete-repository-tags-in-bulk)
periodically based on their own criteria.

However, this alone does not recycle data, it only unlinks tags from manifests
and image blobs. To recycle the Container Registry data in the whole GitLab
instance, you can use the built-in command provided by `gitlab-ctl`.

### Understanding the content-addressable layers

Consider the following example, where you first build the image:

```bash
# This builds a image with content of sha256:111111
docker build -t my.registry.com/my.group/my.project:latest .
docker push my.registry.com/my.group/my.project:latest
```

Now, you do overwrite `:latest` with a new version:

```bash
# This builds a image with content of sha256:222222
docker build -t my.registry.com/my.group/my.project:latest .
docker push my.registry.com/my.group/my.project:latest
```

Now, the `:latest` tag points to manifest of `sha256:222222`. However, due to
the architecture of registry, this data is still accessible when pulling the
image `my.registry.com/my.group/my.project@sha256:111111`, even though it is
no longer directly accessible via the `:latest` tag.

### Recycling unused tags

There are a couple of considerations you need to note before running the
built-in command:

- The built-in command will stop the registry before it starts the garbage collection.
- The garbage collect command takes some time to complete, depending on the
  amount of data that exists.
- If you changed the location of registry configuration file, you will need to
  specify its path.
- After the garbage collection is done, the registry should start up automatically.

CAUTION: **Warning:**
By running the built-in garbage collection command, it will cause downtime to
the Container Registry. To avoid that, you can [use another method](#performing-garbage-collection-without-downtime).

If you did not change the default location of the configuration file, run:

```sh
sudo gitlab-ctl registry-garbage-collect
```

This command will take some time to complete, depending on the amount of
layers you have stored.

If you changed the location of the Container Registry `config.yml`:

```sh
sudo gitlab-ctl registry-garbage-collect /path/to/config.yml
```

You may also [remove all unreferenced manifests](#removing-unused-layers-not-referenced-by-manifests),
although this is a way more destructive operation, and you should first
understand the implications.

### Removing unused layers not referenced by manifests

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/3097)
> in Omnibus GitLab 11.10.

DANGER: **Danger:**
This is a destructive operation.

The GitLab Container Registry follows the same default workflow as Docker Distribution:
retain all layers, even ones that are unreferenced directly to allow all content
to be accessed using context addressable identifiers.

However, in most workflows, you don't care about old layers if they are not directly
referenced by the registry tag. The `registry-garbage-collect` command supports the
`-m` switch to allow you to remove all unreferenced manifests and layers that are
not directly accessible via `tag`:

```sh
sudo gitlab-ctl registry-garbage-collect -m
```

Since this is a way more destructive operation, this behavior is disabled by default.
You are likely expecting this way of operation, but before doing that, ensure
that you have backed up all registry data.

### Performing garbage collection without downtime

You can perform a garbage collection without stopping the Container Registry by setting
it into a read-only mode and by not using the built-in command. During this time,
you will be able to pull from the Container Registry, but you will not be able to
push. To enable the read-only mode:

NOTE: **Note:**
By default, the registry storage path is `/var/opt/gitlab/gitlab-rails/shared/registry`.

1. In `/etc/gitlab/gitlab.rb`, specify the read-only mode:

```ruby
  registry['storage'] = {
    'filesystem' => {
      'rootdirectory' => "<your_registry_storage_path>"
    },
    'maintenance' => {
      'readonly' => {
        'enabled' => true
      }
    }
  }
```

1. Save and reconfigure GitLab:

   ```sh
   sudo gitlab-ctl reconfigure
   ```

   This will set the Container Registry into the read only mode.

1. Next, trigger the garbage collect command:

   ```sh
   sudo /opt/gitlab/embedded/bin/registry garbage-collect /var/opt/gitlab/registry/config.yml
   ```

   This will start the garbage collection, which might take some time to complete.

1. Once done, in `/etc/gitlab/gitlab.rb` change it back to read-write mode:

   ```ruby
    registry['storage'] = {
      'filesystem' => {
        'rootdirectory' => "<your_registry_storage_path>"
      },
      'maintenance' => {
        'readonly' => {
          'enabled' => false
        }
      }
    }
   ```

1. Save and reconfigure GitLab:

   ```sh
   sudo gitlab-ctl reconfigure
   ```

### Running the garbage collection on schedule

Ideally, you want to run the garbage collection of the registry regularly on a
weekly basis at a time when the registry is not being in-use.
The simplest way is to add a new crontab job that it will run periodically
once a week.

Create a file under `/etc/cron.d/registry-garbage-collect`:

```bash
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Run every Sunday at 04:05am
5 4 * * 0  root gitlab-ctl registry-garbage-collect
```
