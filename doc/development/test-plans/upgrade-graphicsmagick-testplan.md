---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `graphicsmagick` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked GraphicsMagick [changelog](https://sourceforge.net/p/graphicsmagick/code/ci/default/tree/ChangeLog) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- [ ] Ran `qa-subset-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Tested the library using container from MR pipeline:
  - [ ] Check version:

    ```shell
    IMAGE='registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:<MR-BRANCH-NAME>'

    docker run -it --rm --platform="linux/amd64" \
      $IMAGE /opt/gitlab/embedded/bin/gm version
    ```

  - [ ] Test PNG image processing:

    ```shell
    docker run -it --rm --platform="linux/amd64" \
      $IMAGE bash

    # Get a suitable PNG to manipulate
    cp \
      /opt/gitlab/embedded/lib/ruby/*/rdoc/generator/template/darkfish/images/date.png \
      /tmp/date.png

    /opt/gitlab/embedded/bin/gm mogrify \
      -rotate 180 \
      -fill white \
      /tmp/date.png

    ; echo $?
    ```

    Result should be `0`. Retrieve modified "upside-down" PNG and confirm that it has been modified.

  - [ ] Test JPEG image processing:

    ```shell
    # Inside the container from previous step
    /opt/gitlab/embedded/bin/gm convert \
      /tmp/date.png \
      /tmp/test.jpg

    /opt/gitlab/embedded/bin/gm identify /tmp/test.jpg
    # Should display JPEG image information without errors
    ```

  - [ ] Test TIFF image support:

    ```shell
    # Inside the container from previous step
    /opt/gitlab/embedded/bin/gm convert \
      /tmp/date.png \
      /tmp/test.tiff

    /opt/gitlab/embedded/bin/gm identify /tmp/test.tiff
    # Should display TIFF image information without errors
    ```

- [ ] Verified image upload and processing in deployed GitLab instance:
  - [ ] Upload PNG image to issue.
  - [ ] Upload JPEG image to issue.
  - [ ] Upload avatar image to user profile.
  - [ ] Verify images display correctly.
  - [ ] Download images and verify they are processed correctly.
- [ ] Equivalent update MR in CNG (if applicable).
````
