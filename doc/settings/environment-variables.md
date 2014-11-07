# Setting custom environment variables

If necessary you can set custom environment variables to be used by Unicorn,
Sidekiq, Rails and Rake via `/etc/gitlab/gitlab.rb`.  This can be useful in
situations where you need to use a proxy to access the internet and you will be
wanting to clone externally hosted repositories directly into gitlab.  In
`/etc/gitlab/gitlab.rb` supply a `gitlab_rails['env']` with a hash value. For
example:

```ruby
gitlab_rails['env'] = {"http_proxy" => "my_proxy", "https_proxy" => "my_proxy"}
```

For GitLab CI, use `gitlab_ci['env']`:

```ruby
gitlab_ci['env'] = {"my_var" => "my value"}
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.
