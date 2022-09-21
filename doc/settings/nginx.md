---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# NGINX settings **(FREE SELF)**

## Service-specific NGINX settings

Users can configure NGINX settings differently for different services via
`gitlab.rb`. Settings for the GitLab Rails application can be configured using the
`nginx['<some setting>']` keys. There are similar keys for other services like
`pages_nginx`, `mattermost_nginx` and `registry_nginx`. All the configurations
available for `nginx` are also available for these `<service_nginx>` settings and
share the same default values as GitLab NGINX.

If modifying via `gitlab.rb`, users have to configure NGINX setting for each
service separately. Settings given via `nginx['foo']` WILL NOT be replicated to
service specific NGINX configuration (as `registry_nginx['foo']` or
`mattermost_nginx['foo']`, etc.). For example, to configure HTTP to HTTPS
redirection for GitLab, Mattermost and Registry, the following settings should
be added to `gitlab.rb`:

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
mattermost_nginx['redirect_http_to_https'] = true
```

NOTE:
Modifying NGINX configuration should be done with care as incorrect
or incompatible configuration may yield to unavailability of service.

## Enable HTTPS

By default, Omnibus GitLab does not use HTTPS. If you want to enable HTTPS for
`gitlab.example.com`, you can:

- [Use Let's Encrypt for free, automated HTTPS](ssl.md#enable-the-lets-encrypt-integration).
- [Manually configure HTTPS with your own certificates](ssl.md#configure-https-manually).

NOTE:
If you use a proxy, load balancer or some other external device to terminate SSL for the GitLab host name,
see [External, proxy, and load balancer SSL termination](ssl.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination).

## Change the default proxy headers

By default, when you specify `external_url` Omnibus GitLab will set a few
NGINX proxy headers that are assumed to be sane in most environments.

For example, Omnibus GitLab will set:

```plaintext
  "X-Forwarded-Proto" => "https",
  "X-Forwarded-Ssl" => "on"
```

if you have specified `https` schema in the `external_url`.

However, if you have a situation where your GitLab is in a more complex setup
like behind a reverse proxy, you will need to tweak the proxy headers in order
to avoid errors like `The change you wanted was rejected` or
`Can't verify CSRF token authenticity Completed 422 Unprocessable`.

This can be achieved by overriding the default headers, eg. specify
in `/etc/gitlab/gitlab.rb`:

```ruby
 nginx['proxy_set_headers'] = {
  "X-Forwarded-Proto" => "http",
  "CUSTOM_HEADER" => "VALUE"
 }
```

Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
for the changes to take effect.

This way you can specify any header supported by NGINX you require.

## Configuring GitLab `trusted_proxies` and the NGINX `real_ip` module

By default, NGINX and GitLab will log the IP address of the connected client.

If your GitLab is behind a reverse proxy, you may not want the IP address of
the proxy to show up as the client address.

You can have NGINX look for a different address to use by adding your reverse
proxy to the `real_ip_trusted_addresses` list:

```ruby
# Each address is added to the the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

Description of the options:

- <http://nginx.org/en/docs/http/ngx_http_realip_module.html>

By default, Omnibus GitLab will use the IP addresses in `real_ip_trusted_addresses`
as GitLab trusted proxies, which will keep users from being listed as signed
in from those IPs.

Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
for the changes to take effect.

## Configuring the PROXY protocol

If you want to use a proxy like HAProxy in front of GitLab using the [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt),
you need to enable this setting. Do not forget to set the `real_ip_trusted_addresses` also as needed:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. Save the file and
   [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
   for the changes to take effect.

Once enabled, NGINX only accepts PROXY protocol traffic on these listeners.
Ensure to also adjust any other environments you might have, like monitoring checks.

## Using a non-bundled web-server

By default, Omnibus GitLab installs GitLab with bundled NGINX.
Omnibus GitLab allows webserver access through the `gitlab-www` user, which resides
in the group with the same name. To allow an external webserver access to
GitLab, the external webserver user needs to be added to the `gitlab-www` group.

To use another web server like Apache or an existing NGINX installation you
will have to perform the following steps:

1. **Disable bundled NGINX**

   In `/etc/gitlab/gitlab.rb` set:

   ```ruby
   nginx['enable'] = false
   ```

1. **Set the username of the non-bundled web-server user**

   By default, Omnibus GitLab has no default setting for the external webserver
   user, you have to specify it in the configuration. For Debian/Ubuntu the
   default user is `www-data` for both Apache/NGINX whereas for RHEL/CentOS
   the NGINX user is `nginx`.

   Make sure you have first installed Apache/NGINX so the webserver user is created, otherwise omnibus will fail while reconfiguring.

   Let's say for example that the webserver user is `www-data`.
   In `/etc/gitlab/gitlab.rb` set:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   This setting is an array so you can specify more than one user to be added to `gitlab-www` group.

   Run `sudo gitlab-ctl reconfigure` for the change to take effect.

   If you are using SELinux and your web server runs under a restricted SELinux profile you may have to [loosen the restrictions on your web server](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache#selinux-modifications).

   Make sure that the webserver user has the correct permissions on all directories used by external web-server, otherwise you will receive `failed (XX: Permission denied) while reading upstream` errors.

1. **Add the non-bundled web-server to the list of trusted proxies**

   Normally, Omnibus GitLab defaults the list of trusted proxies to what was
   configured in the `real_ip` module for the bundled NGINX.

   For non-bundled web-servers the list needs to be configured directly, and should
   include the IP address of your web-server if it is not on the same machine as GitLab.
   Otherwise, users will be shown as being signed in from your web-server's IP address.

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. **(Optional) Set the right GitLab Workhorse settings if using Apache**

   Apache cannot connect to a UNIX socket but instead needs to connect to a
   TCP Port. To allow GitLab Workhorse to listen on TCP (by default port 8181)
   edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   Run `sudo gitlab-ctl reconfigure` for the change to take effect.

1. **Download the right web server configs**

   Go to [GitLab recipes repository](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server) and look for the omnibus
   configs in the webserver directory of your choice. Make sure you pick the
   right configuration file depending whether you choose to serve GitLab with
   SSL or not. The only thing you need to change is `YOUR_SERVER_FQDN` with
   your own FQDN and if you use SSL, the location where your SSL keys currently
   reside. You also might need to change the location of your log files.

## Setting the NGINX listen address or addresses

By default NGINX will accept incoming connections on all local IPv4 addresses.
You can change the list of addresses in `/etc/gitlab/gitlab.rb`.

```ruby
 # Listen on all IPv4 and IPv6 addresses
nginx['listen_addresses'] = ["0.0.0.0", "[::]"]
registry_nginx['listen_addresses'] = ['*', '[::]']
mattermost_nginx['listen_addresses'] = ['*', '[::]']
pages_nginx['listen_addresses'] = ['*', '[::]']
```

## Setting the NGINX listen port

By default NGINX will listen on the port specified in `external_url` or
implicitly use the right port (80 for HTTP, 443 for HTTPS). If you are running
GitLab behind a reverse proxy, you may want to override the listen port to
something else. For example, to use port 8081:

```ruby
nginx['listen_port'] = 8081
```

## Verbosity level of NGINX logs

By default NGINX will log at the `error` verbosity level. You may log at a different level
by changing the log level. For example, to enable `debug` logging:

```ruby
nginx['error_log_level'] = "debug"
```

Valid values can be found from the [NGINX documentation](https://nginx.org/en/docs/ngx_core_module.html#error_log).

## Setting the Referrer-Policy header

By default, GitLab sets the `Referrer-Policy` header to `strict-origin-when-cross-origin` on all responses.

This makes the client send the full URL as referrer when making a same-origin request but only send the
origin when making cross-origin requests.

To set this header to a different value:

```ruby
nginx['referrer_policy'] = 'same-origin'
```

You can also disable this header to make the client use its default setting:

```ruby
nginx['referrer_policy'] = false
```

Note that setting this to `origin` or `no-referrer` would break some features in GitLab that require the full referrer URL.

- <https://www.w3.org/TR/referrer-policy/>

## Disabling Gzip compression

By default, GitLab enables Gzip compression for text data over 10240 bytes. To
disable this behavior:

```ruby
nginx['gzip_enabled'] = false
```

NOTE:
The `gzip` setting only works for the main GitLab application and not for the other services.

## Disabling proxy request buffering

Request buffering can be disabled selectively on specific locations by changing `request_buffering_off_path_regex`.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. Reconfigure GitLab, and [HUP](https://nginx.org/en/docs/control.html)
   NGINX to cause it to reload with the updated configuration gracefully:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## Configure `robots.txt`

To configure [`robots.txt`](https://www.robotstxt.org/robotstxt.html) for your instance, specify a custom `robots.txt` file by adding a [custom NGINX configuration](#inserting-custom-nginx-settings-into-the-gitlab-server-block):

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Inserting custom NGINX settings into the GitLab server block

Please keep in mind that these custom settings may create conflicts if the
same settings are defined in your `gitlab.rb` file.

If you need to add custom settings into the NGINX `server` block for GitLab for
some reason you can use the following setting.

```ruby
# Example: block raw file downloads from a specific repository
nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
```

Run `gitlab-ctl reconfigure` to rewrite the NGINX configuration and restart
NGINX.

This inserts the defined string into the end of the `server` block of
`/var/opt/gitlab/nginx/conf/gitlab-http.conf`.

### Notes

- If you're adding a new location, you might need to include

  ```conf
  proxy_cache off;
  proxy_pass http://gitlab-workhorse;
  ```

  in the string or in the included NGINX configuration. Without these, any sub-location
  will return a 404. See
  [GitLab CE Issue #30619](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30619).
- You cannot add the root `/` location or the `/assets` location as those already
  exist in `gitlab-http.conf`.

## Inserting custom settings into the NGINX configuration

If you need to add custom settings into the NGINX configuration, for example to include
existing server blocks, you can use the following setting.

```ruby
# Example: include a directory to scan for additional config files
nginx['custom_nginx_config'] = "include /etc/nginx/conf.d/*.conf;"
```

Run `gitlab-ctl reconfigure` to rewrite the NGINX configuration and restart
NGINX.

This inserts the defined string into the end of the `http` block of
`/var/opt/gitlab/nginx/conf/nginx.conf`.

## Custom error pages

You can use `custom_error_pages` to modify text on the default GitLab error page.
This can be used for any valid HTTP error code; e.g 404, 502.

As an example the following would modify the default 404 error page.

```ruby
nginx['custom_error_pages'] = {
  '404' => {
    'title' => 'Example title',
    'header' => 'Example header',
    'message' => 'Example message'
  }
}
```

This would result in the 404 error page below.

![custom 404 error page](img/error_page_example.png)

Run `gitlab-ctl reconfigure` to rewrite the NGINX configuration and restart
NGINX.

## Using an existing Passenger/NGINX installation

In some cases you may want to host GitLab using an existing Passenger/NGINX
installation but still have the convenience of updating and installing using
the omnibus packages.

NOTE:
When disabling NGINX, you won't be able to access
other services included by Omnibus, like Grafana, Mattermost, etc. unless
you manually add them in `nginx.conf`.

### Configuration

First, you'll need to setup your `/etc/gitlab/gitlab.rb` to disable the built-in
NGINX and Puma:

```ruby
# Define the external url
external_url 'http://git.example.com'

# Disable the built-in nginx
nginx['enable'] = false

# Disable the built-in puma
puma['enable'] = false

# Set the internal API URL
gitlab_rails['internal_api_url'] = 'http://git.example.com'

# Define the web server process user (ubuntu/nginx)
web_server['external_users'] = ['www-data']
```

Make sure you run `sudo gitlab-ctl reconfigure` for the changes to take effect.

NOTE:
If you are running a version older than 8.16.0, you will have to
manually remove the Unicorn service file (`/opt/gitlab/service/unicorn`), if
exists, for reconfigure to succeed.

### Vhost (server block)

NOTE:
GitLab 13.5 changed the default workhorse socket location from `/var/opt/gitlab/gitlab-workhorse/socket` to `/var/opt/gitlab/gitlab-workhorse/sockets/socket`. Please update the following configuration accordingly if upgrading from versions older than 13.5.

Then, in your custom Passenger/NGINX installation, create the following site
configuration file:

```plaintext
upstream gitlab-workhorse {
  server unix://var/opt/gitlab/gitlab-workhorse/sockets/socket fail_timeout=0;
}

server {
  listen *:80;
  server_name git.example.com;
  server_tokens off;
  root /opt/gitlab/embedded/service/gitlab-rails/public;

  client_max_body_size 250m;

  access_log  /var/log/gitlab/nginx/gitlab_access.log;
  error_log   /var/log/gitlab/nginx/gitlab_error.log;

  # Ensure Passenger uses the bundled Ruby version
  passenger_ruby /opt/gitlab/embedded/bin/ruby;

  # Correct the $PATH variable to included packaged executables
  passenger_env_var PATH "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/usr/local/bin:/usr/bin:/bin";

  # Make sure Passenger runs as the correct user and group to
  # prevent permission issues
  passenger_user git;
  passenger_group git;

  # Enable Passenger & keep at least one instance running at all times
  passenger_enabled on;
  passenger_min_instances 1;

  location ~ ^/[\w\.-]+/[\w\.-]+/(info/refs|git-upload-pack|git-receive-pack)$ {
    # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
    error_page 418 = @gitlab-workhorse;
    return 418;
  }

  location ~ ^/[\w\.-]+/[\w\.-]+/repository/archive {
    # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
    error_page 418 = @gitlab-workhorse;
    return 418;
  }

  location ~ ^/api/v3/projects/.*/repository/archive {
    # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
    error_page 418 = @gitlab-workhorse;
    return 418;
  }

  # Build artifacts should be submitted to this location
  location ~ ^/[\w\.-]+/[\w\.-]+/builds/download {
      client_max_body_size 0;
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
  }

  # Build artifacts should be submitted to this location
  location ~ /ci/api/v1/builds/[0-9]+/artifacts {
      client_max_body_size 0;
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
  }

  # Build artifacts should be submitted to this location
  location ~ /api/v4/jobs/[0-9]+/artifacts {
      client_max_body_size 0;
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
  }


  # For protocol upgrades from HTTP/1.0 to HTTP/1.1 we need to provide Host header if its missing
  if ($http_host = "") {
  # use one of values defined in server_name
    set $http_host_with_default "git.example.com";
  }

  if ($http_host != "") {
    set $http_host_with_default $http_host;
  }

  location @gitlab-workhorse {

    ## https://github.com/gitlabhq/gitlabhq/issues/694
    ## Some requests take more than 30 seconds.
    proxy_read_timeout      3600;
    proxy_connect_timeout   300;
    proxy_redirect          off;

    # Do not buffer Git HTTP responses
    proxy_buffering off;

    proxy_set_header    Host                $http_host_with_default;
    proxy_set_header    X-Real-IP           $remote_addr;
    proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto   $scheme;

    proxy_pass http://gitlab-workhorse;

    ## The following settings only work with NGINX 1.7.11 or newer
    #
    ## Pass chunked request bodies to gitlab-workhorse as-is
    # proxy_request_buffering off;
    # proxy_http_version 1.1;
  }

  ## Enable gzip compression as per rails guide:
  ## http://guides.rubyonrails.org/asset_pipeline.html#gzip-compression
  ## WARNING: If you are using relative urls remove the block below
  ## See config/application.rb under "Relative url support" for the list of
  ## other files that need to be changed for relative url support
  location ~ ^/(assets)/ {
    root /opt/gitlab/embedded/service/gitlab-rails/public;
    gzip_static on; # to serve pre-gzipped version
    expires max;
    add_header Cache-Control public;
  }

  ## To access Grafana
  location /-/grafana/ {
    proxy_pass http://localhost:3000/;
  }

  error_page 502 /502.html;
}
```

Don't forget to update `git.example.com` in the above example to be your server URL.

If you wind up with a 403 forbidden, it's possible that you haven't enabled passenger in `/etc/nginx/nginx.conf`,
to do so simply uncomment:

```plaintext
# include /etc/nginx/passenger.conf;
```

Then run `sudo service nginx reload`.

## Enabling/Disabling nginx_status

By default you will have an NGINX health-check endpoint configured at `127.0.0.1:8060/nginx_status` to monitor your NGINX server status.

### The following information will be displayed

```plaintext
Active connections: 1
server accepts handled requests
 18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- Active connections – Open connections in total.
- 3 figures are shown.
  - All accepted connections.
  - All handled connections.
  - Total number of handled requests.
- Reading: NGINX reads request headers
- Writing: NGINX reads request bodies, processes requests, or writes responses to a client
- Waiting: Keep-alive connections. This number depends on the keepalive-timeout.

### Configuration options

Edit `/etc/gitlab/gitlab.rb`:

```ruby
nginx['status'] = {
  "listen_addresses" => ["127.0.0.1"],
  "fqdn" => "dev.example.com",
  "port" => 9999,
  "options" => {
    "access_log" => "on", # Disable logs for stats
    "allow" => "127.0.0.1", # Only allow access from localhost
    "deny" => "all" # Deny access to anyone else
  }
}
```

If you don't find this service useful for your current infrastructure you can disable it with:

```ruby
nginx['status'] = {
  'enable' => false
}
```

Make sure you run `sudo gitlab-ctl reconfigure` for the changes to take effect.

#### Warning

To ensure that user uploads are accessible your NGINX user (usually `www-data`)
should be added to the `gitlab-www` group. This can be done using the following command:

```shell
sudo usermod -aG gitlab-www www-data
```

## Templates

Other than the Passenger configuration in place of Puma and the lack of HTTPS
(although this could be enabled) these files are mostly identical to:

- [Bundled GitLab NGINX configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-http.conf.erb)

Don't forget to restart NGINX to load the new configuration (on Debian-based
systems `sudo service nginx restart`).

## Troubleshooting

### 400 Bad Request: too many Host headers

Make sure you don't have the `proxy_set_header` configuration in
`nginx['custom_gitlab_server_config']` settings and instead use the
['proxy_set_headers'](ssl.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination) configuration in your `gitlab.rb` file.

### `javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure`

Starting with GitLab 10, the Omnibus GitLab package no longer supports TLSv1 protocol by default.
This can cause connection issues with some older Java based IDE clients when interacting with
your GitLab instance.
We strongly urge you to upgrade ciphers on your server, similar to what was mentioned
in [this user comment](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/624#note_299061).

If it is not possible to make this server change, you can default back to the old
behavior by changing the values in your `/etc/gitlab/gitlab.rb`:

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

### Mismatch between private key and certificate

If you see `x509 certificate routines:X509_check_private_key:key values mismatch)` in the NGINX logs (`/var/log/gitlab/nginx/current` by default for Omnibus), there is a mismatch between your private key and certificate.

To fix this, you will need to match the correct private key with your certificate.

To ensure you have the correct key and certificate, you can ensure that the modulus of the private key and certificate match:

```shell
/opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
```

Once you verify that they match, you will need to reconfigure and reload NGINX:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl hup nginx
```

### Request Entity Too Large

If you see `Request Entity Too Large` in the [NGINX logs](https://docs.gitlab.com/ee/administration/logs.html#nginx-logs),
you will need to increase the [Client Max Body Size](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size).
You may encounter this error if you have increased the [Max import size](https://docs.gitlab.com/ee/user/admin_area/settings/account_and_limit_settings.html#max-import-size).
In a Kubernetes-based GitLab installation, this setting is
[named differently](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize).

To increase the `client_max_body_size`, you will need to set the value in your `/etc/gitlab/gitlab.rb`:

```ruby
nginx['client_max_body_size'] = '250m'
```

Make sure you run `sudo gitlab-ctl reconfigure` and run `sudo gitlab-ctl hup nginx` to cause NGINX to
[reload the with the updated configuration](http://nginx.org/en/docs/control.html)
To increase the `client_max_body_size`:

1. Edit `/etc/gitlab/gitlab.rb` and set the preferred value:

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. Reconfigure GitLab, and [HUP](https://nginx.org/en/docs/control.html)
   NGINX to cause it to reload with the updated configuration gracefully:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

### Security scan is showing a "NGINX HTTP Server Detection" warning

Some security scanners detect issues when they see the `Server: nginx` http header. Most scanners with this alert will
notify as `Low` or `Info` severity. [See Nessus as an example](https://www.tenable.com/plugins/nessus/106375).

We recommend ignoring this warning, as the benefit of removing the header is low, and its presence
[helps support the NGINX project in usage statistics](https://trac.nginx.org/nginx/ticket/1644). We do provide a way to turn off the
header with `hide_server_tokens`:

1. Edit `/etc/gitlab/gitlab.rb` and set the value:

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. Reconfigure GitLab, and [hup](https://nginx.org/en/docs/control.html)
   NGINX to cause it to reload the with the updated configuration gracefully:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

### `502: Bad Gateway` when SELinux and external NGINX are used

On Linux servers with SELinux enabled, after setting up an external NGINX, the error `502: Bad Gateway` may be observed when accessing the GitLab UI. You can also see the error in NGINX's logs:

```plaintext
connect() to unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket failed (13:Permission denied) while connecting to upstream
```

Select one of the following options to fix:

- Update to GitLab 14.3 or later which contains an [updated SELinux policy](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5569).
- Fetch and update the policy manually:

  ```shell
  wget https://gitlab.com/gitlab-org/omnibus-gitlab/-/raw/a9d6b020f81d18d778fb502c21b2c8f2265cabb4/files/gitlab-selinux/rhel/7/gitlab-13.5.0-gitlab-shell.pp
  semodule -i gitlab-13.5.0-gitlab-shell.pp
  ```
