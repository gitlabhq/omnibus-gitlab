<!--
# README first!
This MR should be created on https://gitlab.com/gitlab-org/security/omnibus-gitlab/

See [the general developer security release guidelines](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md).

This merge request _must not_ close the corresponding security issue _unless_ it
targets master.

-->

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Developer checklist

- [ ] Link to the developer security workflow issue on [`security/omnibus-gitlab`](https://gitlab.com/gitlab-org/security/omnibus-gitlab)
- [ ] MR targets `master`, or `X-Y-stable` for backports
- [ ] Milestone is set for the version this MR applies to
- [ ] Title of this MR is the same as for all backports
- [ ] A [CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html) is added without a `merge_request` value, with `type` set to `security`
- [ ] Add a link to this MR in the `links` section of related issue
- [ ] Add a link to an EE MR if required
- [ ] Assign to a reviewer

## Reviewer checklist

- [ ] Correct milestone is applied and the title is matching across all backports
- [ ] Assigned to `@gitlab-release-tools-bot` with passing CI pipelines

/label ~security
