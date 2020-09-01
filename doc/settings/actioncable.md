---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# ActionCable

NOTE: **Note:**
ActionCable is **experimental**, and enabling it in the in-app mode also enables experimental features.

This service is disabled by default. To enable:

```ruby
actioncable['enable'] = true
```

By default, ActionCable is run as a separate Puma server that only handles websocket connections. To run ActionCable on
the existing Puma web server:

```ruby
actioncable['in_app'] = true
```

Note: Action Cable is currently not supported for the Unicorn web server in GitLab.

## Configuring the worker pool size

ActionCable uses a separate thread pool to handle the websocket connections. The number of threads can be configured
using the `actioncable['worker_pool_size']` option.
