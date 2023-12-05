---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Handle vulnerabilities detected by dependency scanning

A scheduled pipeline runs `dependency_scanning` job every night. This job adds new
vulnerabilities to the
[Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report/).

Slack notifications tell `#g_distribution` on Slack when new
vulnerabilities are detected. Complete the following steps when you receive this notification.

1. Visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report)
   and locate the appropriate vulnerability. If the vulnerability is legitimate:

   - Select `Create Issue` to open a confidential issue in the
   [`omnibus-gitlab` issue tracker](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/).
   - Change the vulnerability status to `Confirmed`. If the vulnerability turns
   out to be a false positive, duplicate, or otherwise not actionable, change the
   status to `Dismiss`.

1. Label the issue with the `security` and `For Scheduling` labels. The GitLab
   Security team is then made aware of this issue due to the automation by
   [escalator](https://gitlab.com/gitlab-com/gl-security/automation/escalator).

1. The Security team triages and schedules the issue with the help of Distribution.

1. If the issue is actionable for us, the Security team:

   - Schedules the issue based on its severity and priority.
   - Creates the needed merge requests (MRs) to target all relevant branches.

1. After the MR that fixes the vulnerability has been merged, and the corresponding
   issue is closed:

   - Visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report).
   - Locate the appropriate vulnerability and set the status to `Resolved` if not
   already done automatically.

1. If the issue is a no-op for our use case, set its status to `Dismissed` in the
   [Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report)
   page and close the corresponding issue.
