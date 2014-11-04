# Unicorn settings

If you need to adjust the Unicorn timeout or the number of workers you can use
the following settings in `/etc/gitlab/gitlab.rb`. Run `sudo gitlab-ctl
reconfigure for the change to take effect.

```ruby
unicorn['worker_processes'] = 3
unicorn['worker_timeout'] = 60
```

To adjust Unicorn settings for GitLab CI, use the `ci_unicorn` directive in
`/etc/gitlab/gitlab.rb`.

```ruby
ci_unicorn['worker_processes'] = 3
```
