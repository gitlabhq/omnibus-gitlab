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

See [doc/settings/logs.md.](doc/settings/logs.md)

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
