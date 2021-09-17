---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
comments: false
---

# Omnibus GitLab Documentation **(FREE SELF)**

Omnibus GitLab is a way to package different services and tools required to run GitLab, so that most users can install it without laborious configuration.

## Package information

- [Checking the versions of bundled software](https://docs.gitlab.com/ee/administration/package_information/index.html#checking-the-versions-of-bundled-software)
- [Package defaults](https://docs.gitlab.com/ee/administration/package_information/defaults.html)
- [Components included](https://docs.gitlab.com/ee/development/architecture.html#component-list)
- [Deprecated Operating Systems](https://docs.gitlab.com/ee/administration/package_information/deprecated_os.html)
- [Signed Packages](https://docs.gitlab.com/ee/administration/package_information/signed_packages.html)
- [Deprecation Policy](https://docs.gitlab.com/ee/administration/package_information/deprecation_policy.html)
- [Licenses of bundled dependencies](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)

## Installation

For installation details, see [Installing Omnibus GitLab](installation/index.md).

## Running on a low-resource device (like a Raspberry Pi)

You can run GitLab on supported low-resource computers like the Raspberry Pi 3, but you must tune the settings
to work best with the available resources. Check out the [documentation](settings/rpi.md) for suggestions on what to adjust.

## Maintenance

- [Get service status](maintenance/index.md#get-service-status)
- [Starting and stopping](maintenance/index.md#starting-and-stopping)
- [Invoking Rake tasks](maintenance/index.md#invoking-rake-tasks)
- [Starting a Rails console session](maintenance/index.md#starting-a-rails-console-session)
- [Starting a PostgreSQL superuser `psql` session](maintenance/index.md#starting-a-postgresql-superuser-psql-session)
- [Container registry garbage collection](maintenance/index.md#container-registry-garbage-collection)

## Configuring

- [Configuring the external URL](settings/configuration.md#configuring-the-external-url-for-gitlab)
- [Configuring a relative URL for GitLab (experimental)](settings/configuration.md#configuring-a-relative-url-for-gitlab)
- [Storing Git data in an alternative directory](settings/configuration.md#storing-git-data-in-an-alternative-directory)
- [Changing the name of the Git user group](settings/configuration.md#changing-the-name-of-the-git-user--group)
- [Specify numeric user and group identifiers](settings/configuration.md#specify-numeric-user-and-group-identifiers)
- [Only start Omnibus GitLab services after a given file system is mounted](settings/configuration.md#only-start-omnibus-gitlab-services-after-a-given-file-system-is-mounted)
- [Disable user and group account management](settings/configuration.md#disable-user-and-group-account-management)
- [Disable storage directory management](settings/configuration.md#disable-storage-directories-management)
- [Configuring Rack attack](settings/configuration.md#configuring-rack-attack)
- [SMTP](settings/smtp.md)
- [NGINX](settings/nginx.md)
- [LDAP](https://docs.gitlab.com/ee/administration/auth/ldap/index.html)
- [Puma](https://docs.gitlab.com/ee/administration/operations/puma.html)
- [ActionCable](settings/actioncable.md)
- [Redis](settings/redis.md)
- [Logs](settings/logs.md)
- [Database](settings/database.md)
- [Reply by email](https://docs.gitlab.com/ee/administration/reply_by_email.html)
- [Environment variables](settings/environment-variables.md)
- [`gitlab.yml`](settings/gitlab.yml.md)
- [Backups](settings/backups.md)
- [Pages](https://docs.gitlab.com/ee/administration/pages/index.html)
- [SSL](settings/ssl.md)
- [GitLab and Registry](https://docs.gitlab.com/ee/administration/packages/container_registry.html)
- [Configuring an asset proxy server](https://docs.gitlab.com/ee/security/asset_proxy.html)
- [Image scaling](settings/image_scaling.md)

## Updating

- [Upgrade guidance](https://docs.gitlab.com/ee/update/package/), including [supported upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths).
- [Upgrade from Community Edition to Enterprise Edition](https://docs.gitlab.com/ee/update/package/convert_to_ee.html)
- [Update to the latest version](https://docs.gitlab.com/ee/update/package/#upgrade-using-the-official-repositories)
- [Downgrade to an earlier version](https://docs.gitlab.com/ee/update/package/downgrade.html)
- [Upgrade from a non-Omnibus installation to an Omnibus installation using a backup](update/convert_to_omnibus.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-using-a-backup)
- [Upgrade from non-Omnibus PostgreSQL to an Omnibus installation in-place](update/convert_to_omnibus.md#upgrading-from-non-omnibus-postgresql-to-an-omnibus-installation-in-place)
- [Upgrade from non-Omnibus MySQL to an Omnibus installation (version 6.8+)](update/convert_to_omnibus.md#upgrading-from-non-omnibus-mysql-to-an-omnibus-installation-version-68)

## Troubleshooting

For troubleshooting details, see [Troubleshooting Omnibus GitLab installation issues](troubleshooting.md).

## Omnibus GitLab developer documentation

See the [development documentation](development/index.md)
