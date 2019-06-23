# GitLab 12 specific changes

## Prometheus 1.x Removal Prometheus 1.x was deprecated in GitLab 11.4, and
Prometheus 2.8.1 was installed by default on new installations. Users updating
from older versions of GitLab could manually upgrade Prometheus data using the
[`gitlab-ctl prometheus-upgrade`](https://docs.gitlab.com/omnibus/update/gitlab_11_changes.html#114)
command provided.

With GitLab 12.0, support for Prometheus 1.x is completely removed, and as part
of the upgrade process, Prometheus binaries will be updated to version 2.8.1.
Existing data from Prometheus 1.x installation WILL NOT be migrated as part of
this automatic upgrade, and users who wish to retain that data should
[manually upgrade Prometheus version](https://docs.gitlab.com/omnibus/update/gitlab_11_changes.html#114)
before upgrading to GitLab 12.0

For users who use `/etc/gitlab/skip-auto-reconfigure` file to skip automatic
migrations and reconfigures during upgrade, Prometheus upgrade will also be
skipped. However, since the package no longer contains Prometheus 1.x binary,
the Prometheus service will be non-functional due to the mismatch between binary
version and data directory. Users will have to manually run `sudo gitlab-ctl
prometheus-upgrade` command to get Prometheus running again.

Please note that `gitlab-ctl prometheus-upgrade` command automatically
reconfigures your GitLab instance, and will cause database migrations to run.
So, if you are on an HA instance, run this command only as the last step, after
performing all database related actions.

## Removal of support for /etc/gitlab/skip-auto-migrations file

Before GitLab 10.6, the file `/etc/gitlab/skip-auto-migrations` was used to
prevent automatic reconfigure (and thus automatic database migrations) as part
of upgrade. This file had been deprecated in favor of `/etc/gitlab/skip-auto-reconfigure`
since GitLab 10.6, and in 12.0 the support is removed completely. Upgrade
process will no longer take `skip-auto-migrations` file into consideration.

## Deprecation of TLS v1.1

With the release of GitLab 12, TLS v1.1 has been fully deprecated.
This mitigates numerous issues including, but not limited to,
Heartbleed and makes GitLab compliant out of the box with the PCI
DSS 3.1 standard.

[Learn more about why TLS v1.1 is being deprecated in our blog.](https://about.gitlab.com/2018/10/15/gitlab-to-deprecate-older-tls/)

## Upgrade to Postgres 10

Postgres will automatically be upgraded to 10.7.0 unless specifically opted
out during the upgrade. To opt out you must execute the following before
performing the upgrade of GitLab.

```bash
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Further details and procedures for upgrading a GitLab HA cluster can be
found in the [Database Settings notes](../settings/database.md#upgrade-packaged-postgresql-server).
