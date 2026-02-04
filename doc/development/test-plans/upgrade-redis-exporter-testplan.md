---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `redis-exporter` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check [`redis-exporter` project repository](https://gitlab.com/gitlab-org/build/omnibus-mirror/redis_exporter) for potential breaking changes.
- [ ] Green pipeline with `Trigger:ee-package` and `build-package-on-all-os`.
- [ ] `redis-exporter` starts. Run `sudo gitlab-ctl status redis-exporter` and check output
- [ ] Check the version.

  ```shell
  /opt/gitlab/embedded/bin/redis_exporter -version
  INFO[0000] Redis Metrics Exporter 1.74.0    build date:     sha1:     Go: go1.24.5    GOOS: linux    GOARCH: amd64
  ```

  To ensure `redis-exporter` started successfully.

  ```shell
  sudo gitlab-ctl status redis-exporter
  ```

- [ ] Check that `redis-exporter` endpoint can be queried.

  ```shell
  curl --silent "http://localhost:9121/metrics" | head -n5
  ```

- [ ]  Check that Prometheus scrapes redis metrics by poking metrics endpoint.

  ```shell
  curl --silent "http://localhost:9090/metrics" | grep redis
  ```
````
