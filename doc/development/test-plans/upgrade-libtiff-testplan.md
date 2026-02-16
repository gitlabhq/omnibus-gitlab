---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `libtiff` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Checked libtiff [changelog](https://gitlab.com/libtiff/libtiff/) for potential breaking changes.
- [ ] Start a new pipeline and trigger `Trigger::ee-package`.
- [ ] Checked the library version:
  - [ ] Install `binutils`.
  - [ ] Check output and ensure the updated version is installed.

    ```shell
    strings /opt/gitlab/embedded/lib/libtiff.so|grep "LIBTIFF, Version"
    ```

- [ ] Check that graphicsMagick can use `libtiff` with a tiff:
  - [ ] Upload a tiff of your choice to the deployed GitLab container or
        virtual machine.
  - [ ] Execute graphicsMagick from the command line:

    ```shell
    /opt/gitlab/embedded/bin/gm identify /path/to/file.tiff
    ```
````
