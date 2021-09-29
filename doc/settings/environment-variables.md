---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Setting custom environment variables **(FREE SELF)**

If necessary you can set custom environment variables to be used by Puma,
Sidekiq, Rails and Rake via `/etc/gitlab/gitlab.rb`. This can be useful in
situations where you need to use a proxy to access the internet and need to
clone externally hosted repositories directly into GitLab. In
`/etc/gitlab/gitlab.rb` supply a `gitlab_rails['env']` with a hash value. For
example:

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
#    "no_proxy" => ".yourdomain.com"  # Wildcard syntax if you need your internal domain to bypass proxy
}
```

You can also override environment variables from other GitLab components which
might be required if you are behind a proxy:

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
}

gitlab_workhorse['env'] = {
    "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
}

gitlab_pages['env'] = {
    "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
}
```

GitLab 11.6 and newer will attempt to use HTTP Basic
Authentication when a username and password is included in the proxy
URL. Older GitLab versions will omit the authentication details.

Proxy settings use the `.` syntax for globing.

Proxy URL values should generally be `http://` only, unless
your proxy has its own SSL certificate and SSL enabled. This means, even for
the `https_proxy` value, you should usually specify a value as
`http://USERNAME:PASSWORD@example.com:8080`.

## Applying the changes

Any change made to the environment variables **requires a hard restart** after
reconfigure for it to take effect.

NOTE:
During a hard restart, your GitLab instance will be down until the
services are back up.

Perform a reconfigure:

```shell
sudo gitlab-ctl reconfigure
```
