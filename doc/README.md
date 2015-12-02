# Omnibus GitLab documentation

## Installation

- [Package downloads page](https://about.gitlab.com/downloads/)
- [GitLab CI](gitlab-ci/README.md) Set up the GitLab CI coordinator that ships with Omnibus GitLab package.
- [GitLab Mattermost](gitlab-mattermost/README.md) Set up the Mattermost messaging app that ships with Omnibus GitLab package.
- [Docker](docker/README.md) Set up the GitLab in Docker container.

## Maintenance

- [Get service status](maintenance/README.md#get-service-status)
- [Starting and stopping](maintenance/README.md#starting-and-stopping)
- [Invoking Rake tasks](maintenance/README.md#invoking-rake-tasks)
- [Starting a Rails console session](maintenance/README.md#starting-a-rails-console-session)

## Configuring

- [Configuring the external url](settings/configuration.md#configuring-the-external-url-for-gitlab)
- [Storing git data in an alternative directory](settings/configuration.md#storing-git-data-in-an-alternative-directory)
- [Changing the name of the git user group](settings/configuration.md#changing-the-name-of-the-git-user-group)
- [Specify numeric user and group identifiers](settings/configuration.md#specify-numeric-user-and-group-identifiers)
- [Only start omnibus-gitlab services after a given filesystem is mounted](settings/configuration.md#only-start-omnibus-gitlab-services-after-a-given-filesystem-is-mounted)
- [Using self signed certificate or custom certificate authorities](settings/configuration.md#using-self-signed-certificate-or-custom-certificate-authorities)
- [SMTP](settings/smtp.md)
- [NGINX](settings/nginx.md)
- [LDAP](settings/ldap.md)
- [Unicorn](settings/unicorn.md)
- [Redis](settings/redis.md)
- [Logs](settings/logs.md)
- [Database](settings/database.md)
- [Reply by email](http://doc.gitlab.com/ce/incoming_email/README.html)
- [Environment variables](settings/environment-variables.md)
- [gitlab.yml](settings/gitlab.yml.md)
- [Backups](settings/backups.md)

## Updating

- [Note about updating from GitLab 6.6 and higher to 7.10 or newer](update/README.md#updating-from-gitlab-66-and-higher-to-710-or-newer)
- [Updating to the latest version](update/README.md#updating-from-gitlab-66-and-higher-to-the-latest-version)
- [Updating from GitLab 6.6.0.pre1 to 6.6.4](update/README.md#updating-from-gitlab-660pre1-to-664)
- [Downgrading to an earlier version](update/README.md#reverting-to-gitlab-66x-or-later)
- [Upgrading from a non-Omnibus installation to an Omnibus installation using a backup](update/README.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrading from non-Omnibus PostgreSQL to an Omnibus installation in-place](update/README.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)](update/README.md#upgrading-from-non-omnibus-mysql-to-an-omnibus-installation-version-68)
- [RPM error: 'package is already installed' ](update/README.md#rpm-package-is-already-installed-error)
- [Updating from GitLab CI version prior to 5.4.0 to the latest version](update/README.md#updating-from-gitlab-ci-version-prior-to-540-to-the-latest-version)

## Troubleshooting

- [Hash Sum mismatch when installing packages](common_installation_problems/README.md#hash-sum-mismatch-when-installing-packages)
- [Apt error: 'The requested URL returned error: 403'](common_installation_problems/README.md#apt-error-the-requested-url-returned-error-403).
- [GitLab is unreachable in my browser](common_installation_problems/README.md#gitlab-is-unreachable-in-my-browser).
- [GitLab CI shows GitLab login page](common_installation_problems/README.md#gitlab-ci-shows-gitlab-login-page).
- [Emails are not being delivered](common_installation_problems/README.md#emails-are-not-being-delivered).
- [Reconfigure freezes at ruby_block[supervise_redis_sleep] action run](common_installation_problems/README.md#reconfigure-freezes-at-ruby_blocksupervise_redis_sleep-action-run).
- [TCP ports for GitLab services are already taken](common_installation_problems/README.md#tcp-ports-for-gitlab-services-are-already-taken).
- [Git SSH access stops working on SELinux-enabled systems](common_installation_problems/README.md#git-ssh-access-stops-working-on-selinux-enabled-systems).
- [Postgres error 'FATAL:  could not create shared memory segment: Cannot allocate memory'](common_installation_problems/README.md#postgres-error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory).
- [Reconfigure complains about the GLIBC version](common_installation_problems/README.md#reconfigure-complains-about-the-glibc-version).
- [Reconfigure fails to create the git user](common_installation_problems/README.md#reconfigure-fails-to-create-the-git-user).
- [Failed to modify kernel parameters with sysctl](common_installation_problems/README.md#failed-to-modify-kernel-parameters-with-sysctl).
- [I am unable to install omnibus-gitlab without root access](common_installation_problems/README.md#i-am-unable-to-install-omnibus-gitlab-without-root-access).
- [gitlab-rake assets:precompile fails with 'Permission denied'](common_installation_problems/README.md#gitlab-rake-assetsprecompile-fails-with-permission-denied).
- ['Short read or OOM loading DB' error](common_installation_problems/README.md#short-read-or-oom-loading-db-error).
- ['pg_dump: aborting because of server version mismatch'](settings/database.md#using-a-non-packaged-postgresql-database-management-server)

## Omnibus GitLab developer documentation

- [Development Setup](development/README.md)
- [Release process](release/README.md)
- [Building your own package](build/README.md)
