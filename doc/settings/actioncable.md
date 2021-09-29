---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Action Cable **(FREE SELF)**

NOTE:
Action Cable is **experimental**, and enabling it also enables experimental features.

This service is disabled by default. To enable:

```ruby
actioncable['enable'] = true
```

## Configuring the worker pool size

Action Cable uses a separate thread pool to handle the websocket connections. The number of threads can be configured
using the `actioncable['worker_pool_size']` option.
