---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `go-crond` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check [releases](https://github.com/webdevops/go-crond/releases) for potentially breaking changes.

### Build tests

- [ ] Built on all supported platforms using `build-package-on-all-os` job.
- [ ] Ran `Trigger:ee-package` and then `qa-subset-test` as well as manual `qa-remaining-test-manual` CI jobs on `gitlab.com`.

### Install and check version and basic operation

- [ ] Install and configure using HTTPS URL.
- [ ] Verify version.

  ```shell
  opt/gitlab/embedded/bin/go-crond --version
  ```

- [ ] Check service status

  ```shell
  sudo gitlab-ctl status crond
  sudo gitlab-ctl tail crond
  ```

- [ ] Set crontab entry to a few minutes ahead and make sure cert request renewal occurs

  ```shell
  cat /var/opt/gitlab/crond/letsencrypt-renew
  27 0 */4 * * root /opt/gitlab/bin/gitlab-ctl renew-le-certs
  sudo vi /var/opt/gitlab/crond/letsencrypt-renew
  cat var/opt/gitlab/crond/letsencrypt-renew
  30 18 26 * * root /opt/gitlab/bin/gitlab-ctl renew-le-certs
  sudo gitlab-ctl restart crond
  sudo gitlab-ctl tail crond
  sudo gitlab-ctl tail crond | grep "/opt/gitlab/bin/gitlab-ctl renew"
  ```
````
