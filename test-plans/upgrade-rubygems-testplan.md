# `rubygems` component upgrade test plan

<!-- Copy and paste the following into your MR description. -->
## Test plan

- [ ] Checked rubygems [changelog](https://github.com/rubygems/rubygems/blob/master/CHANGELOG.md) for potential breaking changes.
- [ ] Checked that the `bundler` gem was updated to the corresponding version
  noted in the changelog.
- [ ] Checked that the `BUNDLED_WITH` version in the `Gemfile.lock` was updated
  to the corresponding version noted in the changelog.
- [ ] Performed a successful GitLab Enterprise Edition (EE) build on gitlab.com
  on all supported platforms (include `build-package-on-all-os` job).
- [ ] Ran `qa-subset-test` as well as manual `qa-remaining-test-manual` CI/CD
  test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Performed a successful GitLab Community Edition (CE) build on
  dev.gitlab.org.
- Checked installed gem versions:

  - [ ] `rubygems`

    ```shell
    gem list rubygems
    ```

  - [ ] `bundler`

    ```shell
    gem list bundler
    ```
