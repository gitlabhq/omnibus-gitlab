# Unicorn settings

If you need to adjust the Unicorn timeout or the number of workers you can use
the following settings in `/etc/gitlab/gitlab.rb`.
Run `sudo gitlab-ctl reconfigure` for the change to take effect.

```ruby
unicorn['worker_processes'] = 3
unicorn['worker_timeout'] = 60
```

NOTE: **Note:** Minimum required `worker_processes` is 2 in order for the web editor to work correctly, see [GitLab issue #14546](https://gitlab.com/gitlab-org/gitlab/issues/14546) for details.

CAUTION: **Caution:** Be sure to review [recommended number of Unicorn Workers](https://docs.gitlab.com/ee/install/requirements.html#unicorn-workers)
before changing.
