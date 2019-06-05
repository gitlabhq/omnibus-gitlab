# GitLab 12 specific changes

## Prometheus 1.x Removal

Prometheus 1.x was deprecated in the previous major release. In 12.x it will be removed and automatically upgraded to Prometheus 2.x.

Before upgrading, please follow the [upgrade instructions](https://docs.gitlab.com/omnibus/update/gitlab_11_changes.html#114).

If you have not done this, and have `skip-auto-reconfigure`, you will need to update manually or Prometheus will be non-functional.

```console
sudo gitlab-ctl prometheus-upgrade
```
