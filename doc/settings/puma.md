# Puma

Puma is a multi-threaded HTTP 1.1 server for Ruby applications. To
enable Puma, be sure to disable Unicorn:

```ruby
unicorn['enable'] = false
puma['enable'] = true
```

## Puma settings

If you need to adjust the Puma timeout, the number of workers, or the
number of threads Puma should use, you can use the following settings in
`/etc/gitlab/gitlab.rb`. Run `sudo gitlab-ctl reconfigure` for the
change to take effect.

```ruby
puma['worker_processes'] = 3
puma['worker_timeout'] = 60
puma['min_threads'] = 4
puma['max_threads'] = 4
```

For more details, see the [Puma documentation](https://github.com/puma/puma#configuration).

## Puma with Rugged

For GitLab installations with slower NFS drives, [Direct Git Access](https://docs.gitlab.com/ee/administration/gitaly/#direct-git-access-in-gitlab-rails)(using [Rugged](https://github.com/libgit2/rugged)) can provide improved performance. Previously when using [Unicorn](unicorn.md) this feature was automatically enabled when available, unless otherwise disabled by a [feature flag](https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code).

Due to the multi-threading model of Puma, Direct Git Access [negatively impacts Puma performance](https://docs.gitlab.com/ee/administration/operations/puma.html#performance-caveat-when-using-puma-with-rugged), and is automatically disabled when the thread count is greater than 1. If you still need to use Rugged,
it is recommended to set the number of Puma threads to be 1.

```ruby
puma['worker_processes'] = 4 # same value as `unicorn['worker_processes']`
puma['worker_timeout'] = 60
puma['min_threads'] = 1
puma['max_threads'] = 1
```

To force Rugged usage with multi-threaded Puma, which is not recommended, you can use a [feature flag](https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code).

## Converting Unicorn settings to Puma

If you are still running Unicorn and would like to switch to Puma, server configuration
will _not_ carry over automatically. The table below summarizes which Unicorn configuration keys
correspond to those in Puma, and which ones have no corresponding counterpart.

<!-- markdownlint-disable MD044 -->
| Unicorn                            | Puma                             |
| ---------------------------------- | -------------------------------- |
| unicorn[`enable`]                  | puma[`enable`]                   |
| unicorn[`worker_timeout`]          | puma[`worker_timeout`]           |
| unicorn[`worker_processes`]        | puma[`worker_processes`]         |
| n/a                                | puma[`ha`]                       |
| n/a                                | puma[`min_threads`]              |
| n/a                                | puma[`max_threads`]              |
| unicorn[`listen`]                  | puma[`listen`]                   |
| unicorn[`port`]                    | puma[`port`]                     |
| unicorn[`socket`]                  | puma[`socket`]                   |
| unicorn[`pidfile`]                 | puma[`pidfile`]                  |
| unicorn[`tcp_nopush`]              | n/a                              |
| unicorn[`backlog_socket`]          | n/a                              |
| unicorn[`somaxconn`]               | n/a                              |
| n/a                                | puma[`state_path`]               |
| unicorn[`log_directory`]           | puma[`log_directory`]            |
| unicorn[`worker_memory_limit_min`] | n/a                              |
| unicorn[`worker_memory_limit_max`] | puma[`per_worker_max_memory_mb`] |
| unicorn[`exporter_enabled`]        | puma[`exporter_enabled`]         |
| unicorn[`exporter_address`]        | puma[`exporter_address`]         |
| unicorn[`exporter_port`]           | puma[`exporter_port`]            |
<!-- markdownlint-enable MD044 -->

## Puma Worker Killer

By default, the [Puma Worker
Killer](https://github.com/schneems/puma_worker_killer) will restart a
worker if it exceeds a [memory limit][mem-limit] To change this setting:

```ruby
puma['per_worker_max_memory_mb'] = 850
```

[mem-limit]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib%2Fgitlab%2Fcluster%2Fpuma_worker_killer_initializer.rb
