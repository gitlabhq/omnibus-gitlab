---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `gitlab-exporter` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check [`gitlab-exporter` project repository](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter) for potential breaking changes.
- [ ] Green pipeline with `Trigger:ee-package` and `build-package-on-all-os`.
- [ ] `gitlab-exporter` starts. Run `sudo gitlab-ctl status gitlab-exporter` and check output
  to ensure `gitlab-exporter` started successfully.

  ```shell
  sudo gitlab-ctl status gitlab-exporter
  ```

- [ ] Check exporter version. Run `/opt/gitlab/embedded/bin/gem list gitlab-exporter`

  ```shell
  /opt/gitlab/embedded/bin/gem list gitlab-exporter
  ```

- [ ] Check that `gitlab-exporter` endpoint can be queried.

  ```shell
  curl --silent "http://localhost:9168/metrics" | head -n5
  ```

- [ ]  Check that Prometheus scrapes `gitlab_exporter_database`, `gitlab_exporter_ruby` and `gitlab_exporter_sidekiq` by poking metrics endpoint.

  ```shell
  curl --silent "http://localhost:9090/metrics" | grep gitlab_exporter
  ```
````
