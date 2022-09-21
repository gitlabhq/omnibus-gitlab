---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 15 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 15.0

### PostgreSQL version updates

In GitLab 15.0, [Omnibus GitLab ships with PostgreSQL versions](https://docs.gitlab.com/ee/administration/package_information/postgresql_versions.html) 12.10 for upgrades and 13.6 for fresh installs.
Because of underlying structural changes, the running PostgreSQL
process **_must_** be restarted when it is upgraded before running database migrations. If automatic
restart is skipped, you must run the following command before
migrations are run:

```shell
# If using PostgreSQL
sudo gitlab-ctl restart postgresql

# If using Patroni for Database replication
sudo gitlab-ctl restart patroni
```

If PostgreSQL is not restarted, you might face
[errors related to loading libraries](../settings/database.md#could-not-load-library-plpgsqlso).

### Automatic restart of PostgreSQL service on version change

Starting with GitLab 15.0, `postgresql` and `geo-postgresql` services are
automatically restarted when the PostgreSQL version changes. Restarting
PostgreSQL services causes downtime due to the temporary unavailability of the
database for operations. While this restart is mandatory for proper functioning
of the Database services, you might want more control over when the PostgreSQL
is restarted. For that purpose, you can choose to skip the automatic restarts as
part of `gitlab-ctl reconfigure` and manually restart the services.

To skip automatic restarts as part of GitLab 15.0 upgrade, perform the following
steps before the upgrade:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   # For PostgreSQL/Patroni
   postgresql['auto_restart_on_version_change'] = false

   # For Geo PostgreSQL
   geo_postgresql['auto_restart_on_version_change'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
It is mandatory to restart PostgreSQL when underlying version changes, to avoid
errors like the [one related to loading necessary libraries](../settings/database.md#could-not-load-library-plpgsqlso)
that can cause downtime. So, if you skip the automatic restarts using the above
method, ensure that you restart the services manually before upgrading to GitLab
15.0.

### AES256-GCM-SHA384 SSL cipher no longer allowed by default by NGINX

Starting with GitLab 15.0, the `AES256-GCM-SHA384` SSL cipher will not be allowed by
NGINX by default. If you require this cipher (for example, if you use
[AWS's Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)),
you can add the cipher back to the allow list by following the steps below:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line to it:

   ```ruby
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:AES256-GCM-SHA384"
   ```

1. Run `sudo gitlab-ctl reconfigure`.

### Removing support for Gitaly's internal socket path

In 14.10, [Gitaly introduced a new directory](gitlab_14_changes.md#gitaly-runtime-directory) that holds all runtime data Gitaly requires to operate correctly. This new directory replaces the old internal socket directory, and consequentially the usage of `gitaly['internal_socket_dir']` was deprecated in favor of `gitaly['runtime_dir']`.

The old `gitaly['internal_socket_dir']` configuration was removed in this release.

### PostgreSQL 13.6 support

PostgreSQL 13.6 is being shipped as the default version for fresh installs.

Users can manually upgrade to 13.6 following the [upgrade docs](../settings/database.md#gitlab-150-and-later).

### Removed background uploads settings for object storage

Object storage now preferentially uses direct uploads.

The following keys are no longer supported in `gitlab.rb`:

- `gitlab_rails['artifacts_object_store_direct_upload']`
- `gitlab_rails['artifacts_object_store_background_upload']`
- `gitlab_rails['external_diffs_object_store_direct_upload']`
- `gitlab_rails['external_diffs_object_store_background_upload']`
- `gitlab_rails['lfs_object_store_direct_upload']`
- `gitlab_rails['lfs_object_store_background_upload']`
- `gitlab_rails['uploads_object_store_direct_upload']`
- `gitlab_rails['uploads_object_store_background_upload']`
- `gitlab_rails['packages_object_store_direct_upload']`
- `gitlab_rails['packages_object_store_background_upload']`
- `gitlab_rails['dependency_proxy_object_store_direct_upload']`
- `gitlab_rails['dependency_proxy_object_store_background_upload']`
