# Configuration options

GitLab and GitLab CI are configured by setting their relevant options in
`/etc/gitlab/gitlab.rb`. For a complete list of available options, visit the
[gitlab.rb.template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
New installations starting from GitLab 7.6, will have
all the options of the template listed in `/etc/gitlab/gitlab.rb` by default.


### Configuring the external URL for GitLab

In order for GitLab to display correct repository clone links to your users
it needs to know the URL under which it is reached by your users, e.g.
`http://gitlab.example.com`. Add or edit the following line in
`/etc/gitlab/gitlab.rb`:

```ruby
external_url "http://gitlab.example.com"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Loading external configuration file from non-root user

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

Note that the target directory and any of its subpaths must not be a symlink.

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

### Specify numeric user and group identifiers

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

### Disable user and group account management

By default, omnibus-gitlab takes care of user and group accounts creation as well as keeping the accounts information updated.
This behaviour makes sense for most users but in certain environments user and group accounts are managed by other software, eg. LDAP.

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

# Redis user for GitLab or GitLab CI (only when using packaged Redis)
gitlab-redis

# Postgresql user (only when using packaged Postgresql)
gitlab-psql

# GitLab CI user (only when using GitLab CI)
gitlab-ci

# GitLab Mattermost user (only when using GitLab Mattermost)
mattermost
```

By default, omnibus-gitlab package expects that following groups exist:

```bash
# GitLab group (required)
git

# Web server group (required)
gitlab-www

# Redis group for GitLab or GitLab CI (only when using packaged Redis)
gitlab-redis

# Postgresql group (only when using packaged Postgresql)
gitlab-psql

# GitLab CI group (only when using GitLab CI)
gitlab-ci

# GitLab Mattermost group (only when using GitLab Mattermost)
mattermost
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

# And so on for users/groups for GitLab CI GitLab Mattermost
```

## Only start Omnibus-GitLab services after a given filesystem is mounted

If you want to prevent omnibus-gitlab services (NGINX, Redis, Unicorn etc.)
from starting before a given filesystem is mounted, add the following to
`/etc/gitlab/gitlab.rb`:

```ruby
# wait for /var/opt/gitlab to be mounted
high_availability['mountpoint'] = '/var/opt/gitlab'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Setting up LDAP sign-in

See [doc/settings/ldap.md](ldap.md).

### Enable HTTPS

See [doc/settings/nginx.md](nginx.md#enable-https).

#### Redirect `HTTP` requests to `HTTPS`.

See [doc/settings/nginx.md](nginx.md#redirect-http-requests-to-https).

#### Change the default port and the ssl certificate locations.

See
[doc/settings/nginx.md](nginx.md#change-the-default-port-and-the-ssl-certificate-locations).

### Use non-packaged web-server

For using an existing Nginx, Passenger, or Apache webserver see [doc/settings/nginx.md](nginx.md#using-a-non-bundled-web-server).

## Using a non-packaged PostgreSQL database management server

To connect to an external PostgreSQL or MySQL DBMS see [doc/settings/database.md](database.md) (MySQL support in the Omnibus Packages is Enterprise Only).

## Using a non-packaged Redis instance

See [doc/settings/redis.md](redis.md).

### Adding ENV Vars to the GitLab Runtime Environment

See
[doc/settings/environment-variables.md](environment-variables.md).

### Changing GitLab.yml settings

See [doc/settings/gitlab.yml.md](gitlab.yml.md).

### Sending application email via SMTP

See [doc/settings/smtp.md](smtp.md).

### Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented in
[doc.gitlab.com](http://doc.gitlab.com/ce/integration/omniauth.html).

### Adjusting Unicorn settings

See [doc/settings/unicorn.md](unicorn.md).

### Setting the NGINX listen address or addresses

See [doc/settings/nginx.md](nginx.md).

### Inserting custom NGINX settings into the GitLab server block

See [doc/settings/nginx.md](nginx.md).

### Inserting custom settings into the NGINX config

See [doc/settings/nginx.md](nginx.md).
