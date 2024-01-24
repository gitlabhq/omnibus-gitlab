---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Action Cable

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Action Cable is a Rails engine that handles websocket connections.

## Configuring the worker pool size

Action Cable uses a separate thread pool per Puma worker. The number of threads can be configured
using the `actioncable['worker_pool_size']` option.
