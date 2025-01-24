---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# `alertmanager` component upgrade test plan

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms.
- [ ] Ran `qa-subset-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Performed a successful GitLab Enterprise Community Edition (CE) build on dev.gitlab.org.
- [ ] Installed and verified that the component version has been upgraded.

  ```shell
  $ /opt/gitlab/embedded/bin/alertmanager --version
  ```

- [ ] Verified basic functionality.

  - [ ] Set `prometheus['listen_address'] = '0.0.0.0:9090'` in `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl reconfigure`.

  - [ ] Shut down `gitaly` service:

       ```shell
       gitlab-ctl stop gitaly
       ```

  - [ ] Wait 5 minutes and check Prometheus console `http://<gitlab host>:9090/alerts?search=` for service down alert.

  - [ ] Start `gitaly` service:

       ```shell
       gitlab-ctl start gitaly
       ```

  - [ ]  Wait 5 minutes and check Prometheus console `http://<gitlab host>:9090/alerts?search=` for service back up.

````
