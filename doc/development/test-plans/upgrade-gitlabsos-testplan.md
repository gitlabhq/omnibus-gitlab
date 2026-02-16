---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `gitlabsos` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check [`gitlabsos` project repository](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos) for potential breaking changes.
- [ ] Green pipeline with `Trigger:ee-package` and `build-package-on-all-os`.
- [ ] Install the package and run `sudo gitlabsos`. It will take a few minutes to complete:

  ```shell
  sudo gitlabsos
  ```

- [ ] Ensure that it generates a tarball with sanitized configuration:

  ```plaintext
  [2025-08-05T15:04:08.463861] INFO -- gitlabsos: Sanitizer module found. GitLab configuration files will be collected.
  [2025-08-05T15:04:08.463926] INFO -- gitlabsos: A copy will be printed on the screen for you to review.
  [2025-08-05T15:04:08.471654] INFO -- gitlabsos: Sanitizing /etc/gitlab/gitlab.rb file
  Sanitizing /etc/gitlab/gitlab.rb...done!

  ===================== Sanitized /etc/gitlab/gitlab.rb =====================
  PLEASE CAREFULLY REVIEW THIS FILE FOR ANY SENSITIVE INFO
  THE BELOW INFO WILL BE INCLUDED (SANITIZED) IN YOUR GITLABSOS ARCHIVE
  =====================================================================
  ```

- [ ] Ensure that the tarball can be extracted.

  ```shell
  tar xzvf gitlabsos.*
  ```

- [ ] Extract the tarball and make sure that it contains `var/log/gitlab` and other files.
