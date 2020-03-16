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

## Puma Worker Killer

By default, the [Puma Worker
Killer](https://github.com/schneems/puma_worker_killer) will restart a
worker if it exceeds a [memory limit][mem-limit] To change this setting:

```ruby
puma['per_worker_max_memory_mb'] = 850
```

[mem-limit]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib%2Fgitlab%2Fcluster%2Fpuma_worker_killer_initializer.rb
