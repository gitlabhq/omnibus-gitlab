---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `curl` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked curl [changelog](https://curl.se/ch/) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- Test the library:
  - [ ] `version`

    ```shell
    IMAGE='registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:renovate-curl-curl-8-x'
    
    docker run -it --rm --platform="linux/amd64" \
    $IMAGE curl --version | head -n1
    ```

  - [ ] `execution`

    ```shell
    docker run -it --rm --platform="linux/amd64" \
    $IMAGE curl -L -so /dev/null -w "%{http_code}\n" gitlab.com
    
    200
    ```
````
