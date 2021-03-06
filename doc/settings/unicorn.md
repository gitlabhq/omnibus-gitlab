---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Unicorn settings

NOTE:
Starting with GitLab 13.0, Puma is the default web server and Unicorn has been
disabled by default.

## Enabling Unicorn

To use Unicorn instead of Puma, add the following to `/etc/gitlab/gitlab.rb` and
run `sudo gitlab-ctl reconfigure`

```ruby
puma['enable'] = false
unicorn['enable'] = true
```

### Adjusting workers or timeout

If you need to adjust the Unicorn timeout or the number of workers you can use
the following settings in `/etc/gitlab/gitlab.rb`.
Run `sudo gitlab-ctl reconfigure` for the change to take effect.

```ruby
unicorn['worker_processes'] = 3
unicorn['worker_timeout'] = 60
```

NOTE:
Minimum required `worker_processes` is 2 in order for the web editor to work correctly, see [GitLab issue #14546](https://gitlab.com/gitlab-org/gitlab/-/issues/14546) for details.

WARNING:
Be sure to review [recommended number of Unicorn Workers](https://docs.gitlab.com/ee/install/requirements.html#unicorn-workers)
before changing.
