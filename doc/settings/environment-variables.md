# Setting custom environment variables

If necessary you can set custom environment variables to be used by Unicorn,
Sidekiq, Rails and Rake via `/etc/gitlab/gitlab.rb`.  This can be useful in
situations where you need to use a proxy to access the internet and you will be
wanting to clone externally hosted repositories directly into gitlab.  In
`/etc/gitlab/gitlab.rb` supply a `gitlab_rails['env']` with a hash value. For
example:

```ruby
gitlab_rails['env'] = {
    "http_proxy" => "my_proxy",
    "https_proxy" => "my_proxy"
}
```

You can also override environment variables from other GitLab components which
might be required if you are behind a proxy:

```ruby
# Needed for proxying Git clones
gitaly['env'] = {
    "http_proxy" => "my_proxy",
    "https_proxy" => "my_proxy"
}

gitlab_workhorse['env'] = {
    "http_proxy" => "my_proxy",
    "https_proxy" => "my_proxy"
}

# If you use the docker registry
registry['env'] = {
    "http_proxy" => "my_proxy",
    "https_proxy" => "my_proxy"
}
```

## Applying the changes

Any change made to the environment variables **requires a hard restart** after
reconfigure for it to take effect.

**`Note`**: During a hard restart, your GitLab instance will be down until the
services are back up.

So, after editing `gitlab.rb` file, run the following commands

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```
