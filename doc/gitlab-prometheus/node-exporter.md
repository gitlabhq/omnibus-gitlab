# Node Exporter

Node exporter allows you to measure various machine resources such as
memory, disk and CPU utilization.

To enable Node Exporter in your GitLab installation, in `/etc/gitlab/gitlab.rb`
uncomment and edit the following line:

```
node_exporter['enable'] = true
```

After saving the changes, run `sudo gitlab-ctl reconfigure`.

Node Exporter by default will listen on `TCP port 9100`.
