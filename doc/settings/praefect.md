---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly Cluster
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

[Gitaly Cluster](https://docs.gitlab.com/administration/gitaly/praefect/) provides
fault-tolerant storage for repositories. It uses Praefect as a router and transaction manager for
Gitaly.

## Enable Gitaly Cluster

By default, Gitaly Cluster is not enabled. For information on enabling Gitaly Cluster, see
the Gitaly Cluster [setup instructions](https://docs.gitlab.com/administration/gitaly/praefect/#setup-instructions).

## Update GitLab when Gitaly Cluster is enabled

For information on updating GitLab with Gitaly Cluster enabled, see the
[specific instructions](https://docs.gitlab.com/update/zero_downtime/#gitaly-cluster).
