---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan fpr Redis component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms (include `build-package-on-all-os` job).
- [ ] Ran `qa-subset-test` as well as manual `qa-remaining-test-manual` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Redis indicator test cases were not failing.
  - [realtime components via assignee test](https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347941)
  - [project template import](https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347932)
- [ ] Performed fresh install and verified operation:
  - [ ] Installed on single node
    - [ ] Checked installed version:

      ```shell
      /opt/gitlab/embedded/bin/redis-server --version
      ```

    - [ ] Sign-in
    - [ ] Imported a project (confirms Sidekiq works)
    - [ ] Checked `gitlab-kas` log for Redis errors
    - [ ] Checked `redis-exporter` logs for errors
    - [ ] Confirmed `gitlab-redis-cli` command connects to Redis
  - [ ] Installed on [HA Sentinels](https://docs.gitlab.com/administration/redis/replication_and_failover/)
    - [ ] Signed-in
    - [ ] Imported a project (confirms Sidekiq works)
    - [ ] Checked `gitlab-kas` log for Redis errors
    - [ ] Performed failover
- [ ] Updates
  - [ ] Updated on single node:
    - [ ] Verified that you get the message:

      ```plaintext
      Running version of Redis different than installed version. Restart redis"
      ```

    - [ ] Sign-in
    - [ ] Imported a project (confirms Sidekiq works)
    - [ ] Checked `gitlab-kas log` for Redis errors
    - [ ] Checked `redis-exporter logs` for errors
    - [ ] Confirmed `gitlab-redis-cli` command connects to Redis
  - [ ] Updated [HA Sentinel/Redis nodes](https://docs.gitlab.com/update/zero_downtime/#redis-ha-using-sentinel)
    - [ ] Verified that you get the message:

      ```plaintext
      Running version of Redis different than installed version. Restart redis"
      ```

    - [ ] Signed-in
    - [ ] Imported a project (confirms Sidekiq works)
    - [ ] Checked `gitlab-kas` log for Redis errors
    - [ ] Checked `redis-exporter` logs for errors
    - [ ] Confirmed `gitlab-redis-cli` command connects to Redis on a Redis node
    - [ ] Performed failover
````
