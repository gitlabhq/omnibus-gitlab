# Puma

NOTE: **Note** Puma support is EXPERIMENTAL at this time. We do not
recommend using it in production yet.

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
puma['min_threads'] = 1
puma['max_threads'] = 16
```

For more details, see the [Puma documentation](https://github.com/puma/puma#configuration).

## Puma Worker Killer

By default, the [Puma Worker
Killer](https://github.com/schneems/puma_worker_killer) will restart a
worker if it exceeds a 650 MB in RAM usage. To change this setting:

```ruby
puma['per_worker_max_memory_mb'] = 650
```
