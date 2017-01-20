# Prometheus

[Prometheus](https://prometheus.io) is a powerful time-series monitoring service, whose data can be used to easily create dashboards with tools like Grafana or provide alerts.

To enable Prometheus in your GitLab installation, in `/etc/gitlab/gitlab.rb`
uncomment and edit the following line:

```
prometheus['enable'] = true
```
After saving the changes, run `sudo gitlab-ctl reconfigure`.

By default, Prometheus will run as the `gitlab-prometheus` user and listen on `TCP port 9090`.