# Omnibus GitLab

This project creates full-stack platform-specific [downloadable packages for GitLab][downloads].
For other installation options please see the
[GitLab installation page][installation].

## Canonical source

The source of omnibus-gitlab is [hosted on
GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab) and there are mirrors
to make contributing as easy as possible.

## Documentation version

Please make sure you are viewing the documentation for the version of
omnibus-gitlab you are using. In most cases this should be the highest numbered
stable branch (example shown below).

![documentation version](doc/images/omnibus-documentation-version.png)

## Omnibus fork

Omnibus GitLab is using a fork of [omnibus project](https://github.com/chef/omnibus). Fork is located at [gitlab.com](https://gitlab.com/gitlab-org/omnibus).

## GitLab CI

To setup GitLab CI please see the [separate GitLab CI
documentation](doc/gitlab-ci/README.md).

## Configuration options

GitLab and GitLab CI are configured by setting their relevant options in
`/etc/gitlab/gitlab.rb`. For a complete list of available options, visit the
[gitlab.rb.template][]. New installations starting from GitLab 7.6, will have
all the options of the template listed in `/etc/gitlab/gitlab.rb` by default.

## Installation

Please follow the steps on the [downloads page][downloads].

### After installation

Run `sudo gitlab-ctl status`; the output should look like this:

```
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: unicorn: (pid 961) 7s; run: log: (pid 960) 7s
```

If any of the processes is not behaving like expected, try tailing their logs
to see what is wrong.

```
sudo gitlab-ctl tail postgresql
```

Your GitLab instance should reachable over HTTP at the IP or hostname of your server.
You can login as an admin user with username `root` and password `5iveL!fe`.

### Common installation problems

#### Apt error 'The requested URL returned error: 403'

When trying to install GitLab using the apt repo if you receive an error similar to:

```bash
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

check if there is a repository cacher in front of your server, like for example `apt-cacher-ng`.

Add the following line to apt-cacher-ng config(eg. in  `/etc/apt-cacher-ng/acng.conf`):

```bash
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com)
```

Read more about `apt-cacher-ng` and the reasons why this change is needed [on the packagecloud blog](http://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/).

#### GitLab is unreachable in my browser

Try [specifying](#configuring-the-external-url-for-gitlab) an `external_url` in
`/etc/gitlab/gitlab.rb`. Also check your firewall settings; port 80 (HTTP) or
443 (HTTPS) might be closed on your GitLab server.

#### Emails are not being delivered

To test email delivery you can create a new GitLab account for an email that is
not used in your GitLab instance yet.

If necessary, you can modify the 'From' field of the emails sent by GitLab with
the following setting in `/etc/gitlab/gitlab.rb`:

```
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

#### Reconfigure freezes at `ruby_block[supervise_redis_sleep] action run`

During the first `gitlab-ctl reconfigure` run, omnibus-gitlab needs to figure
out if your Linux server is using SysV Init, Upstart or Systemd so that it can
install and activate the `gitlab-runsvdir` service. If `gitlab-ctl reconfigure`
makes the wrong decision, it will later hang at
`ruby_block[supervise_redis_sleep] action run`.

The choice of init system is currently made in [the embedded Runit
cookbook](files/gitlab-cookbooks/runit/recipes/default.rb) by essentially
looking at the output of `uname -a`, `/etc/issue` and others. This mechanism
can make the wrong decision in situations such as:

- your OS release looks like 'Debian 7' but it is really some variant which
  uses Upstart instead of SysV Init;
- your OS release is unknown to the Runit cookbook (e.g. ClearOS 6.5).

Solving problems like this would require changes to the embedded Runit
cookbook; Merge Requests are welcome. Until this problem is fixed, you can work
around it by manually performing the appropriate installation steps for your
particular init system. For instance, to manually set up `gitlab-runsvdir` with
Upstart, you can do the following:

```
sudo cp /opt/gitlab/embedded/cookbooks/runit/files/default/gitlab-runsvdir.conf /etc/init/
sudo initctl start gitlab-runsvdir
sudo gitlab-ctl reconfigure # Resume gitlab-ctl reconfigure
```

#### TCP ports for GitLab services are already taken

By default, Unicorn listens at TCP address 127.0.0.1:8080. Nginx
listens on port 80 (HTTP) and/or 443 (HTTPS) on all interfaces.

The ports for Redis, PostgreSQL and Unicorn can be overriden in
`/etc/gitlab/gitlab.rb` as follows:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
unicorn['port'] = 3456
```

For Nginx port changes please see
[doc/settings/nginx.md](doc/settings/nginx.md).

#### Git SSH access stops working on SELinux-enabled systems

On SELinux-enabled systems the git user's `.ssh` directory or its contents can
get their security context messed up. You can fix this by running `sudo
gitlab-ctl reconfigure`, which will run a `chcon --recursive` command on
`/var/opt/gitlab/.ssh`.

#### Postgres error 'FATAL:  could not create shared memory segment: Cannot allocate memory'

The packaged Postgres instance will try to allocate 25% of total memory as
shared memory. On some Linux (virtual) servers, there is less shared memory
available, which will prevent Postgres from starting. In
`/var/log/gitlab/postgresql/current`:

```
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

You can manually lower the amount of shared memory Postgres tries to allocate
in `/etc/gitlab/gitlab.rb`:

```ruby
postgresql['shared_buffers'] = "100MB"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

#### Reconfigure complains about the GLIBC version

```
$ gitlab-ctl reconfigure
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

This can happen if the omnibus package you installed was built for a different
OS release than the one on your server. Double-check that you downloaded and
installed the correct omnibus-gitlab package for your operating system.

#### Reconfigure fails to create the git user

This can happen if you run `sudo gitlab-ctl reconfigure` as the git user.
Switch to another user.

More importantly: do not give sudo rights to the git user or to any of the
other users used by omnibus-gitlab. Bestowing unnecessary privileges on a
system user weakens the security of your system.


#### Failed to modify kernel parameters with sysctl

If sysctl cannot modify the kernel parameters you could possibly get an error with the following stack trace:

```
 * execute[sysctl] action run
================================================================================
Error executing action `run` on resource 'execute[sysctl]'
================================================================================


Mixlib::ShellOut::ShellCommandFailed
------------------------------------
Expected process to exit with [0], but received '255'
---- Begin output of /sbin/sysctl -p /etc/sysctl.conf ----

```
This is unlikely to happen with non virtualized machines but on a VPS with virtualization like openVZ, container might not have the required module enabled
or container doesn't have access to kernel parameters.

Try enabling the module on which sysctl errored out, on how to enable the module see example [here](http://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error).

There is a reported workaround described in [this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/361) which requires editing the GitLab' internal recipe by supplying the switch which will ignore failures. Ignoring errors can have unexpected side effects on performance of your GitLab server so it is not recommended to do so.

#### I am unable to install omnibus-gitlab without root access

Occasionally people ask if they can install GitLab without root access. This is
not possible because GitLab uses multiple system users (privilege separation)
for security reasons. The `gitlab-ctl reconfigure` script needs root access to
create/manage these users and the files they have access to.

Once GitLab is up an running on your system, you will see that several
processes run as root, for instance the 'runsv' and 'runsvdir' processes
(Runit) and the NGINX master process. Runit is a process supervisor that
manages the different GitLab services for you. Because those services run as
different users (privilege separation), and Runit needs to manage all of those
services, Runit itself needs root. NGINX (the front-end web server) has its own
built-in process supervision and privilege separation. It has a 'master'
process running as root that can open privileged TCP ports (80/443) and files
(SSL certificates), while pushing the risky business of handling web requests
to 'worker' processes running as gitlab-www.

#### gitlab-rake assets:precompile fails with 'Permission denied'

Some users report that running `gitlab-rake assets:precompile` does not work
with the omnibus packages. The short answer to this is: do not run that
command, it is only for GitLab installations from source.

The GitLab web interface uses CSS and JavaScript files, called 'assets' in Ruby
on Rails-speak. In the [upstream GitLab
repository](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets)
these files are stored in a developer-friendly way: easy to read and edit. When
you are a normal user of GitLab, you do not want these files to be in the
developer friendly format however because that makes GitLab slow. This is why
part of the GitLab setup process is to convert the assets from a
developer-friendly format to an end-user friendly (compact, fast) format; that
is what the `rake assets:precompile` script is for.

When you install GitLab from source (which was the only way to do it before we
had omnibus packages) you need to convert the assets on your GitLab server
every time you update GitLab. People used to overlook this step and there are
still posts, comments and mails out there on the internet where users recommend
each other to run `rake assets:precompile`. With the omnibus packages things
are different: when we build the package [we convert the assets for
you](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74).
When you install GitLab with an omnibus package, the converted assets are
already there! That is why you do not need to run `rake assets:precompile` when
you install GitLab from a package.

When `gitlab-rake assets:precompile` fails with a permission error it fails for
a good reason from a security standpoint: the fact that the assets cannot
easily be rewritten makes it harder for an attacker to use your GitLab server
to serve evil JavaScript code to the visitors of your GitLab server.

If you want to run GitLab with custom JavaScript or CSS code you are probably
better off running GitLab from source, or building your own packages.

### Uninstalling omnibus-gitlab

To uninstall omnibus-gitlab, preserving your data (repositories, database, configuration), run the following commands.

```
# Stop gitlab and remove its supervision process
sudo gitlab-ctl uninstall

# Debian/Ubuntu
sudo dpkg -r gitlab

# Redhat/Centos
sudo rpm -e gitlab
```

To remove all omnibus-gitlab data use `sudo gitlab-ctl cleanse`.

To remove all users and groups created by omnibus-gitlab, before removing the gitlab package (with dpkg or yum) run `sudo gitlab-ctl remove_users`. *Note* All gitlab processes need to be stopped before runnign the command.

#### 'Short read or OOM loading DB' error

Try cleaning the old redis session by following the [documentation here.](http://doc.gitlab.com/ce/operations/cleaning_up_redis_sessions.html)

## Updating

Instructions for updating your Omnibus installation and upgrading from a manual installation are in the [update doc](doc/update.md).

## Starting and stopping

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

## Configuration

### Backup and restore omnibus-gitlab configuration

All configuration for omnibus-gitlab is stored in `/etc/gitlab`. To backup your
configuration, just backup this directory.

```shell
# Example backup command for /etc/gitlab:
# Create a time-stamped .tar file in the current directory.
# The .tar file will be readable only to root.
sudo sh -c 'umask 0077; tar -cf $(date "+etc-gitlab-%s.tar") -C / etc/gitlab'
```

You can extract the .tar file as follows.

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf etc-gitlab-1399948539.tar -C /
```

Remember to run `sudo gitlab-ctl reconfigure` after restoring a configuration
backup.

NOTE: Your machines SSH host keys are stored in a separate location at `/etc/ssh/`. Be sure to also [backup and restore those keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

### Configuring the external URL for GitLab

In order for GitLab to display correct repository clone links to your users
it needs to know the URL under which it is reached by your users, e.g.
`http://gitlab.example.com`. Add or edit the following line in
`/etc/gitlab/gitlab.rb`:

```ruby
external_url "http://gitlab.example.com"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.


### Storing Git data in an alternative directory

By default, omnibus-gitlab stores Git repository data under
`/var/opt/gitlab/git-data`: repositories are stored in
`/var/opt/gitlab/git-data/repositories`, and satellites in
`/var/opt/gitlab/git-data/gitlab-satellites`.  You can change the location of
the `git-data` parent directory by adding the following line to
`/etc/gitlab/gitlab.rb`.

```ruby
git_data_dir "/mnt/nas/git-data"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

If you already have existing Git repositories in `/var/opt/gitlab/git-data` you
can move them to the new location as follows:

```shell
# Prevent users from writing to the repositories while you move them.
sudo gitlab-ctl stop

# Only move 'repositories'; 'gitlab-satellites' will be recreated
# automatically. Note there is _no_ slash behind 'repositories', but there _is_ a
# slash behind 'git-data'.
sudo rsync -av /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/

# Fix permissions if necessary
sudo gitlab-ctl reconfigure

# Double-check directory layout in /mnt/nas/git-data. Expected output:
# gitlab-satellites  repositories
sudo ls /mnt/nas/git-data/

# Done! Start GitLab and verify that you can browse through the repositories in
# the web interface.
sudo gitlab-ctl start
```

### Changing the name of the Git user / group

By default, omnibus-gitlab uses the user name `git` for Git gitlab-shell login,
ownership of the Git data itself, and SSH URL generation on the web interface.
Similarly, `git` group is used for group ownership of the Git data.  You can
change the user and group by adding the following lines to
`/etc/gitlab/gitlab.rb`.

```ruby
user['username'] = "gitlab"
user['group'] = "gitlab"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Setting up LDAP sign-in

See [doc/settings/ldap.md](doc/settings/ldap.md).

### Enable HTTPS

See [doc/settings/nginx.md](doc/settings/nginx.md#enable-https).

#### Redirect `HTTP` requests to `HTTPS`.

See [doc/settings/nginx.md](doc/settings/nginx.md#redirect-http-requests-to-https).

#### Change the default port and the ssl certificate locations.

See [doc/settings/nginx.md](doc/settings/nginx.md#change-the-default-port-and-the-ssl-certificate-locations).

### Use non-packaged web-server

For using an existing Nginx, Passenger, or Apache webserver see [doc/settings/nginx.md](doc/settings/nginx.md#using-a-non-bundled-web-server).

## Using a non-packaged PostgreSQL database management server

To connect to an external PostgreSQL or MySQL DBMS see [doc/settings/database.md](doc/settings/database.md) (MySQL support in the Omnibus Packages is Enterprise Only).

## Using a non-packaged Redis instance

See [doc/settings/redis.md](doc/settings/redis.md).

### Adding ENV Vars to the Gitlab Runtime Environment

See
[doc/settings/environment-variables.md](doc/settings/environment-variables.md).

### Changing gitlab.yml settings

See [doc/settings/gitlab.yml.md](doc/settings/gitlab.yml.md).

### Specify numeric user and group identifiers

Omnibus-gitlab creates users for GitLab, PostgreSQL, Redis and NGINX. You can
specify the numeric identifiers for these users in `/etc/gitlab/gitlab.rb` as
follows.

```ruby
user['uid'] = 1234
user['gid'] = 1234
postgresql['uid'] = 1235
postgresql['gid'] = 1235
redis['uid'] = 1236
redis['gid'] = 1236
web_server['uid'] = 1237
web_server['gid'] = 1237
```

### Sending application email via SMTP

See [doc/settings/smtp.md](doc/settings/smtp.md).

### Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented in
[doc.gitlab.com](http://doc.gitlab.com/ce/integration/omniauth.html).

### Adjusting Unicorn settings

See [doc/settings/unicorn.md](doc/settings/unicorn.md).

### Setting the NGINX listen address or addresses

See [doc/settings/nginx.md](doc/settings/nginx.md).

### Inserting custom NGINX settings into the GitLab server block

See [doc/settings/nginx.md](doc/settings/nginx.md).

### Inserting custom settings into the NGINX config

See [doc/settings/nginx.md](doc/settings/nginx.md).

## Backups

### Creating an application backup

To create a backup of your repositories and GitLab metadata, run the following command.

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:backup:create
```

For GitLab CI run:

```
# Remove 'sudo' if you are the 'git' user
sudo gitlab-ci-rake backup:create
```

This will store a tar file in `/var/opt/gitlab/backups`. The filename will look like
`1393513186_gitlab_backup.tar`, where 1393513186 is a timestamp.

If you want to store your GitLab backups in a different directory, add the
following setting to `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl
reconfigure`:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

### Upload backups to remote (cloud) storage

For details check [backup restore document of GitLab CE](https://gitlab.com/gitlab-org/gitlab-ce/blob/966f68b33e1f15f08e383ec68346ed1bd690b59b/doc/raketasks/backup_restore.md#upload-backups-to-remote-cloud-storage).

## Invoking Rake tasks

To invoke a GitLab Rake task, use `gitlab-rake` (for GitLab) or
`gitlab-ci-rake` (for GitLab CI). For example:

```shell
sudo gitlab-rake gitlab:check
sudo gitlab-ci-rake -T
```

Leave out 'sudo' if you are the 'git' user or the 'gitlab-ci' user.

Contrary to with a traditional GitLab installation, there is no need to change
the user or the `RAILS_ENV` environment variable; this is taken care of by the
`gitlab-rake` and `gitlab-ci-rake` wrapper scripts.

## Directory structure

Omnibus-gitlab uses four different directories.

- `/opt/gitlab` holds application code for GitLab and its dependencies.
- `/var/opt/gitlab` holds application data and configuration files that
  `gitlab-ctl reconfigure` writes to.
- `/etc/gitlab` holds configuration files for omnibus-gitlab. These are
  the only files that you should ever have to edit manually.
- `/var/log/gitlab` contains all log data generated by components of
  omnibus-gitlab.

## Omnibus-gitlab and SELinux

Although omnibus-gitlab runs on systems that have SELinux enabled, it does not
use SELinux confinement features:
- omnibus-gitlab creates unconfined system users;
- omnibus-gitlab services run in an unconfined context.

The correct operation of Git access via SSH depends on the labeling of
`/var/opt/gitlab/.ssh`. If needed you can restore this labeling by running
`sudo gitlab-ctl reconfigure`.

Depending on your platform, `gitlab-ctl reconfigure` will install SELinux
modules required to make GitLab work. These modules are listed in
[files/gitlab-selinux/README.md](files/gitlab-selinux/README.md).

NSA, if you're reading this, we'd really appreciate it if you could contribute back a SELinux profile for omnibus-gitlab :)
Of course, if anyone else is reading this, you're welcome to contribute the SELinux profile too.

## Logs

### Tail logs in a console on the server

If you want to 'tail', i.e. view live log updates of GitLab logs you can use
`gitlab-ctl tail`.

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### Runit logs

The Runit-managed services in omnibus-gitlab generate log data using
[svlogd][svlogd]. See the [svlogd documentation][svlogd] for more information
about the files it generates.

You can modify svlogd settings via `/etc/gitlab/gitlab.rb` with the following settings:

```ruby
# Below are the default values
logging['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
logging['svlogd_num'] = 30 # keep 30 rotated log files
logging['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
logging['svlogd_filter'] = "gzip" # compress logs with gzip
logging['svlogd_udp'] = nil # transmit log messages via UDP
logging['svlogd_prefix'] = nil # custom prefix for log messages

# Optionally, you can override the prefix for e.g. Nginx
nginx['svlogd_prefix'] = "nginx"
```

### Logrotate

Starting with omnibus-gitlab 7.4 there is a built-in logrotate service in
omnibus-gitlab. This service will rotate, compress and eventually delete the
log data that is not captured by Runit, such as `gitlab-rails/production.log`
and `nginx/gitlab_access.log`. You can configure logrotate via
`/etc/gitlab/gitlab.rb`.

```
# Below are some of the default settings
logging['logrotate_frequency'] = "daily" # rotate logs daily
logging['logrotate_size'] = nil # do not rotate by size by default
logging['logrotate_rotate'] = 30 # keep 30 rotated logs
logging['logrotate_compress'] = "compress" # see 'man logrotate'
logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
logging['logrotate_postrotate'] = nil # no postrotate command by default

# You can add overrides per service
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"

# You can also disable the built-in logrotate service if you want
logrotate['enable'] = false
```

### UDP log shipping (GitLab Enterprise Edition only)

You can configure omnibus-gitlab to send syslog-ish log messages via UDP.

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

Example log messages:

```
<13>Jun 26 06:33:46 ubuntu1204-test production.log: Started GET "/root/my-project/import" for 127.0.0.1 at 2014-06-26 06:33:46 -0700
<13>Jun 26 06:33:46 ubuntu1204-test production.log: Processing by ProjectsController#import as HTML
<13>Jun 26 06:33:46 ubuntu1204-test production.log: Parameters: {"id"=>"root/my-project"}
<13>Jun 26 06:33:46 ubuntu1204-test production.log: Completed 200 OK in 122ms (Views: 71.9ms | ActiveRecord: 12.2ms)
<13>Jun 26 06:33:46 ubuntu1204-test gitlab_access.log: 172.16.228.1 - - [26/Jun/2014:06:33:46 -0700] "GET /root/my-project/import HTTP/1.1" 200 5775 "https://172.16.228.169/root/my-project/import" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
2014-06-26_13:33:46.49866 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7nbj0 Sidekiq::Extensions::DelayedMailer JID-bbfb118dd1db20f6c39f5b50 INFO: start

2014-06-26_13:33:46.52608 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7muoc RepositoryImportWorker JID-57ee926c3655fcfa062338ae INFO: start

```

## Starting a Rails console session

If you need access to a Rails production console for your GitLab installation
you can start one with the command below. Please be warned that it is very easy
to inadvertently modify, corrupt or destroy data from the console.

```shell
# start a Rails console for GitLab
sudo gitlab-rails console

# start a Rails console for GitLab CI
sudo gitlab-ci-rails console
```

This will only work after you have run `gitlab-ctl reconfigure` at least once.

## Using a MySQL database management server (Enterprise Edition only)

See [doc/settings/database.md](doc/settings/database.md).

### Create a user and database for GitLab

See [doc/settings/database.md](doc/settings/database.md).

### Configure omnibus-gitlab to connect to it

See [doc/settings/database.md](doc/settings/database.md).

### Seed the database (fresh installs only)

See [doc/settings/database.md](doc/settings/database.md).

## Only start omnibus-gitlab services after a given filesystem is mounted

If you want to prevent omnibus-gitlab services (nginx, redis, unicorn etc.)
from starting before a given filesystem is mounted, add the following to
`/etc/gitlab/gitlab.rb`:

```ruby
# wait for /var/opt/gitlab to be mounted
high_availability['mountpoint'] = '/var/opt/gitlab'
```

## Building your own package

See [the separate build documentation](doc/build.md).

## Running a custom GitLab version

It is not recommended to make changes to any of the files in `/opt/gitlab`
after installing omnibus-gitlab: they will either conflict with or be
overwritten by future updates. If you want to run a custom version of GitLab
you can [build your own package](doc/build.md) or use [another installation
method][CE README].

## Acknowledgments

This omnibus installer project is based on the awesome work done by Chef in
[omnibus-chef-server][omnibus-chef-server].

[downloads]: https://about.gitlab.com/downloads/
[CE README]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md
[omnibus-chef-server]: https://github.com/opscode/omnibus-chef-server
[database.yml.mysql]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/database.yml.mysql
[svlogd]: http://smarden.org/runit/svlogd.8.html
[installation]: https://about.gitlab.com/installation/
[gitlab.rb.template]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template
