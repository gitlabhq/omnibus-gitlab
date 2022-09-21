---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configuring Redis **(FREE SELF)**

## Using an alternate local Redis instance

Omnibus GitLab includes Redis by default. To direct the GitLab
application to your own *locally* running Redis instance:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Disable the bundled Redis
   redis['enable'] = false

   # Redis via TCP
   gitlab_rails['redis_host'] = '127.0.0.1'
   gitlab_rails['redis_port'] = 6379

   # OR Redis via Unix domain sockets
   gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket

   # Password to Authenticate to alternate local Redis if required
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Making the bundled Redis reachable via TCP

Use the following settings if you want to make the Redis instance
managed by Omnibus GitLab reachable via TCP:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   redis['port'] = 6379
   redis['bind'] = '127.0.0.1'
   ```

1. Save the file and reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Setting up a Redis-only server using Omnibus GitLab

If you'd like to set up Redis in a separate server than the GitLab application,
you can use the
[bundled Redis in Omnibus GitLab](https://docs.gitlab.com/ee/administration/redis/standalone.html).

## Running with multiple Redis instances

See <https://docs.gitlab.com/ee/administration/redis/replication_and_failover.html#running-multiple-redis-clusters>.

## Redis Sentinel

See <https://docs.gitlab.com/ee/administration/redis/replication_and_failover.html>.

## Using Redis in a failover setup

See <https://docs.gitlab.com/ee/administration/redis/replication_and_failover.html>.

## Using Google Cloud Memorystore

Google Cloud Memorystore [does not support the Redis `CLIENT` command](https://cloud.google.com/memorystore/docs/redis/product-constraints#blocked_redis_commands).
By default, Sidekiq will attempt to set the `CLIENT` for debugging
purposes. This can be disabled via the following configuration setting:

```ruby
gitlab_rails['redis_enable_client'] = false
```

## Increasing the number of Redis connections beyond the default

By default Redis will only accept 10,000 client connections. If you need
more that 10,000 connections set the `maxclients` attribute to suit your needs.
Be advised that adjusting the `maxclients` attribute means that you will also need
to take into account your systems settings for `fs.file-max` (for example `sysctl -w fs.file-max=20000`)

```ruby
redis['maxclients'] = 20000
```

## Tuning the TCP stack for Redis

The following settings are to enable a more performant Redis server instance. `tcp_timeout` is
a value set in seconds that the Redis server waits before terminating an idle TCP connection.
The `tcp_keepalive` is a tunable setting in seconds to TCP ACKs to clients in absence of
communication.

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## Announce ip from hostname

Currently the only way to enable hostnames in Redis is by setting `redis['announce_ip']`. However,
this would need to be set uniquely per Redis instance. `announce_ip_from_hostname` is a boolean that allows us to turn this on or off.
It fetches the hostname dynamically, inferring the hostname from `hostname -f` command.

```ruby
redis['announce_ip_from_hostname'] = true
```

## Setting the Redis Cache instance as an LRU

Using multiple Redis instances allows you to configure Redis as a
[Least Recently Used cache](https://redis.io/docs/manual/eviction/). Note you should only
do this for the Redis cache and rate-limiting instances; the Redis queues, shared
state instances, and tracechunks instances should never be configured as an LRU,
since they contain data (e.g. Sidekiq jobs) that is expected to be persistent.

To cap memory usage at 32GB, you can use:

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## Using Secure Sockets Layer (SSL)

You can configure Redis to run behind SSL.

### Running Redis server behind SSL

1. To run Redis server behind SSL, you can use the following settings in
   `/etc/gitlab/gitlab.rb`. See the TLS/SSL section of
   [`redis.conf.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/redis/templates/default/redis.conf.erb)
   to learn about the possible values:

   ```ruby
   redis['tls_port']
   redis['tls_cert_file']
   redis['tls_key_file']
   ```

1. After specifying the required values, reconfigure GitLab for the changes to take
   effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
Some `redis-cli` binaries are not built with support for directly connecting to a Redis server over TLS.
If your `redis-cli` doesn't support the `--tls` flag, you will have to use something like
[`stunnel`](https://redis.com/blog/stunnel-secure-redis-ssl/) to connect to the
Redis server using `redis-cli` for any debugging purposes.

### Make GitLab client connect to Redis server over SSL

To activate GitLab client support for SSL:

1. Add the following line to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['redis_ssl'] = true
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SSL certificates

If you're using custom SSL certificates for Redis, be sure to add them
to the [trusted certificates](../settings/ssl.md#install-custom-public-certificates).

## Renamed commands

By default, the `KEYS` command is disabled as a security measure.

If you'd like to obfuscate or disable this command, or other commands, edit the `redis['rename_commands']` setting in `/etc/gitlab/gitlab.rb` to look like:

```ruby
redis['rename_commands'] = {
  'KEYS': '',
  'OTHER_COMMAND': 'VALUE'
}
```

- `OTHER_COMMAND` is the command you want to modify
- `VALUE` should be one of:
  1. A new command name.
  1. `''`, which completely disables the command.

To disable this functionality:

1. Set `redis['rename_commands'] = {}` in your `/etc/gitlab/gitlab.rb` file
1. Run `sudo gitlab-ctl reconfigure`

## Lazy freeing

Redis 4 introduced [lazy freeing](http://antirez.com/news/93). This can improve performance when freeing large values.

This setting defaults to `false`. To enable it, you can use:

```ruby
redis['lazyfree_lazy_eviction'] = true
redis['lazyfree_lazy_expire'] = true
redis['lazyfree_lazy_server_del'] = true
redis['replica_lazy_flush'] = true
```

## Threaded I/O

Redis 6 introduced threaded I/O. This allow writes to scale across multiple cores.

This setting is disabled by default. To enable it, you can use:

```ruby
redis['io_threads'] = 4
redis['io_threads_do_reads'] = true
```

## Troubleshooting

### `x509: certificate signed by unknown authority`

This error message suggests that the SSL certificates have not been
properly added to the list of trusted certificates for the server. To
check whether this is an issue:

1. Check Workhorse logs in `/var/log/gitlab/gitlab-workhorse/current`.

1. If you see messages that look like:

   ```plaintext
   2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
   ```

   The first line should show `rediss` as the scheme with the address
   of the Redis server. The second line indicates the certificate is
   not properly trusted on this server. See the [previous section](#ssl-certificates).

1. Verify that the SSL certificate is working via [these troubleshooting steps](ssl.md#custom-certificates-missing-or-skipped).

### NOAUTH Authentication required

A Redis server may require a password sent via an `AUTH` message before
commands are accepted. A `NOAUTH Authentication required` error message
suggests the client is not sending a password. GitLab logs may help
troubleshoot this error:

1. Check Workhorse logs in `/var/log/gitlab/gitlab-workhorse/current`.

1. If you see messages that look like:

   ```plaintext
   2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
   2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
   ```

1. Check that the Redis client password specified in `/etc/gitlab/gitlab.rb` is correct:

   ```ruby
   gitlab_rails['redis_password'] = 'your-password-here'
   ```

1. If you are using the Omnibus-provided Redis server, check that the server has the same password:

   ```ruby
   redis['password'] = 'your-password-here'
   ```

### Redis connection reset (ECONNRESET)

If you see `Redis::ConnectionError: Connection lost (ECONNRESET)` in the
GitLab Rails logs (`/var/log/gitlab-rails/production.log`), this might
indicate that the server is expecting SSL but the client is not
configured to use it.

1. Check that the server is actually listening to the port via SSL.
   For example:

   ```shell
   /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
   ```

1. Check `/var/opt/gitlab/gitlab-rails/etc/resque.yml`. You
   should see something like:

   ```yaml
   production:
     url: rediss://:mypassword@redis-server:6379/
   ```

1. If `redis://` is present instead of `rediss://`, the `redis_ssl`
   parameter may not have been configured properly, or the reconfigure
   step may not have been run.

### Connecting to Redis via the CLI

When connecting to Redis for troubleshooting you can use:

- Redis via Unix domain sockets:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
  ```

- Redis via TCP:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379
  ```

- Password to authenticate to Redis if required:

  ```shell
  sudo /opt/gitlab/embedded/bin/redis-cli -h 127.0.0.1 -p 6379 -a <password>
  ```
