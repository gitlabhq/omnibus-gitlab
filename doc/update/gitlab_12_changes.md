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
