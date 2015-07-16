# Omnibus GitLab documentation

## Installation

- [Package downloads page](https://about.gitlab.com/downloads/)
- [GitLab CI](gitlab-ci/README.md) Set up the GitLab CI coordinator that ships with Omnibus GitLab package.

## Maintenance

- [Get service status](doc/maintenance/README.md#get-service-status)
- [Starting and stopping](doc/maintenance/README.md#starting-and-stopping)
- [Invoking Rake tasks](doc/maintenance/README.md#invoking-rake-tasks)
- [Starting a Rails console session](doc/maintenance/README.md#starting-a-rails-console-session)

## Configuring

- [Configuring the external url](doc/settings/configuration.md#configuring-the-external-url-for-gitlab)
- [Storing git data in an alternative directory](doc/settings/configuration.md#storing-git-data-in-an-alternative-directory)
- [Changing the name of the git user group](doc/settings/configuration.md#changing-the-name-of-the-git-user-group)
- [Specify numeric user and group identifiers](doc/settings/configuration.md#specify-numeric-user-and-group-identifiers)
- [Only start omnibus-gitlab services after a given filesystem is mounted](doc/settings/configuration.md#only-start-omnibus-gitlab-services-after-a-given-filesystem-is-mounted)
- [SMTP](settings/smtp.md)
- [NGINX](settings/nginx.md)
- [LDAP](settings/ldap.md)
- [Unicorn](settings/unicorn.md)
- [Environment variables](settings/environment-variables.md).
- [gitlab.yml](settings/gitlab.yml.md)
- [Redis](settings/redis.md)
- [Logs](settings/logs.md)

## Updating

- [Note about updating from GitLab 6.6 and higher to 7.10 or newer](doc/update/README.md#updating-from-gitlab-66-and-higher-to-710-or-newer)
- [Updating to the latest version](doc/update/README.md#updating-from-gitlab-66-and-higher-to-the-latest-version)
- [Updating from GitLab 6.6.0.pre1 to 6.6.4](doc/update/README.md#updating-from-gitlab-660pre1-to-664)
- [Downgrading to an earlier version](doc/update/README.md#reverting-to-gitlab-66x-or-later)
- [Upgrading from a non-Omnibus installation to an Omnibus installation using a backup](doc/update/README.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrading from non-Omnibus PostgreSQL to an Omnibus installation in-place](doc/update/README.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)](doc/update/README.md#upgrading-from-non-omnibus-mysql-to-an-omnibus-installation-version-68)
- [RPM error: 'package is already installed' ](doc/update/README.md#rpm-package-is-already-installed-error)
- [Updating from GitLab CI version prior to 5.4.0 to the latest version](doc/update/README.md#updating-from-gitlab-ci-version-prior-to-540-to-the-latest-version)

## Troubleshooting

- [Apt error: 'The requested URL returned error: 403'](doc/common_installation_problems/README.md#apt-error-the-requested-url-returned-error-403).
- [GitLab is unreachable in my browser](doc/common_installation_problems/README.md#gitlab-is-unreachable-in-my-browser).
- [GitLab CI shows GitLab login page](doc/common_installation_problems/README.md#gitlab-ci-shows-gitlab-login-page).
- [Emails are not being delivered](doc/common_installation_problems/README.md#emails-are-not-being-delivered).
- [Reconfigure freezes at ruby_block[supervise_redis_sleep] action run](doc/common_installation_problems/README.md#reconfigure-freezes-at-ruby_blocksupervise_redis_sleep-action-run).
- [TCP ports for GitLab services are already taken](doc/common_installation_problems/README.md#tcp-ports-for-gitlab-services-are-already-taken).
- [Git SSH access stops working on SELinux-enabled systems](doc/common_installation_problems/README.md#git-ssh-access-stops-working-on-selinux-enabled-systems).
- [Postgres error 'FATAL:  could not create shared memory segment: Cannot allocate memory'](doc/common_installation_problems/README.md#postgres-error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory).
- [Reconfigure complains about the GLIBC version](doc/common_installation_problems/README.md#reconfigure-complains-about-the-glibc-version).
- [Reconfigure fails to create the git user](doc/common_installation_problems/README.md#reconfigure-fails-to-create-the-git-user).
- [Failed to modify kernel parameters with sysctl](doc/common_installation_problems/README.md#failed-to-modify-kernel-parameters-with-sysctl).
- [I am unable to install omnibus-gitlab without root access](doc/common_installation_problems/README.md#i-am-unable-to-install-omnibus-gitlab-without-root-access).
- [gitlab-rake assets:precompile fails with 'Permission denied'](doc/common_installation_problems/README.md#gitlab-rake-assetsprecompile-fails-with-permission-denied).
- ['Short read or OOM loading DB' error](doc/common_installation_problems/README.md#short-read-or-oom-loading-db-error).

## Omnibus GitLab developer documentation

- [Development Setup](doc/development/README.md)
- [Release process](doc/release/README.md)
- [Building your own package](doc/build/README.md)
