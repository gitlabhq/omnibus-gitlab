---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `libpng` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked [libpng changelog](https://github.com/pnggroup/libpng) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- [ ] Checked the library version:
  - [ ] Install `binutils`.
  - [ ] Check output and ensure the updated version is installed.
    ```shell
    strings /opt/gitlab/embedded/lib/libpng16.so.16|grep "libpng version"
    ```
- [ ] Check that graphicsMagick can use `libpng` with a PNG:
  ```shell
  # get a suitable PNG to manipulate
  cp \
    /opt/gitlab/embedded/lib/ruby/3.2.0/rdoc/generator/template/darkfish/images/date.png \
    /tmp/date.png

  /opt/gitlab/embedded/bin/gm mogrify \
    -rotate 180 \
    -fill white \
    /tmp/date.png

  ; echo $?
  ```

  result should be `0`

  retrieve modified "upside-down" PNG and confirm that indeed it has been modified.
````
