# Handling broken master pipelines

We currently run [nightly pipelines](pipelines.md#scheduled-pipelines) for
building both CE and EE package in [our Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).
This mirror is configured to send pipeline failure notifications to
`#g_distribution` channel on Slack. A broken master pipeline gets priority over
other scheduled work as per our [development guidelines](https://about.gitlab.com/handbook/engineering/workflow/#resolution-of-broken-master).

## `dependency_scanning` job failed due to one of the dependencies being reported as vulnerable

1. Check the job log and find out which component is marked `Vulnerable`

1. Visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report), locate the appropriate
   vulnerability. If the vulnerability appears to be legitimate, use the `Create Issue` button to open a confidential issue in the
   [`omnibus-gitlab` issue tracker](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/). Additionally, change the vulnerability status to `Confirmed`. In
   the event that it is a false positive, duplicate, or otherwise not actionable please change the status to `Dismiss`.

1. Label the issue with the `security` and `For Scheduling` labels. The GitLab
   Security team will be made aware of this issue, thanks to the automation in
   place by [escalator](https://gitlab.com/gitlab-com/gl-security/automation/escalator).

1. Once an issue has been filed, ask a
   [Maintainer of the project](https://about.gitlab.com/handbook/engineering/projects/#omnibus-gitlab)
   to add the CVE to the `CVEIGNORE` environment variable defined in the project
   settings, in [Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).
   This will ensure the master pipeline won't keep failing and flood the Slack
   channel with notifications while we triage the issue based on severity, and
   priority.

1. Security team, with the help of Distribution, triages the issue and schedules
   it accordingly.

1. If the issue is found out to be a no-op for our usecase, open
   an MR adding the variable to the [`.cveignore`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/.cveignore)
   file.

1. If the issue is found out to be actionable for us, it goes through the
   regular scheduling process based on its severity and priority and gets
   necessary MRs (targeting master and relevant backport stable branches).

1. Ensure the entry is removed from the `CVEIGNORE` variable once the MRs have
   been merged. This handles the edge false-negative case where a vulnerability
   might affect multiple components and only one of them was fixed by an MR. Removing
   an item from the `.cveignore` file can be done through a public MR to the Omnibus
   repository.

1. Visit the [Omnibus Vulnerability Report](https://gitlab.com/gitlab-org/omnibus-gitlab/-/security/vulnerability_report), locate the appropriate
   vulnerability and set the status to `Resolved`.

## Jobs are stuck due to no runners being active

This is a transient error due to connection issues between runner manager
machine and `dev.gitlab.org`.

1. Sign in to [runner manager machine](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/maintenance/build-machines.html#build-runnersgitlaborg).

1. Run the following command to force a connection between runner and GitLab

    ```shell
    sudo gitlab-runner verify
    ```
