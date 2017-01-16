# Prometheus

To enable Prometheus in your GitLab installation, in `/etc/gitlab/gitlab.rb`
uncomment and edit the following line:

```
prometheus['enable'] = true
```
After saving the changes, run `sudo gitlab-ctl reconfigure`.
