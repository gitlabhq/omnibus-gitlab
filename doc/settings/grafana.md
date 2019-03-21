# Grafana Dashboard Service

[Grafana](https://grafana.com/) is a powerful dashboard building system. You can use it to visualize performance metrics from the embedded Prometheus monitoring system.

Grafana is not enabled by default.

To enable and adjust settings in the embedded Grafana service, can use the following settings in `/etc/gitlab/gitlab.rb`.

Once enabled, it will be available on `gitlab.example.com/-/grafana`.

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

```ruby
grafana['enable'] = true
grafana['admin_password'] = 'admin' # This is the default admin password.
grafana['allow_user_sign_up'] = false # Allow users to create accounts.

# Configure a Gitlab authentication: http://docs.grafana.org/auth/gitlab/
grafana['gitlab_application_id'] = 'GITLAB_APPLICATION_ID'
grafana['gitlab_secret'] = 'GITLAB_SECRET'

# Select a list of GitLab groups allowed to login.
grafana['allowed_groups'] = []
```

## Dashboards

There are [pre-build dashboards for omnibus](https://gitlab.com/gitlab-org/grafana-dashboards/tree/master/omnibus). These will be automatically loaded in [future releases](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4180).
