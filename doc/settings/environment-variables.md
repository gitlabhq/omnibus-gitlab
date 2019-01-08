# Setting custom environment variables

If necessary you can set custom environment variables to be used by Unicorn,
Sidekiq, Rails and Rake via `/etc/gitlab/gitlab.rb`.  This can be useful in
situations where you need to use a proxy to access the internet and you will be
wanting to clone externally hosted repositories directly into gitlab.  In
`/etc/gitlab/gitlab.rb` supply a `gitlab_rails['env']` with a hash value. For
example:

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "https://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "https://USERNAME:PASSWORD@example.com:8080"
}
```

You can also override environment variables from other GitLab components which
might be required if you are behind a proxy:

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "https://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "https://USERNAME:PASSWORD@example.com:8080",
    "no_proxy" => "unix"  # Workaround for https://gitlab.com/gitlab-org/gitaly/issues/1447
}

gitlab_workhorse['env'] = {
    "http_proxy" => "https://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "https://USERNAME:PASSWORD@example.com:8080"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "https://USERNAME:PASSWORD@example.com:8080",
    "https_proxy" => "https://USERNAME:PASSWORD@example.com:8080"
}
```

NOTE: **Note**: The `no_proxy` entry for Gitaly is needed in GitLab 11.6
and newer if a proxy is defined and Gitaly is listening on a UNIX
socket, which it is by default. It appears to be a limitation in the
gRPC client library. See [the Gitaly
issue]([https://gitlab.com/gitlab-org/gitaly/issues/1447]) for more
details.

NOTE: **Note**: GitLab 11.6 and newer will attempt to use HTTP Basic
Authentication when a username and password is included in the proxy
URL. Older GitLab versions will omit the authentication details.

NOTE: **Note**: Proxy settings use the `.` syntax for globing.

## Applying the changes

Any change made to the environment variables **requires a hard restart** after
reconfigure for it to take effect.

NOTE: **Note**: During a hard restart, your GitLab instance will be down until the
services are back up.

So, after editing `gitlab.rb` file, run the following commands

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```
