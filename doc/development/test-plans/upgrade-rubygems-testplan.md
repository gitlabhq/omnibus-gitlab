---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `rubygems` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked rubygems [changelog](https://github.com/rubygems/rubygems/blob/master/CHANGELOG.md) for potential breaking changes.
- [ ] Checked that the `bundler` gem was updated to the corresponding version
  noted in the changelog.
- [ ] Checked that the `BUNDLED_WITH` version in the `Gemfile.lock` was updated
  to the corresponding version noted in the changelog.
- [ ] Performed a successful GitLab Enterprise Edition (EE) build on `gitlab.com`
  on all supported platforms (include `build-package-on-all-os` job).
- [ ] Ran `qa-subset-test` as well as manual `qa-remaining-test-manual` CI/CD
  test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Performed a successful GitLab Community Edition (CE) build on
  `dev.gitlab.org`.
- Checked installed gem versions:
  - [ ] `rubygems`

    ```shell
    gem list rubygems
    ```

  - [ ] `bundler`

    ```shell
    gem list bundler
    ```
````
