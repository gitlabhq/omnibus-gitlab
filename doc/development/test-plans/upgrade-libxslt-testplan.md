---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `libxslt` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked `libxslt` [changelog](https://gitlab.gnome.org/GNOME/libxslt/-/blob/master/NEWS) for potential breaking changes and security fixes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`. 
- [ ] Deploy GitLab. 

### Verify libxslt version and dependencies

- [ ] Check the library version. The command gives the compiled-in version number, which needs to be converted to semantic version format:
  ```shell
  /opt/gitlab/embedded/bin/xsltproc --version
  ```
  - [ ] Major version = version / 10000
  - [ ] Minor version = (version % 10000) / 100
  - [ ] Patch version = version % 100
  - [ ] Example: version 10143
    - 10143 / 10000 = 1.0143 --> 1
    - (10143 % 10000) / 100 = 1.43 --> 1
    - (10143 % 100) = 43 --> 43
    - Version is 1.1.43

### Test functionality

- [ ] Create a project and issue to test Markdown rendering with inline HTML:

  ```markdown
  ## Test HTML in Markdown
  
  <details>
  <summary>Click to expand</summary>
  
  This is **Markdown** with <em>HTML</em> tags.
  
  </details>
  
  <dl>
    <dt>Definition</dt>
    <dd>Description with <strong>formatting</strong></dd>
  </dl>
  ```

- [ ] Test RSS/Atom feed:

  ```shell
  export GITLAB_URL="https://your-gitlab-instance"
  export TEST_PROJECT="your-test-project"
  export NAMESPACE="your-root-user" # This can also be a group you created to host the project.
  curl -s "${GITLAB_URL}/${NAMESPACE}/${TEST_PROJECT}.atom"
  ```

````
