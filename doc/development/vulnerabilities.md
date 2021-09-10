# Handling vulnerabilities detected by `dependency_scanning` job

A scheduled pipeline runs `dependency_scanning` job nightly, and results in new
vulnerabilities, if any, being added to the
[Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report/).

Slack notifications have been configured to inform `#g_distribution` when new
vulnerabilities are detected. The steps mentioned below needs to be followed
once such a notification is received:

1. Visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report),
   locate the appropriate vulnerability. If the vulnerability appears to be
   legitimate, use the `Create Issue` button to open a confidential issue in the
   [`omnibus-gitlab` issue tracker](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/).
   Additionally, change the vulnerability status to `Confirmed`. In the event
   that it is a false positive, duplicate, or otherwise not actionable please
   change the status to `Dismiss`.

1. Label the issue with the `security` and `For Scheduling` labels. The GitLab
   Security team will be made aware of this issue, thanks to the automation in
   place by [escalator](https://gitlab.com/gitlab-com/gl-security/automation/escalator).

1. Security team, with the help of Distribution, triages the issue and schedules
   it accordingly.

1. If the issue is found out to be actionable for us, it goes through the
   regular scheduling process based on its severity and priority and gets
   necessary MRs (targeting master and relevant backport stable branches).

1. Once the MR fixing the vulnerability has been merged and corresponding issue
   closed, visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report),
   locate the appropriate vulnerability and set the status to `Resolved` if not
   already done automatically.

1. If the issue is found out to be a no-op for our usecase, set its status to
   `Dismissed` in the [Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report)
   page and close the corresponding issue.
