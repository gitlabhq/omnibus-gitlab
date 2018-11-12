---
toc: false
comments: false
---

# Omnibus GitLab documentation

Omnibus is a way to package different services and tools required to run GitLab, so that most users can install it without laborious configuration.

## Package information

- [Checking the versions of bundled software](package-information/README.md#checking-the-versions-of-bundled-software)
- [Package defaults](package-information/defaults.md)
- [Deprecated Operating Systems](package-information/deprecated_os.md)
- [Signed Packages](package-information/signed_packages.md)
- [Deprecation Policy](package-information/deprecation_policy.md)
- Licenses of bundled dependencies - [Community Edition](https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab-ce.html) | [Enterprise Edition](https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab-ee.html)

## Installation

##### Prerequisites

- [Installation Requirements](https://docs.gitlab.com/ce/install/requirements.html)
- If you want to access your GitLab instance via a domain name, like mygitlabinstance.com, make sure the domain correctly points to the IP of the server where GitLab is being installed. You can check this using the command `host mygitlabinstance.com`
- If you want to use HTTPS on your GitLab instance, make sure you have the SSL certificates for the domain ready. (Note that certain components like Container Registry which can have their own subdomains requires certificates for those subdomains also)
- If you want to send notification emails, install and configure a mail server (MTA) like sendmail. Alternatively, you can use other third party SMTP servers, which is described below.

#### Installation and Configuration using omnibus package

NOTE: **Note:**
This section describes the commonly used configuration settings. Check
[configuration](#configuring) section of the documentation for complete configuration settings.

* [Installing GitLab](https://about.gitlab.com/installation/)
  * [Manually downloading and installing a GitLab package](manual_install.md)
* [Setting up a domain name/URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab) for the GitLab Instance so that it can be accessed easily
* [Enabling HTTPS](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
* [Enabling notification EMails](https://docs.gitlab.com/omnibus/settings/smtp.html#smtp-settings)
* [Enabling replying via email](https://docs.gitlab.com/ce/administration/reply_by_email.html#set-it-up)
    * [Installing and configuring postfix](https://docs.gitlab.com/ce/administration/reply_by_email_postfix_setup.html)
* [Enabling container registry on GitLab](https://docs.gitlab.com/ce/administration/container_registry.html#container-registry-domain-configuration)
    * You will require SSL certificates for the domain used for container registry
* [Enabling GitLab Pages](https://docs.gitlab.com/ce/administration/pages/)
    * If you want HTTPS enabled, you will have to get wildcard certificates
* [Enabling Elasticsearch](https://docs.gitlab.com/ee/integration/elasticsearch.html)
* [GitLab Mattermost](gitlab-mattermost/README.md) Set up the Mattermost messaging app that ships with Omnibus GitLab package.
* [GitLab Prometheus](https://docs.gitlab.com/ce/administration/monitoring/performance/prometheus.html) Set up the Prometheus
  monitoring included in the Omnibus GitLab package.
* [GitLab High Availability Roles](roles/README.md)

#### Using docker image

You can also use the docker images provided by GitLab to install and configure a GitLab instance. Check the [documentation](docker/README.md) to know more.

## Maintenance

- [Get service status](maintenance/README.md#get-service-status)
- [Starting and stopping](maintenance/README.md#starting-and-stopping)
- [Invoking Rake tasks](maintenance/README.md#invoking-rake-tasks)
- [Starting a Rails console session](maintenance/README.md#starting-a-rails-console-session)
- [Starting a Postgres superuser psql session](maintenance/README.md#starting-a-postgres-superuser-psql-session)
- [Container registry garbage collection](maintenance/README.md#container-registry-garbage-collection)

## Configuring

- [Configuring the external url](settings/configuration.md#configuring-the-external-url-for-gitlab)
- [Configuring a relative URL for Gitlab (experimental)](settings/configuration.md#configuring-a-relative-url-for-gitlab)
- [Storing git data in an alternative directory](settings/configuration.md#storing-git-data-in-an-alternative-directory)
- [Changing the name of the git user group](settings/configuration.md#changing-the-name-of-the-git-user-group)
- [Specify numeric user and group identifiers](settings/configuration.md#specify-numeric-user-and-group-identifiers)
- [Only start omnibus-gitlab services after a given filesystem is mounted](settings/configuration.md#only-start-omnibus-gitlab-services-after-a-given-filesystem-is-mounted)
- [Disable user and group account management](settings/configuration.html#disable-user-and-group-account-management)
- [Disable storage directory management](settings/configuration.html#disable-storage-directories-management)
- [Configuring Rack attack](settings/configuration.md#configuring-rack-attack)
- [SMTP](settings/smtp.md)
- [NGINX](settings/nginx.md)
- [LDAP](settings/ldap.md)
- [Unicorn](settings/unicorn.md)
- [Redis](settings/redis.md)
- [Logs](settings/logs.md)
- [Database](settings/database.md)
- [Reply by email](https://docs.gitlab.com/ce/incoming_email/README.html)
- [Environment variables](settings/environment-variables.md)
- [gitlab.yml](settings/gitlab.yml.md)
- [Backups](settings/backups.md)
- [Pages](https://docs.gitlab.com/ce/pages/administration.html)
- [SSL](settings/ssl.md)
- [GitLab and Registry](architecture/registry/README.md)

## Updating

- [Upgrade support policy](https://docs.gitlab.com/ee/policy/maintenance.html)
- [Upgrade from Community Edition to Enterprise Edition](update/README.md#updating-community-edition-to-enterprise-edition)
- [Updating to the latest version](update/README.md#updating-using-the-official-repositories)
- [Downgrading to an earlier version](update/README.md#downgrading)
- [Upgrading from a non-Omnibus installation to an Omnibus installation using a backup](update/convert_to_omnibus.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-using-a-backup)
- [Upgrading from non-Omnibus PostgreSQL to an Omnibus installation in-place](update/convert_to_omnibus.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrading from non-Omnibus MySQL to an Omnibus installation (version 6.8+)](update/convert_to_omnibus.md#upgrading-from-non-omnibus-mysql-to-an-omnibus-installation-version-6-8)
- [Updating from GitLab 6.6 and higher to 7.10 or newer](update/README.md#updating-from-gitlab-6-6-and-higher-to-7-10-or-newer)
- [Updating from GitLab 6.6.0.pre1 to 6.6.4](update/README.md#updating-from-gitlab-6-6-0-pre1-to-6-6-4)
- [Updating from GitLab CI version prior to 5.4.0 to the latest version](update/README.md#updating-gitlab-ci-from-prior-5-4-0-to-version-7-14-via-omnibus-gitlab)

## Troubleshooting

- [Hash Sum mismatch when installing packages](common_installation_problems/README.md#hash-sum-mismatch-when-installing-packages)
- [Apt error: 'The requested URL returned error: 403'](common_installation_problems/README.md#apt-error-the-requested-url-returned-error-403).
- [GitLab is unreachable in my browser](common_installation_problems/README.md#gitlab-is-unreachable-in-my-browser).
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
- ['Errno::ENOMEM: Cannot allocate memory' during backup or upgrade](common_installation_problems/README.md#errnoenomem-cannot-allocate-memory-during-backup-or-upgrade)
- [NGINX error: 'could not build server_names_hash'](common_installation_problems/README.md#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size)
- [Reconfigure fails due to "'root' cannot chown" with NFS root_squash](common_installation_problems/README.md#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash)

## Omnibus GitLab developer documentation

See the [development documentation](development/README.md)
