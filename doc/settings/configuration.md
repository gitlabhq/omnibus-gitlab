# Configuration options

GitLab is configured by setting the relevant options in
`/etc/gitlab/gitlab.rb`. See [package defaults](../package-information/defaults.md)
for a list of default settings and visit the
[gitlab.rb.template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
for a complete list of available options.
New installations starting from GitLab 7.6, will have
all the options of the template as of installation listed in
`/etc/gitlab/gitlab.rb` by default.

## Configuring the external URL for GitLab

In order for GitLab to display correct repository clone links to your users
it needs to know the URL under which it is reached by your users, e.g.
`http://gitlab.example.com`. Add or edit the following line in
`/etc/gitlab/gitlab.rb`:

```ruby
external_url "http://gitlab.example.com"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Configuring a relative URL for Gitlab

_**Note:** Relative URL support in Omnibus GitLab is **experimental** and was
[introduced][590] in version 8.5. For source installations there is a
[separate document](https://docs.gitlab.com/ce/install/relative_url.html)._

---

While it is recommended to install GitLab in its own (sub)domain, sometimes
this is not possible due to a variety of reasons. In that case, GitLab can also
be installed under a relative URL, for example `https://example.com/gitlab`.

Note that by changing the URL, all remote URLS will change, so you'll have to
manually edit them in any local repository that points to your GitLab instance.

### Relative URL requirements

_Starting with 8.17 packages, there is **no need to recompile assets**._

The Omnibus GitLab package is shipped with pre-compiled assets (CSS, JavaScript,
fonts, etc.). If you are running a package _prior to 8.17_ and you configure
Omnibus with a relative URL, the assets will need to be recompiled, which is a
task which consumes a lot of CPU and memory resources. To avoid out-of-memory
errors, you should have at least 2GB of RAM available on your system, while we
recommend 4GB RAM, and 4 or 8 CPU cores.

### Enable relative URL in GitLab

Follow the steps below to enable relative URL in GitLab:

1.  (Optional) If you run short on resources, you can temporarily free up some
    memory by shutting down Unicorn and Sidekiq with the following command:

    ```shell
    sudo gitlab-ctl stop unicorn
    sudo gitlab-ctl stop sidekiq
    ```

1.  Set the `external_url` in `/etc/gitlab/gitlab.rb`:

    ```ruby
    external_url "https://example.com/gitlab"
    ```

    In this example, the relative URL under which GitLab will be served will be
    `/gitlab`. Change it to your liking.

1.  Reconfigure GitLab for the changes to take effect:

    ```shell
    sudo gitlab-ctl reconfigure
    ```

1.  Restart the services so that Unicorn and Sidekiq picks up the changes

    ```shell
    sudo gitlab-ctl restart
    ```

If you stumble upon any issues, see the [troubleshooting section]
(#relative-url-troubleshooting).

### Disable relative URL in GitLab

To disable the relative URL, follow the same steps as above and set up the
`external_url` to a one that doesn't contain a relative path. You may need to
explicitly restart Unicorn after the reconfigure task is done:

```shell
sudo gitlab-ctl restart unicorn
```

If you stumble upon any issues, see the [troubleshooting section]
(#relative-url-troubleshooting).

### Relative URL troubleshooting

If you notice any issues with gitlab assets appearing broken after moving to a
relative url configuration (like missing images or unresponsive components)
please raise an issue in [GitLab CE](https://gitlab.com/gitlab-org/gitlab-ce)
with the `Frontend` label.

If you are running a version _prior to 8.17_ and for some reason the asset
compilation step fails (i.e. the server runs out of memory), you can execute
the task manually after you addressed the issue (e.g. add swap):

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake assets:clean assets:precompile
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

User and path might be different if you changed the defaults of
`user['username']`, `user['group']` and `gitlab_rails['dir']` in `gitlab.rb`.
In that case, make sure that the `chown` command above is run with the right
username and group.

[590]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/590 "Merge request - Relative url support for omnibus installations"

## Loading external configuration file from non-root user

Omnibus-gitlab package loads all configuration from `/etc/gitlab/gitlab.rb` file.
This file has strict file permissions and is owned by the `root` user. The reason for strict permissions
and ownership is that `/etc/gitlab/gitlab.rb` is being executed as Ruby code by the `root` user during `gitlab-ctl reconfigure`. This means
that users who have write access to `/etc/gitlab/gitlab.rb` can add configuration that will be executed as code by `root`.

In certain organizations it is allowed to have access to the configuration files but not as the root user.
You can include an external configuration file inside `/etc/gitlab/gitlab.rb` by specifying the path to the file:

```ruby
from_file "/home/admin/external_gitlab.rb"

```

Please note that code you include into `/etc/gitlab/gitlab.rb` using `from_file` will run with `root` privileges when you run `sudo gitlab-ctl reconfigure`.
Any configuration that is set in `/etc/gitlab/gitlab.rb` after `from_file` is included will take precedence over the configuration from the included file.

## Storing Git data in an alternative directory

By default, omnibus-gitlab stores the Git repository data under
`/var/opt/gitlab/git-data`. The repositories are stored in a subfolder
`repositories`. You can change the location of
the `git-data` parent directory by adding the following line to
`/etc/gitlab/gitlab.rb`.

```ruby
git_data_dirs({ "default" => { "path" => "/mnt/nas/git-data" } })
```

You can also add more than one git data directory by
adding the following lines to `/etc/gitlab/gitlab.rb` instead.

```ruby
git_data_dirs({
  "default" => { "path" => "/var/opt/gitlab/git-data" },
  "alternative" => { "path" => "/mnt/nas/git-data" }
})
```

If you're running Gitaly on its own server remember to also include the
`gitaly_address` for each git data directory. See [the documentation on
configuring Gitaly](https://docs.gitlab.com/ee/administration/gitaly/#gitaly-server-configuration).

Note that the target directories and any of its subpaths must not be a symlink.

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

If you already have existing Git repositories in `/var/opt/gitlab/git-data` you
can move them to the new location as follows:

```shell
# Prevent users from writing to the repositories while you move them.
sudo gitlab-ctl stop

# Note there is _no_ slash behind 'repositories', but there _is_ a
# slash behind 'git-data'.
sudo rsync -av /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/

# Start the necessary processes and run reconfigure to fix permissions
# if necessary
sudo gitlab-ctl upgrade

# Double-check directory layout in /mnt/nas/git-data. Expected output:
# repositories
sudo ls /mnt/nas/git-data/

# Done! Start GitLab and verify that you can browse through the repositories in
# the web interface.
sudo gitlab-ctl start
```

## Changing the name of the Git user / group

By default, omnibus-gitLab uses the user name `git` for Git gitlab-shell login,
ownership of the Git data itself, and SSH URL generation on the web interface.
Similarly, `git` group is used for group ownership of the Git data.

We do not recommend changing the user/group of an existing installation because it can cause unpredictable side-effects.
If you still want to do change the user and group, you can do so by adding the following lines to
`/etc/gitlab/gitlab.rb`.

```ruby
user['username'] = "gitlab"
user['group'] = "gitlab"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

Note that if you are changing the username of an existing installation, the reconfigure run won't change the ownership of the nested directories so you will have to do that manually. Make sure that the new user can access `repositories` as well as the `uploads` directory.

## Specify numeric user and group identifiers

omnibus-gitlab creates users for GitLab, PostgreSQL, Redis and NGINX. You can
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

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## Disable user and group account management

By default, omnibus-gitlab takes care of creating system user and group accounts
as well as keeping the information updated.
These system accounts run various components of the package.
Most users do not need to change this behaviour.
However, if your system accounts are managed by other software, eg. LDAP, you
might need to disable account management done by the package.

In order to disable user and group accounts management, in `/etc/gitlab/gitlab.rb` set:

```ruby
manage_accounts['enable'] = false
```

*Warning* Omnibus-gitlab still expects users and groups to exist on the system where omnibus-gitlab package is installed.

By default, omnibus-gitlab package expects that following users exist:


```bash
# GitLab user (required)
git

# Web server user (required)
gitlab-www

# Redis user for GitLab (only when using packaged Redis)
gitlab-redis

# Postgresql user (only when using packaged Postgresql)
gitlab-psql

# Prometheus user for prometheus monitoring and various exporters
gitlab-prometheus

# GitLab Mattermost user (only when using GitLab Mattermost)
mattermost

# GitLab Registry user (only when using GitLab Registry)
registry

# GitLab Consul user (only when using GitLab Consul)
gitlab-consul
```

By default, omnibus-gitlab package expects that following groups exist:

```bash
# GitLab group (required)
git

# Web server group (required)
gitlab-www

# Redis group for GitLab (only when using packaged Redis)
gitlab-redis

# Postgresql group (only when using packaged Postgresql)
gitlab-psql

# Prometheus user for prometheus monitoring and various exporters
gitlab-prometheus

# GitLab Mattermost group (only when using GitLab Mattermost)
mattermost

# GitLab Registry group (only when using GitLab Registry)
registry

# GitLab Consul group (only when using GitLab Consul)
gitlab-consul
```

You can also use different user/group names but then you must specify user/group details in `/etc/gitlab/gitlab.rb`, eg.

```ruby
# Do not manage user/group accounts
manage_accounts['enable'] = false

# GitLab
user['username'] = "custom-gitlab"
user['group'] = "custom-gitlab"
user['shell'] = "/bin/sh"
user['home'] = "/var/opt/custom-gitlab"

# Web server
web_server['username'] = 'webserver-gitlab'
web_server['group'] = 'webserver-gitlab'
web_server['shell'] = '/bin/false'
web_server['home'] = '/var/opt/gitlab/webserver'

# Postgresql (not needed when using external Postgresql)
postgresql['username'] = "postgres-gitlab"
postgresql['shell'] = "/bin/sh"
postgresql['home'] = "/var/opt/postgres-gitlab"

# Redis (not needed when using external Redis)
redis['username'] = "redis-gitlab"
redis['shell'] = "/bin/false"
redis['home'] = "/var/opt/redis-gitlab"

# And so on for users/groups for GitLab Mattermost
```

## Disable storage directories management

The omnibus-gitlab package takes care of creating all the necessary directories
with the correct ownership and permissions, as well as keeping this updated.

Some of these directories will hold large amount of data so in certain setups,
these directories will most likely be mounted on a NFS (or some other) share.

Some types of mounts won't allow automatic creation of directories by root user
 (default user for initial setup), eg. NFS with `root_squash` enabled on the
share. To work around this the omnibus-gitlab package will attempt to create
these directories using the directory's owner user.

If you have the `/etc/gitlab` directory mounted, you can turn off management of
that directory.

In `/etc/gitlab/gitlab.rb` set:

```ruby
manage_storage_directories['manage_etc'] = false
```

If you are mounting all GitLab's storage directories, each on a seperate mount,
you should completely disable the management of storage directories.

In order to disable management of these directories,
in `/etc/gitlab/gitlab.rb` set:

```ruby
manage_storage_directories['enable'] = false
```

**Warning** The omnibus-gitlab package still expects these directories to exist
on the filesystem. It is up to the administrator to create and set correct
permissions if this setting is set.

Enabling this setting will prevent the creation of the following directories:

| Default location | Permissions | Ownership | Purpose |
| ---------------- | ----------- | --------- | ------- |
| `/var/opt/gitlab/git-data`   | 0700 | git:root | Holds repositories directory |
| `/var/opt/gitlab/git-data/repositories` | 2770 | git:git | Holds git repositories |
| `/var/opt/gitlab/gitlab-rails/shared` | 0751 | git:gitlab-www | Holds large object directories |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts` | 0700 | git:root | Holds CI artifacts |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects` | 0700 | git:root | Holds LFS objects |
| `/var/opt/gitlab/gitlab-rails/uploads` | 0700 | git:root | Holds user attachments |
| `/var/opt/gitlab/gitlab-rails/shared/pages` | 0750 | git:gitlab-www | Holds user pages |
| `/var/opt/gitlab/gitlab-ci/builds` | 0700 | git:root | Holds CI build logs |
| `/var/opt/gitlab/.ssh` | 0700 | git:git | Holds authorized keys |



## Only start Omnibus-GitLab services after a given filesystem is mounted

If you want to prevent omnibus-gitlab services (NGINX, Redis, Unicorn etc.)
from starting before a given filesystem is mounted, add the following to
`/etc/gitlab/gitlab.rb`:

```ruby
# wait for /var/opt/gitlab to be mounted
high_availability['mountpoint'] = '/var/opt/gitlab'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Configuring runtime directory

When Prometheus monitoring is enabled, GitLab-monitor will conduct measurements
of each Unicorn process (Rails metrics). Every Unicorn process will need to write
a metrics file to a temporary location for each controller request.
Prometheus will then collect all these files and process their values.

In order to avoid creating disk I/O, the omnibus-gitlab package will use a
runtime directory.

During `reconfigure`, package will check if `/run` is a `tmpfs` mount.
If it is not, warning will be printed:

```
Runtime directory '/run' is not a tmpfs mount.
```

and Rails metrics will be disabled.

To enable Rails metrics again, create a `tmpfs` mount and specify it in `/etc/gitlab/gitlab.rb`:

```
runtime_dir '/path/to/tmpfs'
```

*Please note that there is no `=` in the configuration.*

Run `sudo gitlab-ctl reconfigure` for the settings to take effect.

## Configuring Rack Attack

To prevent abusive clients doing damage, GitLab uses the Rack Attack gem.
Check [this page](https://docs.gitlab.com/ee/security/rack_attack.html)
for more information.

## Disabling automatic cache cleaning during installation

If you have large gitlab installation, you might not want to run `rake cache:clean` task.
As it can take long time to finish. By default, cache clear task will run automatically
during reconfigure.

Edit `/etc/gitlab/gitlab.rb`:

```ruby
# This is advanced feature used by large gitlab deployments where loading
# whole RAILS env takes a lot of time.
gitlab_rails['rake_cache_clear'] = false
```

Don't forget to remove the `#` comment characters at the beginning of this
line.

### Enabling/Disabling Rack Attack and setting up basic auth throttling

Next configuration settings control Rack Attack:

```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true, # Enable/Disable Rack Attack
  'ip_whitelist' => ["127.0.0.1"], # Whitelisted urls
  'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
  'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
  'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
}
```

### Setting up paths to be protected by Rack Attack

If you want to change default protected paths
set `gitlab_rails['rack_attack_protected_paths']` in config file.

**Warning** This action will overwrite
list provided by omnibus-gitlab:

```ruby
gitlab_rails['rack_attack_protected_paths'] = [
  '/users/password',
  '/users/sign_in',
  '/api/#{API::API.version}/session.json',
  '/api/#{API::API.version}/session',
  '/users',
  '/users/confirmation',
  '/unsubscribes/',
  '/import/github/personal_access_token'
]
```

_**Note:** All paths are relative to the gitlab url._
Do not include [relative URL](configuration.md#configuring-a-relative-url-for-gitlab) if you set it up.

**Warning** If path contains variables which need to be
interpolated by rails(ex. `#{API::API.version}`)
then you need to escape curly brackets or use single quoted string.
For example `"/api/#\{API::API.version\}/session.json"` or `'/api/#{API::API.version}/session.json'`


### Setting up throttling for 'paths to be protected'
Use next options to control throttling 'limit' and 'period':

```ruby
gitlab_rails['rate_limit_requests_per_period'] = 10
gitlab_rails['rate_limit_period'] = 60
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Setting up LDAP sign-in

See [doc/settings/ldap.md](ldap.md).

## Enable HTTPS

See [doc/settings/nginx.md](nginx.md#enable-https).

### Redirect `HTTP` requests to `HTTPS`.

See [doc/settings/nginx.md](nginx.md#redirect-http-requests-to-https).

### Change the default port and the ssl certificate locations.

See
[doc/settings/nginx.md](nginx.md#change-the-default-port-and-the-ssl-certificate-locations).

## Use non-packaged web-server

For using an existing Nginx, Passenger, or Apache webserver see [doc/settings/nginx.md](nginx.md#using-a-non-bundled-web-server).

## Using a non-packaged PostgreSQL database management server

To connect to an external PostgreSQL or MySQL DBMS see [doc/settings/database.md](database.md) (MySQL support in the Omnibus Packages is Enterprise Only).

## Using a non-packaged Redis instance

See [doc/settings/redis.md](redis.md).

## Adding ENV Vars to the GitLab Runtime Environment

See
[doc/settings/environment-variables.md](environment-variables.md).

## Changing GitLab.yml settings

See [doc/settings/gitlab.yml.md](gitlab.yml.md).

## Sending application email via SMTP

See [doc/settings/smtp.md](smtp.md).

## Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented in
[docs.gitlab.com](https://docs.gitlab.com/ce/integration/omniauth.html).

## Adjusting Unicorn settings

See [doc/settings/unicorn.md](unicorn.md).

## Setting the NGINX listen address or addresses

See [doc/settings/nginx.md](nginx.md).

## Inserting custom NGINX settings into the GitLab server block

See [doc/settings/nginx.md](nginx.md).

## Inserting custom settings into the NGINX config

See [doc/settings/nginx.md](nginx.md).

## Enable nginx_status

See [doc/settings/nginx.md](nginx.md).

## Pseudonymizer settings

Pseudonymizer configuration is documented in
[docs.gitlab.com](https://docs.gitlab.com/ee/administration/pseudonymizer.html).
