# GitLab Prometheus

GitLab provides out of the box monitoring with
[Prometheus](https://prometheus.io/), providing easy access to high quality time-series monitoring of GitLab services.

Prometheus works by periodically connecting to data sources and collecting their performance metrics. With release 8.16 system information will be monitored with Node Exporter, and over subsequent releases additional GitLab metrics will be captured.

To view and work with the monitoring data, you can either connect directly to Prometheus or utilize a dashboard tool like [Grafana](https://grafana.net). 

>**Note:**
Prometheus services are on by default starting with GitLab 9.0.

- [Prometheus](prometheus.md)
- [Node Exporter](node-exporter.md)
