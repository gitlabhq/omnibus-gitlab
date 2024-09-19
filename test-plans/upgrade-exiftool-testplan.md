# `exiftool` component upgrade test plan 

## Test Plan

* [ ] Built on all supported platforms
* [ ] Ran `Trigger:ee-package` and then `qa-subset-test` as well as manual `qa-remaining-test-manual` CI jobs on `gitlab.com`.
* [ ] No observable breaking changes at [history](https://exiftool.org/history.html).
* [ ] Verified installed version: `exiftool -ver`
* [ ] Test
  * [ ] Uploaded image to issue.
  * [ ] Downloaded image from issue.
  * [ ] Verified downloaded issue has no metadata.
  * [ ] Equivalent update MR in omnibus