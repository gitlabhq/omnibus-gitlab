# Prometheus

[Prometheus](https://prometheus.io) is a powerful time-series monitoring service, providing a flexible platform for monitoring GitLab and other software products.

#### Configuring Prometheus

To enable Prometheus in your GitLab installation, in `/etc/gitlab/gitlab.rb`
uncomment and edit the following line:

```
prometheus['enable'] = true
```
After saving the changes, run `sudo gitlab-ctl reconfigure`.

By default, Prometheus will run as the `gitlab-prometheus` user and listen on `TCP port 9090`. If the [Node Exporter](node-exporter.md) service has been enabled, it will automatically be set up as a monitoring target for Prometheus.

#### Viewing Performance Metrics

The performance data collected by Prometheus can be viewed directly in the Prometheus console or through compatible dashboard tool.

The Prometheus interface provides a [flexible query language](https://prometheus.io/docs/querying/basics/) to work with the collected data, and can visualize the output.

For a more fully featured dashboard, Grafana can be used and has [official support](https://prometheus.io/docs/visualization/grafana/) for Prometheus.  
