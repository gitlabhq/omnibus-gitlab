---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Handling broken master pipelines
---

We run [nightly pipelines](pipelines.md#scheduled-pipelines) for
building both CE and EE package in our Release mirror: `https://dev.gitlab.org/gitlab/omnibus-gitlab`.
This mirror is configured to send pipeline failure notifications to
`#g_distribution` channel on Slack. A broken `master` pipeline gets priority over
other scheduled work as per our [development guidelines](https://handbook.gitlab.com/handbook/engineering/workflow/#resolution-of-broken-master).

## Jobs are stuck due to no runners being active

This is a transient error due to connection issues between runner manager
machine and `dev.gitlab.org`.

1. Sign in to [runner manager machine](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/maintenance/build-infrastructure/#runner-manager-machines).
1. Run the following command to force a connection between runner and GitLab

   ```shell
   sudo gitlab-runner verify
   ```
