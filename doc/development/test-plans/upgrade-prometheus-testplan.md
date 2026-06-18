---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `prometheus` component upgrade
---

Copy the following test plan to a comment of the merge request that
upgrades the component.

````markdown
## Test plan

- [ ] Check the [Prometheus release notes](https://github.com/prometheus/prometheus/releases) for potential breaking changes -- TSDB format, log format, configuration syntax, and removed flags or APIs.
- [ ] Green pipeline on gitlab.com with `Trigger:ee-package` and `build-package-on-all-os`.
- [ ] Green pipeline on dev.gitlab.org.
- [ ] `prometheus` starts. Confirm with `sudo gitlab-ctl status prometheus`.
- [ ] Check the installed version.

  ```shell
  /opt/gitlab/embedded/bin/prometheus --version
  ```

  Expect the output to report the upgraded version line.

- [ ] Verify the Prometheus query API responds.

  ```shell
  curl 'localhost:9090/api/v1/query?query=up' | jq .
  ```

  Expect `status: "success"` and a non-empty `data.result` array. Every
  scrape target the install enables reports value `"1"`.

- [ ] Inspect the boot log for errors and any unexpected format change.

  ```shell
  sudo cat /var/log/gitlab/prometheus/current | head
  ```

  Expect no error-level entries during boot or TSDB replay.

- [ ] Verify an upgrade from the predecessor GitLab release.

  - [ ] Install the predecessor GitLab release that ships the prior Prometheus version.
  - [ ] Confirm the predecessor version.

    ```shell
    /opt/gitlab/embedded/bin/prometheus --version
    ```

  - [ ] Capture the pre-upgrade boot log for later comparison.

    ```shell
    sudo cat /var/log/gitlab/prometheus/current | head -n2
    ```

  - [ ] Install the new GitLab package and run `sudo gitlab-ctl reconfigure`.
  - [ ] Confirm the Prometheus version flipped to the upgraded line.

    ```shell
    /opt/gitlab/embedded/bin/prometheus --version
    ```

  - [ ] Verify the query API still responds against the upgraded TSDB.

    ```shell
    curl 'localhost:9090/api/v1/query?query=up' | jq .
    ```

    Expect `status: "success"` and the prior scrape targets still
    report value `"1"`.
  - [ ] Inspect the post-upgrade boot log for errors.

    ```shell
    sudo cat /var/log/gitlab/prometheus/current | head
    ```
````
