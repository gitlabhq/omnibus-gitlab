# Omnibus GitLab Logs

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

## Configure default log directories

In your `/etc/gitlab/gitlab.rb` file, there are many `log_directory` keys for
the various types of logs. Uncomment and update the values for all the logs
you want to place elsewhere:

```ruby
# For example:
gitlab_rails['log_directory'] = "/var/log/gitlab/gitlab-rails"
unicorn['log_directory'] = "/var/log/gitlab/unicorn"
registry['log_directory'] = "/var/log/gitlab/registry"
...
```

Run `sudo gitlab-ctl reconfigure` to configure your instance with these settings.

## runit logs

The [runit-managed](../architecture/README.md#runit) services in Omnibus GitLab generate log data using
svlogd. See the [svlogd documentation](http://smarden.org/runit/svlogd.8.html) for more information
about the files it generates.

You can modify svlogd settings via `/etc/gitlab/gitlab.rb` with the following settings:

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

Starting with Omnibus GitLab 7.4 there is a built-in logrotate service in
Omnibus GitLab. This service will rotate, compress and eventually delete the
log data that is not captured by runit, such as `gitlab-rails/production.log`
and `nginx/gitlab_access.log`. You can configure logrotate via
`/etc/gitlab/gitlab.rb`.

```
# Below are some of the default settings
logging['logrotate_frequency'] = "daily" # rotate logs daily
logging['logrotate_maxsize'] = nil # logs will be rotated when they grow bigger than size specified for `maxsize`, even before the specified time interval (daily, weekly, monthly, or yearly)
logging['logrotate_size'] = nil # do not rotate by size by default
logging['logrotate_rotate'] = 30 # keep 30 rotated logs
logging['logrotate_compress'] = "compress" # see 'man logrotate'
logging['logrotate_method'] = "copytruncate" # see 'man logrotate'
logging['logrotate_postrotate'] = nil # no postrotate command by default
logging['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz


# You can add overrides per service
nginx['logrotate_frequency'] = nil
nginx['logrotate_size'] = "200M"

# You can also disable the built-in logrotate service if you want
logrotate['enable'] = false
```

### Run logrotate manually

Logrotate is a scheduled job but it can also be triggered on-demand.

To manually trigger GitLab log rotation with `logrotate`, use the following command:

```bash
/opt/gitlab/embedded/sbin/logrotate -fv /var/opt/gitlab/logrotate/logrotate.d -s /var/opt/gitlab/logrotate/logrotate.conf
```

## UDP log forwarding

In case you have a central server where all your infra logs are gathered,
you can configure Omnibus GitLab to send syslog-ish log messages via UDP:

```ruby
logging['udp_log_shipping_host'] = '1.2.3.4' # Your syslog server
logging['udp_log_shipping_port'] = 1514 # Optional, defaults to 514 (syslog)
```

Example log messages:

```
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
[the NGINX documentation](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format)
for format details.

```
nginx['log_format'] = 'my format string $foo $bar'
mattermost_nginx['log_format'] = 'my format string $foo $bar'
```

## JSON logging

Structured logs can be exported via JSON to be parsed by Elasticsearch,
Splunk, or another log management system. Some components already write JSON logs
by default (e.g. see [GitLab CE logging
documentation](https://docs.gitlab.com/ee/administration/logs.html)),
but until GitLab 12.0 other GitLab components may be using an
unstructured format. To enable JSON logging for all GitLab components in
versions prior to GitLab 12.0 add these lines to `/etc/gitlab/gitlab.rb` and
run `gitlab-ctl reconfigure`:

```ruby
gitaly['logging_format'] = 'json'
gitlab_shell['log_format'] = 'json'
gitlab_workhorse['log_format'] = 'json'
registry['log_formatter'] = 'json'
sidekiq['log_format'] = 'json'
gitlab_pages['log_format'] = 'json'
```

NOTE: **Note** PostgreSQL does not support JSON logging without an
external plugin. However, it does support logging in CSV format:

```ruby
postgresql['log_destination'] = 'csvlog'
postgresql['logging_collector'] = 'on'
```

A restart of the database is required for this to take effect. For more
details, see the [PostgreSQL
documentation](https://www.postgresql.org/docs/current/runtime-config-logging.html).

## Text logging

Customers with established log ingestion systems may not wish to use JSON
logs after they become default in GitLab version 12.0. The old behavior may
be retained by setting the following in `/etc/gitlab/gitlab.rb` and then
running `gitlab-ctl reconfigure` afterward:

```ruby
gitaly['logging_format'] = 'default'
gitlab_shell['log_format'] = nil
gitlab_workhorse['log_format'] = nil
registry['log_formatter'] = 'text'
sidekiq['log_format'] = 'default'
gitlab_pages['log_format'] = 'text'
```

[ee]: https://about.gitlab.com/gitlab-ee/
