# Redis settings

## Using a non-packaged Redis instance

If you want to use your own Redis instance instead of the bundled Redis, you
can use the `gitlab.rb` settings below. Run `gitlab-ctl reconfigure` for the
settings to take effect.

```ruby
redis['enable'] = false

# Redis via TCP
gitlab_rails['redis_host'] = 'redis.example.com'
gitlab_rails['redis_port'] = 6380

# OR Redis via Unix domain sockets
gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket
```

For GitLab CI, use `ci_redis` and `gitlab_ci` instead:

```ruby
ci_redis['enable'] = false

gitlab_ci['redis_host'] = 'ci-redis.example.com'
```

Note that GitLab and GitLab CI are not designed to share a single Redis
instance. This is why omnibus-gitlab has separate `redis` and `ci_redis`
services.

## Making a bundled Redis instance reachable via TCP

Use the following settings if you want to make one of the Redis instances
managed by omnibus-gitlab reachable via TCP.

```ruby
redis['port'] = 6379
redis['bind'] = '127.0.0.1'
```
