---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# `<component name>` component upgrade test plan

Copy the following test plan to a comment of the merge request that upgrades the component.

```markdown
## Test plan

At a minimum, the following test should be run:

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms.
- [ ] Ran `qa-subset-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- [ ] Installed and verified that the component version has been upgraded.
- [ ] Verified basic functionality of the software component.
```
