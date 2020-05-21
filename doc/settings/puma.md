# Puma

NOTE: **Note:**
Starting with GitLab 13.0, Puma is the default web server and Unicorn has been
disabled by default.

## Configuring Puma settings

1. Determine suitable Puma worker and thread settings. For details, see [Puma settings](https://docs.gitlab.com/ee/install/requirements.html#puma-settings).
1. Convert custom Unicorn settings to the equivalent Puma settings (if applicable). For details, see [Converting Unicorn settings to Puma](#converting-unicorn-settings-to-puma).
1. For multi-node deployments, configure the load balancer to use the [readiness check](https://https://docs.gitlab.com/ee/administration/high_availability/load_balancer.html#readiness-check).
1. Reconfigure GitLab so the above changes take effect.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

For more details, see the [Puma documentation](https://github.com/puma/puma#configuration).

## Converting Unicorn settings to Puma

If you are still running Unicorn and would like to switch to Puma, server configuration
will _not_ carry over automatically. The table below summarizes which Unicorn configuration keys
correspond to those in Puma, and which ones have no corresponding counterpart.

| Unicorn                              | Puma                               |
| ------------------------------------ | ---------------------------------- |
| `unicorn['enable']`                  | `puma['enable']`                   |
| `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
| `unicorn['worker_processes']`        | `puma['worker_processes']`         |
| n/a                                  | `puma['ha']`                       |
| n/a                                  | `puma['min_threads']`              |
| n/a                                  | `puma['max_threads']`              |
| `unicorn['listen']`                  | `puma['listen']`                   |
| `unicorn['port']`                    | `puma['port']`                     |
| `unicorn['socket']`                  | `puma['socket']`                   |
| `unicorn['pidfile']`                 | `puma['pidfile']`                  |
| `unicorn['tcp_nopush']`              | n/a                                |
| `unicorn['backlog_socket']`          | n/a                                |
| `unicorn['somaxconn']`               | n/a                                |
| n/a                                  | `puma['state_path']`               |
| `unicorn['log_directory']`           | `puma['log_directory']`            |
| `unicorn['worker_memory_limit_min']` | n/a                                |
| `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
| `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
| `unicorn['exporter_address']`        | `puma['exporter_address']`         |
| `unicorn['exporter_port']`           | `puma['exporter_port']`            |

## Puma Worker Killer

By default, the [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) will restart
a worker if it exceeds a [memory limit](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/cluster/puma_worker_killer_initializer.rb). Additionally, rolling restarts of
Puma workers are performed every 12 hours.

To change the memory limit setting:

```ruby
puma['per_worker_max_memory_mb'] = 850
```

## Worker timeout

Unlike Unicorn, the `puma['worker_timeout']` setting does not set maximum request duration.
A [timeout of 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb)
is used when Puma is enabled. This limit is not configurable.
