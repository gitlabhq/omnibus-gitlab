---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Logs on Linux package installations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab includes an [advanced log system](https://docs.gitlab.com/administration/logs/) where every service and component within GitLab will output system logs.
Here are the configuration settings and tools for managing these logs on Linux package installations.

## Tail logs in a console on the server

If you want to 'tail', i.e. view live log updates of GitLab logs you can use
`gitlab-ctl tail`.

```shell
# Tail all logs; press Ctrl-C to exit
sudo gitlab-ctl tail

# Drill down to a sub-directory of /var/log/gitlab
sudo gitlab-ctl tail gitlab-rails

# Drill down to an individual file
sudo gitlab-ctl tail nginx/gitlab_error.log
```

### Tail logs in a console and save to a file

Oftentimes, it is useful to both display the logs in the console and save them to a file for later debugging/analysis. You can use the [`tee`](https://en.wikipedia.org/wiki/Tee_(command)) utility to accomplish this.

```shell
# Use 'tee' to tail all the logs to STDOUT and write to a file at the same time
sudo gitlab-ctl tail | tee --append /tmp/gitlab_tail.log
```

## Configure default log directories

In your `/etc/gitlab/gitlab.rb` file, there are many `log_directory` keys for
the various types of logs. Uncomment and update the values for all the logs
you want to place elsewhere:

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
puma['log_directory'] = "/var/log/gitlab/puma"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

Gitaly and Mattermost have different log directory configs:

```ruby
gitaly['configuration'] = {
   logging: {
    dir: "/var/log/gitlab/registry"
   }
}
mattermost['log_file_directory'] = "/var/log/gitlab/registry"
```

Run `sudo gitlab-ctl reconfigure` to configure your instance with these settings.

## runit logs

The [runit-managed](../development/architecture/_index.md#runit) services in Linux package installations generate log data using
`svlogd`.

- Logs are written to a file called `current`.
- Periodically, this log is compressed and renamed using the TAI64N format, for
  example: `@400000005f8eaf6f1a80ef5c.s`.
- The file system datestamp on the compressed logs will be consistent with the time
  GitLab last wrote to that file.
- `zmore` and `zgrep` allow viewing and searching through both compressed or uncompressed logs.

Read the [`svlogd` documentation](https://smarden.org/runit/svlogd.8) for more information
about the files it generates.

You can modify `svlogd` settings in `/etc/gitlab/gitlab.rb` with the following settings:

```ruby
# Below are the default values
logging['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
logging['svlogd_num'] = 30 # keep 30 rotated log files
logging['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
logging['svlogd_filter'] = "gzip" # compress logs with gzip
logging['svlogd_udp'] = nil # transmit log messages via UDP
logging['svlogd_prefix'] = nil # custom prefix for log messages

# Optionally, you can override the prefix for e.g. Nginx
nginx['svlogd_prefix'] = "nginx"
```

## Logrotate

The **logrotate** service built into GitLab manages all logs except those
captured by **runit**. This service will rotate, compress, and eventually delete
the log data such as `gitlab-rails/production.log` and
`nginx/gitlab_access.log`. You can configure common logrotate settings,
configure per-service logrotate settings, and completely disable logrotate
with `/etc/gitlab/gitlab.rb`.

### Configuring common logrotate settings

Settings common to all **logrotate** services can be set in the
`/etc/gitlab/gitlab.rb` file. These settings correspond to configuration options
in the logrotate configuration files for each service. See the logrotate man
page (`man logrotate`) for details.

```ruby
logging['logrotate_frequency'] = "daily" # rotate logs daily
logging['logrotate_maxsize'] = nil # logs will be rotated when they grow bigger than size specified for `maxsize`, even before the specified time interval (daily, weekly, monthly, or yearly)
logging['logrotate_size'] = nil # do not rotate by size by default
logging['logrotate_rotate'] = 30 # keep 30 rotated logs
logging['logrotate_compress'] = "compress" # see 'man logrotate'
logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
logging['logrotate_postrotate'] = nil # no postrotate command by default
logging['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz
```

### Configuring individual service logrotate settings

You can customize logrotate settings for each individual service by using
`/etc/gitlab/gitlab.rb`. For example, to customize logrotate frequency and size
for the `nginx` service, use:

```ruby
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"
```

### Disabling logrotate

You can also disable the built-in logrotate service with the following setting
in `/etc/gitlab/gitlab.rb`:

```ruby
logrotate['enable'] = false
```

### Logrotate `notifempty` setting

The logrotate service runs with a non-configurable default of `notifempty`, resolving
the following issues:

- Empty logs being rotated unnecessarily, and often many empty logs being stored.
- One-off logs that are useful for long term troubleshooting being deleted after 30 days, such as database migration logs.

### Logrotate one-off and empty log handling

Logs are now rotated and recreated by **logrotate** as needed, and one-off logs
are only rotated when they change. With this setting in place, some tidying can be done:

- Empty one-off logs such as `gitlab-rails/gitlab-rails-db-migrate*.log` can be deleted.
- Empty logs which were rotated and compressed by older versions of GitLab. These
  empty logs are usually 20 bytes in size.

### Run logrotate manually

Logrotate is a scheduled job but it can also be triggered on-demand.

To manually trigger GitLab log rotation with `logrotate`, use the following command:

```shell
/opt/gitlab/embedded/sbin/logrotate -fv -s /var/opt/gitlab/logrotate/logrotate.status /var/opt/gitlab/logrotate/logrotate.conf
```

### Increase how often logrotate is triggered

The logrotate script triggers every 50 minutes and waits for 10 minutes before attempting to rotate the logs.

To modify these values:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   logrotate['pre_sleep'] = 600   # sleep 10 minutes before rotating after start-up
   logrotate['post_sleep'] = 3000 # wait 50 minutes after rotating
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## UDP log forwarding

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Linux package installations can utilize the UDP logging feature in svlogd as well as sending non-svlogd logs to a syslog-compatible remote system using UDP.
To configure a Linux package installation to send syslog-protocol messages via UDP, use the following settings:

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
# logging['udp_log_shipping_hostname'] = nil # Optional, defaults the system hostname
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

{{< alert type="note" >}}

Setting `udp_log_shipping_host` will [add a `svlogd_prefix`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/logging.rb)
for the specified hostname and service for each of the [runit-managed](../development/architecture/_index.md#runit) services.

{{< /alert >}}

Example log messages:

```plaintext
Jun 26 06:33:46 ubuntu1204-test production.log: Started GET "/root/my-project/import" for 127.0.0.1 at 2014-06-26 06:33:46 -0700
Jun 26 06:33:46 ubuntu1204-test production.log: Processing by ProjectsController#import as HTML
Jun 26 06:33:46 ubuntu1204-test production.log: Parameters: {"id"=>"root/my-project"}
Jun 26 06:33:46 ubuntu1204-test production.log: Completed 200 OK in 122ms (Views: 71.9ms | ActiveRecord: 12.2ms)
Jun 26 06:33:46 ubuntu1204-test gitlab_access.log: 172.16.228.1 - - [26/Jun/2014:06:33:46 -0700] "GET /root/my-project/import HTTP/1.1" 200 5775 "https://172.16.228.169/root/my-project/import" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
2014-06-26_13:33:46.49866 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7nbj0 Sidekiq::Extensions::DelayedMailer JID-bbfb118dd1db20f6c39f5b50 INFO: start
2014-06-26_13:33:46.52608 ubuntu1204-test sidekiq: 2014-06-26T13:33:46Z 18107 TID-7muoc RepositoryImportWorker JID-57ee926c3655fcfa062338ae INFO: start
```

## Using a custom NGINX log format

By default the NGINX access logs will use a version of the 'combined' NGINX
format, designed to hide potentially sensitive information embedded in query strings.
If you want to use a custom log format string you can specify it
in `/etc/gitlab/gitlab.rb` - see
[the NGINX documentation](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format)
for format details.

```ruby
nginx['log_format'] = 'my format string $foo $bar'
mattermost_nginx['log_format'] = 'my format string $foo $bar'
```

## JSON logging

Structured logs can be exported via JSON to be parsed by Elasticsearch,
Splunk, or another log management system.
The JSON format is enabled by default for all services that support it.

{{< alert type="note" >}}

PostgreSQL does not support JSON logging without an
external plugin. However, it does support logging in CSV format:

{{< /alert >}}

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

A restart of the database is required for this to take effect. For more
details, see the
[PostgreSQL documentation](https://www.postgresql.org/docs/12/runtime-config-logging.html).

## Text logging

Customers with established log ingestion systems may not wish to use the JSON
log format. Text formatting can be configured by setting the following
in `/etc/gitlab/gitlab.rb` and then running `gitlab-ctl reconfigure` afterward:

```ruby
gitaly['configuration'] = {
   logging: {
    format: ""
   }
}
gitlab_shell['log_format'] = 'text'
gitlab_workhorse['log_format'] = 'text'
registry['log_formatter'] = 'text'
sidekiq['log_format'] = 'text'
gitlab_pages['log_format'] = 'text'
```

{{< alert type="note" >}}

There are a few variations in attribute names for the log format depending on the service involved (for example, Container Registry uses `log_formatter`, Gitaly and Praefect both use `logging_format`). See [Issue #4280](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4280) for more details.

{{< /alert >}}

## rbtrace

GitLab ships with [`rbtrace`](https://github.com/tmm1/rbtrace), which
allows you to trace Ruby code, view all running threads, take memory dumps,
and more. However, this is not enabled by default. To enable it, define the
`ENABLE_RBTRACE` variable to the environment:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

Then reconfigure the system and restart Puma and Sidekiq. To run this
in a Linux package installation, run as root:

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## Configuring log level/verbosity

You can configure the minimum log levels (verbosity) for GitLab Rails,
Container Registry, GitLab Shell and Gitaly:

1. Edit `/etc/gitlab/gitlab.rb` and set the log levels:

   ```ruby
   gitlab_rails['env'] = {
     "GITLAB_LOG_LEVEL" => "WARN",
   }
   registry['log_level'] = 'info'
   gitlab_shell['log_level'] = 'INFO'
   gitaly['configuration'] = {
     logging: {
       level: "warn"
     }
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

You [cannot edit](https://gitlab.com/groups/gitlab-org/-/epics/6034)
the `log_level` for certain GitLab logs, for example
`production_json.log`, `graphql_json.log`, and so on.
See also [Override default log level](https://docs.gitlab.com/administration/logs/#override-default-log-level).

{{< /alert >}}

## Setting a custom log group

GitLab supports assigning a custom group to the configured [log directories](#configure-default-log-directories)

A global `logging['log_group']` setting in your `/etc/gitlab/gitlab.rb` file can
be configured as well as per-service `log_group` settings such as `gitaly['log_group']`.
You will need to run `sudo gitlab-ctl reconfigure` to configure your instance
when adding `log_group` settings.

Setting a global or per-service `log_group` will:

- Change the permissions on the per-service log directories (or all log directories
if using the global setting) to `0750` to allow the configured group members to
read the contents of the log directory.

- Configure [runit](#runit-logs) to write and rotate logs using the specified
`log_group` : either per-service or for all runit-managed services.

### Custom log group limitations

Logs for services not managed by runit (e.g. the `gitlab-rails` logs in
`/var/log/gitlab/gitlab-rails`) will not inherit the configured `log_group` setting.

The group must already exist on the host. Linux package installations don't create the group
when running `sudo gitlab-ctl reconfigure`.
