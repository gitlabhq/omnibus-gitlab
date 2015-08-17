# Configuration options

GitLab and GitLab CI are configured by setting their relevant options in
`/etc/gitlab/gitlab.rb`. For a complete list of available options, visit the
[gitlab.rb.template][]. New installations starting from GitLab 7.6, will have
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

### Storing Git data in an alternative directory

By default, Omnibus-GitLab stores Git repository data under
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

By default, Omnibus-GitLab uses the user name `git` for Git GitLab-shell login,
ownership of the Git data itself, and SSH URL generation on the web interface.
Similarly, `git` group is used for group ownership of the Git data.  You can
change the user and group by adding the following lines to
`/etc/gitlab/gitlab.rb`.

```ruby
user['username'] = "gitlab"
user['group'] = "gitlab"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Specify numeric user and group identifiers

Omnibus-GitLab creates users for GitLab, PostgreSQL, Redis and NGINX. You can
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

## Only start Omnibus-GitLab services after a given filesystem is mounted

If you want to prevent Omnibus-GitLab services (NGINX, Redis, Unicorn etc.)
from starting before a given filesystem is mounted, add the following to
`/etc/gitlab/gitlab.rb`:

```ruby
# wait for /var/opt/gitlab to be mounted
high_availability['mountpoint'] = '/var/opt/gitlab'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Setting up LDAP sign-in

See [LDAP](ldap.md).

### Enable HTTPS

See [NGINX](nginx.md#enable-https).

#### Redirect `HTTP` requests to `HTTPS`.

See [NGINX](nginx.md#redirect-http-requests-to-https).

#### Change the default port and the ssl certificate locations.

See [NGINX](nginx.md#change-the-default-port-and-the-ssl-certificate-locations).

### Use non-packaged web-server

For using an existing Nginx, Passenger, or Apache webserver see [NGINX](nginx.md#using-a-non-bundled-web-server).

## Using a non-packaged PostgreSQL database management server

To connect to an external PostgreSQL or MySQL DBMS see [database](database.md) (MySQL support in the Omnibus Packages is Enterprise Only).

## Using a non-packaged Redis instance

See [Redis](redis.md).

### Adding ENV Vars to the GitLab Runtime Environment

See
[environment-variables](environment-variables.md).

### Changing GitLab.yml settings

See [GitLab.yml](gitlab.yml.md).

### Sending application email via SMTP

See [SMTP](smtp.md).

### Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented in
[doc.GitLab.com](http://doc.gitlab.com/ce/integration/omniauth.html).

### Adjusting Unicorn settings

See [Unicorn](unicorn.md).

### Setting the NGINX listen address or addresses

See [NGINX](nginx.md).

### Inserting custom NGINX settings into the GitLab server block

See [NGINX](nginx.md).

### Inserting custom settings into the NGINX config

See [NGINX](nginx.md).
