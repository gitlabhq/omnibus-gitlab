# Omnibus GitLab

## Description

This project creates full-stack platform-specific [downloadable packages for GitLab][downloads].
For other installation options please see the
[GitLab installation page][installation].

## Canonical source

The source of omnibus-gitlab is [hosted on
GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab) and there are mirrors
to make contributing as easy as possible.

## Documentation

The documentation overview is in the [readme in the doc directory](doc/README.md).

## Omnibus fork

Omnibus GitLab is using a fork of [omnibus project](https://github.com/chef/omnibus).  For additional information see the comments in the [Gemfile](/Gemfile).

## Deprecated links

*We left the links below in the readme to preserve old links, but please use the [readme in the doc directory](doc/README.md) to browse the complete documentation.*

## Contributing

Please see the [contribution guidelines](CONTRIBUTING.md)

## Installation

Please follow the steps on the [downloads page][downloads].

### After installation

Your GitLab instance should be reachable over HTTP at the IP or hostname of your
server. You can login as an admin user with username `root` and password `5iveL!fe`.

See [doc/maintenance/README.md](doc/maintenance/README.md) for useful commands
to control/debug your GitLab instance.

### Configuration options

See [doc/settings/configuration.md](doc/settings/configuration.md).

#### Configuring the external URL for GitLab

See [doc/settings/configuration.md](doc/settings/configuration.md#configuring-the-external-url-for-gitlab).

#### Storing Git data in an alternative directory

See [doc/settings/configuration.md](doc/settings/configuration.md#storing-git-data-in-an-alternative-directory).

#### Changing the name of the Git user / group

See [doc/settings/configuration.md](doc/settings/configuration.md#changing-the-name-of-the-git-user-group).

#### Setting up LDAP sign-in

See [doc/settings/ldap.md](doc/settings/ldap.md).

#### Enable HTTPS

See [doc/settings/nginx.md](doc/settings/nginx.md#enable-https).

#### Redirect `HTTP` requests to `HTTPS`

See [doc/settings/nginx.md](doc/settings/nginx.md#redirect-http-requests-to-https).

#### Change the default port and the ssl certificate locations

See [doc/settings/nginx.md](doc/settings/nginx.md#change-the-default-port-and-the-ssl-certificate-locations).

#### Use non-packaged web-server

For using an existing Nginx, Passenger, or Apache webserver see [doc/settings/nginx.md](doc/settings/nginx.md#using-a-non-bundled-web-server).

#### Using a non-packaged PostgreSQL database management server

To connect to an external PostgreSQL DBMS see [doc/settings/database.md](doc/settings/database.md)

#### Using a non-packaged Redis instance

See [doc/settings/redis.md](doc/settings/redis.md).

#### Adding ENV Vars to the Gitlab Runtime Environment

See
[doc/settings/environment-variables.md](doc/settings/environment-variables.md).

#### Changing gitlab.yml settings

See [doc/settings/gitlab.yml.md](doc/settings/gitlab.yml.md).

#### Specify numeric user and group identifiers

See [doc/settings/configuration.md](doc/settings/configuration.md#specify-numeric-user-and-group-identifiers).

#### Sending application email via SMTP

See [doc/settings/smtp.md](doc/settings/smtp.md).

#### Omniauth (Google, Twitter, GitHub login)

Omniauth configuration is documented in
[docs.gitlab.com](https://docs.gitlab.com/ee/integration/omniauth.html).

#### Adjusting Unicorn settings

See [doc/settings/unicorn.md](doc/settings/unicorn.md).

#### Setting the NGINX listen address or addresses

See [doc/settings/nginx.md](doc/settings/nginx.md).

#### Inserting custom NGINX settings into the GitLab server block

See [doc/settings/nginx.md](doc/settings/nginx.md).

#### Inserting custom settings into the NGINX config

See [doc/settings/nginx.md](doc/settings/nginx.md).

#### Only start omnibus-gitlab services after a given filesystem is mounted

See [doc/settings/configuration.md](doc/settings/configuration.md#only-start-omnibus-gitlab-services-after-a-given-filesystem-is-mounted).

### Updating

Instructions for updating your Omnibus installation and upgrading from a manual
installation are in the [update doc](doc/update/README.md).

### Uninstalling omnibus-gitlab

To remove [all users and groups created by Omnibus GitLab](doc/settings/configuration.md#disable-user-and-group-account-management),
run `sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts` before removing the gitlab package (with `dpkg` or `yum`).

If you have problems removing accounts or groups, run `luserdel` or `lgroupdel` manually
to delete them. You might also want to manually remove the leftover user home directories
from `/home/`.

To remove all omnibus-gitlab data use `sudo gitlab-ctl cleanse`.

To uninstall omnibus-gitlab, preserving your data (repositories, database, configuration), run the following commands.

```
# Stop gitlab and remove its supervision process
sudo systemctl stop    gitlab-runsvdir
sudo systemctl disable gitlab-runsvdir
sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
sudo systemctl daemon-reload
sudo gitlab-ctl uninstall

# (Replace with gitlab-ce if you have GitLab FOSS installed)

# Debian/Ubuntu
sudo apt remove gitlab-ee

# Redhat/Centos
sudo yum remove gitlab-ee
```

### Common installation problems

This section has been moved to the separate document [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md).

Section below remains for historical reasons(mainly to not break existing links). Each section contains the link to the new location.

#### Apt error 'The requested URL returned error: 403'

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#apt-error-the-requested-url-returned-error-403).

#### GitLab is unreachable in my browser

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#gitlab-is-unreachable-in-my-browser).

#### Emails are not being delivered

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#emails-are-not-being-delivered).

#### Reconfigure freezes at `ruby_block[supervise_redis_sleep] action run`

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#reconfigure-freezes-at-ruby_blocksupervise_redis_sleep-action-run).

#### TCP ports for GitLab services are already taken

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#tcp-ports-for-gitlab-services-are-already-taken).

#### Git SSH access stops working on SELinux-enabled systems

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#git-ssh-access-stops-working-on-selinux-enabled-systems
).

#### Postgres error 'FATAL:  could not create shared memory segment: Cannot allocate memory'

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#postgres-error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory).

#### Reconfigure complains about the GLIBC version

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#reconfigure-complains-about-the-glibc-version).

#### Reconfigure fails to create the git user

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#reconfigure-fails-to-create-the-git-user).

#### Failed to modify kernel parameters with sysctl

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#failed-to-modify-kernel-parameters-with-sysctl).

#### I am unable to install omnibus-gitlab without root access

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#i-am-unable-to-install-omnibus-gitlab-without-root-access).

#### gitlab-rake assets:precompile fails with 'Permission denied'

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#gitlab-rake-assetsprecompile-fails-with-permission-denied).

#### 'Short read or OOM loading DB' error

See [doc/common_installation_problems/README.md](doc/common_installation_problems/README.md#short-read-or-oom-loading-db-error).

### Backups

See [doc/settings/backups.md](doc/settings/backups.md).

#### Backup and restore omnibus-gitlab configuration

See [doc/settings/backups.md](doc/settings/backups.md#backup-and-restore-omnibus-gitlab-configuration).

#### Creating an application backup

See [doc/settings/backups.md](doc/settings/backups.md#creating-an-application-backup).

### Restoring an application backup

See [backup restore documentation](https://docs.gitlab.com/ee/raketasks/backup_restore.html#omnibus-installations).

### Backup and restore using non-packaged database

If you are using non-packaged database see [documentation on using non-packaged database](doc/settings/database.md#using-a-non-packaged-postgresql-database-management-server).

### Upload backups to remote (cloud) storage

For details check [backup restore document of GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss/blob/966f68b33e1f15f08e383ec68346ed1bd690b59b/doc/raketasks/backup_restore.md#upload-backups-to-remote-cloud-storage).

## Invoking Rake tasks

See [doc/maintenance/index.md](doc/maintenance/index.md#invoking-rake-tasks).

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

NSA, if you're reading this, we'd really appreciate it if you could contribute
back a SELinux profile for omnibus-gitlab :)
Of course, if anyone else is reading this, you're welcome to contribute the
SELinux profile too.

### Logs

This section has been moved to separate document [doc/settings/logs.md](doc/settings/logs.md).

#### Tail logs in a console on the server

See [doc/settings/logs.md](doc/settings/logs.md#tail-logs-in-a-console-on-the-server).

##### Runit logs

See [doc/settings/logs.md](doc/settings/logs.md#runit-logs).

##### Logrotate

See [doc/settings/logs.md](doc/settings/logs.md#logrotate).

##### UDP log shipping (GitLab Enterprise Edition only)

See [doc/settings/logs.md](doc/settings/logs.md#udp-log-shipping-gitlab-enterprise-edition-only)

### Create a user and database for GitLab

See [doc/settings/database.md](doc/settings/database.md).

### Configure omnibus-gitlab to connect to it

See [doc/settings/database.md](doc/settings/database.md).

### Seed the database (fresh installs only)

See [doc/settings/database.md](doc/settings/database.md).

## Building your own package

See [the separate build documentation](doc/build/index.md).

## Running a custom GitLab version

It is not recommended to make changes to any of the files in `/opt/gitlab`
after installing omnibus-gitlab: they will either conflict with or be
overwritten by future updates. If you want to run a custom version of GitLab
you can [build your own package](doc/build/index.md) or use [another installation
method][CE README].

## Acknowledgments

This omnibus installer project is based on the awesome work done by Chef in
[omnibus-chef-server][omnibus-chef-server].

[downloads]: https://about.gitlab.com/downloads/
[CE README]: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/README.md
[omnibus-chef-server]: https://github.com/opscode/omnibus-chef-server
[database.yml.mysql]: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/database.yml.mysql
[svlogd]: http://smarden.org/runit/svlogd.8.html
[installation]: https://about.gitlab.com/install/
[gitlab.rb.template]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template
