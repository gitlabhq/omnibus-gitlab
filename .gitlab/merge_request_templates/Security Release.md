<!--
# README first!
This MR should be created on https://gitlab.com/gitlab-org/security/omnibus-gitlab/

See [the general developer security release guidelines](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md).
-->

## Related issues

<!-- Mention the GitLab Security issue this MR is related to -->

## Developer checklist

- [ ] **On "Related issues" section, write down the [Omnibus GitLab Security] issue it belongs to (i.e. `Related to <issue_id>`).**
- [ ] MR targets `master`, or `X-Y-stable` for backports.
- [ ] Title of this MR is the same as for all backports.
- [ ] A [CHANGELOG entry] has been included, with `Changelog` trailer set to `security`.
- [ ] Assign to a reviewer and maintainer, per our [Code Review process].
- [ ] For the MR targeting `master`, ensure it's approved according to our [Approval Guidelines]
  - [ ] Approved by an AppSec engineer.
- [ ] Merge request _must not_ close the corresponding security issue, _unless_ it targets `master`.

## Reviewer checklist

- [ ] Assigned to `@gitlab-release-tools-bot` with passing CI pipelines

## AppSec checklist

- [ ] Assign the right [AppSecWeight](https://handbook.gitlab.com/handbook/security/product-security/application-security/milestone-planning/#weight-labels) label
- [ ] Update the `~AppSecWorkflow::in-progress` to `~AppSecWorkflow::complete`

/label ~security

<!-- AppSec specific labels -->

/label ~"division::Security" ~"Department::Product Security" ~"Application Security Team"
/label ~"AppSecWorkflow::in-progress" ~"AppSecWorkType::VulnFixVerification" 
/label ~"AppSecPriority::1" <!-- This is always a priority to review for us to ensure the fix is good and the release is done on time -->

[Omnibus GitLab Security]: https://gitlab.com/gitlab-org/security/omnibus-gitlab
[approval guidelines]: https://docs.gitlab.com/ee/development/code_review.html#approval-guidelines
[Code Review process]: https://docs.gitlab.com/ee/development/code_review.html
[quick actions]: https://docs.gitlab.com/ee/user/project/quick_actions.html#quick-actions-for-issues-merge-requests-and-epics
[CHANGELOG entry]: https://docs.gitlab.com/ee/development/changelog.html#overview

/assign me
