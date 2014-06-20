# GitLab Omnibus project

This project creates full-stack platform-specific [downloadable packages for GitLab][downloads].
For other installation options please see the
[GitLab project README][CE README].

## Documentation version

Please make sure you are viewing the documentation for the version of
omnibus-gitlab you are using. In most cases this should be the highest numbered
stable branch (example shown below).

![documentation version](doc/images/omnibus-documentation-version.png)

## Installation

Please [download the package][downloads] and follow the steps below.

### Ubuntu 12.04

```
sudo apt-get install openssh-server
sudo apt-get install postfix # sendmail or exim is also OK
sudo dpkg -i gitlab_x.y.z-omnibus-x.ubuntu.12.04_amd64.deb # this is the .deb you downloaded
sudo gitlab-ctl reconfigure
```

### Debian 7.4
```
sudo apt-get install openssh-server
sudo apt-get install exim4-daemon-light
sudo dpkg -i gitlab-x.y.z.deb # this is the .deb you downloaded
sudo gitlab-ctl reconfigure
```

during the exim installation you may follow http://alexatnet.com/references/server-setup-debian/send-only-mail-server-with-exim to ensure you get a secure mailserver

### CentOS 6.5

```
sudo yum install openssh-server
sudo yum install postfix # sendmail or exim is also OK
sudo rpm -i gitlab-x.y.z_omnibus-x.el6.x86_64.rpm # this is the .rpm you downloaded
sudo gitlab-ctl reconfigure
sudo lokkit -s http -s ssh # open up the firewall for HTTP and SSH requests
```

### After installation

Run `sudo gitlab-ctl status`; the output should look like this:

```
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: unicorn: (pid 961) 7s; run: log: (pid 960) 7s
```

Your GitLab instance should reachable over HTTP at the IP or hostname of your server.
You can login as an admin user with username `root` and password `5iveL!fe`.

### Common installation problems

#### GitLab is unreachable in my browser

Try [specifying](#configuring-the-external-url-for-gitlab) an `external_url` in
`/etc/gitlab/gitlab.rb`. Also check your firewall settings; port 80 (HTTP) or
443 (HTTPS) might be closed on your GitLab server.

#### Reconfigure freezes at `ruby_block[supervise_redis_sleep] action run`

This happens when Runit has not been installed succesfully during `gitlab-ctl
reconfigure`. The most common cause for a failed Runit installation is
installing omnibus-gitlab on an unsupported platform. Solution: double check on
the download page whether you downloaded a package for the correct operating
system.

#### TCP ports for GitLab services are already taken

By default, the services in omnibus-gitlab are using the following TCP ports:
Redis (6379), PostgreSQL (5432) and Unicorn (8080) listen on 127.0.0.1. Nginx
listens on port 80 (HTTP) and/or 443 (HTTPS) on all interfaces.

The ports for Redis, PostgreSQL and Unicorn can be overriden in
`/etc/gitlab/gitlab.rb` as follows:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
unicorn['port'] = 3456
```

For Nginx port changes please see the section on enabling HTTPS below.

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

By default, omnibus-gitlab stores Git repository data in `/var/opt/gitlab/git-data`.
You can change this location by adding the following line to `/etc/gitlab/gitlab.rb`.

```ruby
git_data_dir "/mnt/nas/git-data"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

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

If you have an LDAP directory service such as Active Directory, you can configure
GitLab so that your users can sign in with their LDAP credentials. Add the following
to `/etc/gitlab/gitlab.rb`, edited for your server.

```ruby
# These settings are documented in more detail at
# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example#L118
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_host'] = 'hostname of LDAP server'
gitlab_rails['ldap_port'] = 389
gitlab_rails['ldap_uid'] = 'sAMAccountName'
gitlab_rails['ldap_method'] = 'plain' # 'ssl' or 'plain'
gitlab_rails['ldap_bind_dn'] = 'CN=query user,CN=Users,DC=mycorp,DC=com'
gitlab_rails['ldap_password'] = 'query user password'
gitlab_rails['ldap_allow_username_or_email_login'] = true
gitlab_rails['ldap_base'] = 'DC=mycorp,DC=com'

# GitLab Enterprise Edition only
gitlab_rails['ldap_group_base'] = '' # Example: 'OU=groups,DC=mycorp,DC=com'
gitlab_rails['ldap_user_filter'] = '' # Example: '(memberOf=CN=my department,OU=groups,DC=mycorp,DC=com)'
```

Run `sudo gitlab-ctl reconfigure` for the LDAP settings to take effect.

### Enable HTTPS

By default, omnibus-gitlab runs does not use HTTPS.  If you want to enable HTTPS you can add the
following line to `/etc/gitlab/gitlab.rb`.

```ruby
external_url "https://gitlab.example.com"
```

Redirect `HTTP` requests to `HTTPS`.

```ruby
external_url "https://gitlab.example.com"
nginx['redirect_http_to_https'] = true
```

Change the default port and the ssl certificate locations.

```ruby
external_url "https://gitlab.example.com:2443"
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.key"
```

Create the default ssl certifcate directory and add the files:

```
sudo mkdir -p /etc/gitlab/ssl && sudo chmod 700 /etc/gitlab/ssl
sudo cp gitlab.example.com.crt gitlab.example.com.key /etc/gitlab/ssl/
# run lokkit to open https on the firewall
sudo lokkit -s https
# if you are using a non standard https port
sudo lokkit -p 2443:tcp
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Changing gitlab.yml settings

Some of GitLab's features can be customized through
[gitlab.yml][gitlab.yml.example]. If you want to change a `gitlab.yml` setting
with omnibus-gitlab, you need to do so via `/etc/gitlab/gitlab.rb`. The
translation works as follows.

In `gitlab.yml`, you will find structure like this:

```yaml
production: &base
  gitlab:
    default_projects_limit: 10
```

In `gitlab.rb`, this translates to:

```ruby
gitlab_rails['gitlab_default_projects_limit'] = 10
```

What happens here is that we forget about `production: &base`, and join
`gitlab:` with `default_projects_limit:` into `gitlab_default_projects_limit`.
Note that not all `gitlab.yml` settings can be changed via `gitlab.rb` yet; see
the [gitlab.yml ERB template][gitlab.yml.erb].  If you think an attribute is
missing please create a merge request on the omnibus-gitlab repository.

Run `sudo gitlab-ctl reconfigure` for changes in `gitlab.rb` to take effect.

Do not edit the generated file in `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`
since it will be overwritten on the next `gitlab-ctl reconfigure` run.

### Specify numeric user and group identifiers

Omnibus-gitlab creates users for GitLab, PostgreSQL and Redis. You can specify
the numeric identifiers for these users in `/etc/gitlab/gitlab.rb` as follows.

```ruby
user['uid'] = 1234
user['gid'] = 1234
postgresql['uid'] = 1235
postgresql['gid'] = 1235
redis['uid'] = 1236
redis['gid'] = 1236
```

### Storing user attachments on Amazon S3

Instead of using local storage you can also store the user attachments for your
GitLab instance on Amazon S3.

__This currently only works if you are packaging a forked version of GitLab.__

```
# /etc/gitlab/gitlab.rb
gitlab_rails['aws_enable'] = true
gitlab_rails['aws_access_key_id'] = 'AKIA1111111111111UA'
gitlab_rails['aws_secret_access_key'] = 'secret'
gitlab_rails['aws_bucket'] = 'my_gitlab_bucket'
gitlab_rails['aws_region'] = 'us-east-1'
```

### Sending application email via SMTP

If you would rather send email via an SMTP server instead of via Sendmail, add
the following configuration information to `/etc/gitlab/gitlab.rb` and run
`gitlab-ctl reconfigure`.

```
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.server"
gitlab_rails['smtp_port'] = 456
gitlab_rails['smtp_user_name'] = "smtp user"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented on
[doc.gitlab.com](http://doc.gitlab.com/ce/integration/omniauth.html). To effect
the necessary changes in `gitlab.yml`, use the following syntax in
`/etc/gitlab/gitlab.rb`. Note that the providers are specified as an array of
Ruby hashes.

```ruby
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_providers'] = [
  {
    "name" => "google_oauth2",
    "app_id" => "YOUR APP ID",
    "app_secret" => "YOUR APP SECRET",
    "args" => { "access_type" => "offline", "approval_prompt" => "" }
  }
]
```

## Backups

### Creating an application backup

To create a backup of your repositories and GitLab metadata, run the following command.

```shell
sudo gitlab-rake gitlab:backup:create
```

This will store a tar file in `/var/opt/gitlab/backups`. The filename will look like
`1393513186_gitlab_backup.tar`, where 1393513186 is a timestamp.

### Scheduling a backup

To schedule a cron job that backs up your repositories and GitLab metadata, use the root user:

```
sudo su -
crontab -e
```

There, add the following line to schedule the backup for everyday at 2 AM:

```
0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create
```

### Restoring an application backup

We will assume that you have installed GitLab from an omnibus package and run
`sudo gitlab-ctl reconfigure` at least once.

First make sure your backup tar file is in `/var/opt/gitlab/backups`.

```shell
sudo cp 1393513186_gitlab_backup.tar /var/opt/gitlab/backups/
```

Next, restore the backup by running the restore command. You need to specify the
timestamp of the backup you are restoring.

```shell
# Stop processes that are connected to the database
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# DROP THE CURRENT DATABASE; workaround for a Postgres backup restore bug in GitLab 6.6
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production
# This command will overwrite the contents of your GitLab database!
sudo gitlab-rake gitlab:backup:restore BACKUP=1393513186

# Start GitLab
sudo gitlab-ctl start
```

If there is a GitLab version mismatch between your backup tar file and the installed
version of GitLab, the restore command will abort with an error. Install a package for
the [required version](https://www.gitlab.com/downloads/archives/) and try again.

## Invoking Rake tasks

To invoke a GitLab Rake task, use `gitlab-rake`. For example:

```shell
sudo gitlab-rake gitlab:check
```

Contrary to with a traditional GitLab installation, there is no need to change
the user or the `RAILS_ENV` environment variable; this is taken care of by the
`gitlab-rake` wrapper script.

## Directory structure

Omnibus-gitlab uses four different directories.

- `/opt/gitlab` holds application code for GitLab and its dependencies.
- `/var/opt/gitlab` holds application data and configuration files that
  `gitlab-ctl reconfigure` writes to.
- `/etc/gitlab` holds configuration files for omnibus-gitlab. These are
  the only files that you should ever have to edit manually.
- `/var/log/gitlab` contains all log data generated by components of
  omnibus-gitlab.

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

## Starting a Rails console session

If you need access to a Rails production console for your GitLab installation
you can start one with the command below. Please be warned that it is very easy
to inadvertently modify, corrupt or destroy data from the console.

```shell
sudo /opt/gitlab/bin/gitlab-rails console
```

This will only work after you have run `gitlab-ctl reconfigure` at least once.

## Using a MySQL database management server (Enterprise Edition only)

If you want to use MySQL and are using the **GitLab Enterprise Edition packages** please do the following:

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
```

Parameters such as `db_adapter` correspond to `adapter` in `database.yml`; see the upstream GitLab for a [MySQL configuration example][database.yml.mysql].
We remind you that `/etc/gitlab/gitlab.rb` should have file permissions `0600` because it contains plaintext passwords.

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Seed the database (fresh installs only)

Omnibus-gitlab will not automatically seed your external database. Run the
following command to import the schema and create the first admin user:

```shell
sudo gitlab-rake gitlab:setup
```

This is a destructive command; do not run it on an existing database!

## Using a non-packaged PostgreSQL database management server

If you do do not want to use the packaged Postgres server you can configure an external one similar to configuring a MySQL server (shown above).
Configuring a PostgreSQL server is possible both with GitLab Community Edition and Enterprise Edition packages.
Please see the upstream GitLab for a [PostgreSQL configuration example][database.yml.postgresql].

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

[downloads]: https://www.gitlab.com/downloads
[CE README]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md
[omnibus-chef-server]: https://github.com/opscode/omnibus-chef-server
[gitlab.yml.erb]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb
[database.yml.postgresql]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/database.yml.postgresql
[database.yml.mysql]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/database.yml.mysql
[gitlab.yml.example]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
[svlogd]: http://smarden.org/runit/svlogd.8.html
