ijunxyz123:patch-1---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Linux package documentation

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

The Linux package has different services and tools required to run GitLab. Most users can install it without laborious
configuration.

## Package information

- [Checking the versions of bundled software](https://docs.gitlab.com/ee/administration/package_information/index.html#checking-the-versions-of-bundled-software)
- [Package defaults](https://docs.gitlab.com/ee/administration/package_information/defaults.html)
- [Components included](https://docs.gitlab.com/ee/development/architecture.html#component-list)
- [Deprecated Operating Systems](https://docs.gitlab.com/ee/administration/package_information/supported_os.html#os-versions-that-are-no-longer-supported)
- [Signed Packages](https://docs.gitlab.com/ee/administration/package_information/signed_packages.html)
- [Deprecation Policy](https://docs.gitlab.com/ee/administration/package_information/deprecation_policy.html)
- [Licenses of bundled dependencies](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)

## Installation

For installation details, see [Install GitLab with the Linux package](installation/index.md).

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

- [Configuring the external URL](settings/configuration.md#configure-the-external-url-for-gitlab)
- [Configuring a relative URL for GitLab (experimental)](settings/configuration.md#configure-a-relative-url-for-gitlab)
- [Storing Git data in an alternative directory](settings/configuration.md#store-git-data-in-an-alternative-directory)
- [Changing the name of the Git user group](settings/configuration.md#change-the-name-of-the-git-user-or-group)
- [Specify numeric user and group identifiers](settings/configuration.md#specify-numeric-user-and-group-identifiers)
- [Start Linux package installation services only after a given file system is mounted](settings/configuration.md#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted)
- [Disable user and group account management](settings/configuration.md#disable-user-and-group-account-management)
- [Disable storage directory management](settings/configuration.md#disable-storage-directories-management)
- [Failed authentication ban](settings/configuration.md#configure-a-failed-authentication-ban)
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
- [SSL](settings/ssl/index.md)
- [GitLab and Registry](https://docs.gitlab.com/ee/administration/packages/container_registry.html)
- [Configuring an asset proxy server](https://docs.gitlab.com/ee/security/asset_proxy.html)
- [Image scaling](settings/image_scaling.md)
- [GitLab Agent](https://docs.gitlab.com/ee/administration/clusters/kas.html)

## Upgrading

- [Upgrade guidance](https://docs.gitlab.com/ee/update/package/), including [supported upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths).
- [Upgrade from Community Edition to Enterprise Edition](https://docs.gitlab.com/ee/update/package/convert_to_ee.html)
- [Upgrade to the latest version](https://docs.gitlab.com/ee/update/package/#upgrade-using-the-official-repositories)
- [Downgrade to an earlier version](https://docs.gitlab.com/ee/update/package/downgrade.html)

## Converting

- [Convert a self-compiled installation to a Linux package installation](update/convert_to_omnibus.md)
- [Convert an external PostgreSQL to a Linux package installation by using a backup](update/convert_to_omnibus.md#convert-an-external-postgresql-to-a-linux-package-installation-by-using-a-backup)
- [Convert an external PostgreSQL to a Linux package installation in-place](update/convert_to_omnibus.md#convert-an-external-postgresql-to-a-linux-package-installation-in-place)

## Troubleshooting

For troubleshooting details, see [Troubleshooting Omnibus GitLab installation issues](troubleshooting.md).

## Omnibus GitLab developer documentation

See the [development documentation](development/index.md)
