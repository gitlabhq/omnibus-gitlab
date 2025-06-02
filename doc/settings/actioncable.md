---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Action Cable
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Action Cable is a Rails engine that handles websocket connections.

## Configuring the worker pool size

Action Cable uses a separate thread pool per Puma worker. The number of threads can be configured
using the `actioncable['worker_pool_size']` option.
