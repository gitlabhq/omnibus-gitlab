---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test plan for `exiftool` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

```markdown
## Test Plan

- [ ] Built on all supported platforms
- [ ] Ran `Trigger:ee-package` and then `qa-subset-test` as well as manual `qa-remaining-test-manual` CI jobs on `gitlab.com`.
- [ ] No observable breaking changes at [history](https://exiftool.org/history.html).
- [ ] Verified installed version: `exiftool -ver`
- [ ] Test
  - [ ] Uploaded image to issue.
  - [ ] Downloaded image from issue.
  - [ ] Verified downloaded issue has no metadata.
  - [ ] Equivalent update MR in CNG
```
