---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# NGINX settings

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
be added to `gitlab.rb`

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
mattermost_nginx['redirect_http_to_https'] = true
```

NOTE: **Note:** Modifying NGINX configuration should be done with care as incorrect
or incompatible configuration may yield to unavailability of service.

## Enable HTTPS

By default, Omnibus GitLab does not use HTTPS. If you want to enable HTTPS for
`gitlab.example.com`, there are two options:

1. [Free and automated HTTPS with Let's Encrypt](ssl.md#lets-encrypt-integration)
1. [Manually configuring HTTPS with your own certificates](#manually-configuring-https)

### Warning

The NGINX configuration will tell browsers and clients to only communicate with your
GitLab instance over a secure connection for the next 24 months. By enabling
HTTPS you'll need to provide a secure connection to your instance for at least
the next 24 months.

## Manually configuring HTTPS

By default, Omnibus GitLab does not use HTTPS.

To enable HTTPS for the domain `gitlab.example.com`:

1. Edit the `external_url` in `/etc/gitlab/gitlab.rb`:

   ```ruby
   # note the 'https' below
   external_url "https://gitlab.example.com"
   ```

1. Create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
   ```

   Because the hostname in our example is `gitlab.example.com`, Omnibus GitLab
   will look for private key and public certificate files called
   `/etc/gitlab/ssl/gitlab.example.com.key` and `/etc/gitlab/ssl/gitlab.example.com.crt`,
   respectively.

   Make sure you use the full certificate chain in order to prevent SSL errors when
   clients connect. The full certificate chain order should consist of the server certificate first,
   followed by all intermediate certificates, with the root CA last.

   If the `certificate.key` file is password protected, NGINX will not ask for
   the password when you reconfigure GitLab. In that case, Omnibus GitLab will
   fail silently with no error messages. To remove the password from the key, run:

   ```shell
   openssl rsa -in certificate_before.key -out certificate_after.key
   ```

1. Now, reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

When the reconfigure finishes, your GitLab instance should be reachable at `https://gitlab.example.com`.

If you are using a firewall you may have to open port 443 to allow inbound
HTTPS traffic.

```shell
# UFW example (Debian, Ubuntu)
sudo ufw allow https

# lokkit example (RedHat, CentOS 6)
sudo lokkit -s https

# firewall-cmd (RedHat, Centos 7)
sudo firewall-cmd --permanent --add-service=https
sudo systemctl reload firewalld
```

## Redirect `HTTP` requests to `HTTPS`

By default, when you specify an `external_url` starting with 'https', NGINX will
no longer listen for unencrypted HTTP traffic on port 80. If you want to
redirect all HTTP traffic to HTTPS you can use the `redirect_http_to_https`
setting.

NOTE: **Note:** This behavior is enabled by default.

```ruby
external_url "https://gitlab.example.com"
nginx['redirect_http_to_https'] = true
```

## Change the default port and the SSL certificate locations

If you need to use an HTTPS port other than the default (443), just specify it
as part of the `external_url`.

```ruby
external_url "https://gitlab.example.com:2443"
```

To set the location of ssl certificates create `/etc/gitlab/ssl` directory,
place the `.crt` and `.key` files in the directory and specify the following
configuration:

```ruby
# For GitLab
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Update the SSL Certificates

If the content of your SSL certificates has been updated, but no configuration
changes have been made to `gitlab.rb`, then `gitlab-ctl reconfigure` will not
affect NGINX. Instead, run `sudo gitlab-ctl hup nginx` to cause NGINX to
[reload the existing configuration and new certificates](http://nginx.org/en/docs/control.html)
gracefully.

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
as GitLab's trusted proxies, which will keep users from being listed as signed
in from those IPs.

Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
for the changes to take effect.

## Configuring HTTP2 protocol

By default, when you specify that your GitLab instance should be reachable
through HTTPS by specifying `external_url "https://gitlab.example.com"`,
[http2 protocol](https://tools.ietf.org/html/rfc7540) is also enabled.

The Omnibus GitLab package sets required ssl_ciphers that are compatible with
http2 protocol.

If you are specifying custom ssl_ciphers in your configuration and a cipher is
in [http2 cipher blacklist](https://tools.ietf.org/html/rfc7540#appendix-A), once you try to reach your GitLab instance you will
be presented with `INADEQUATE_SECURITY` error in your browser.

Consider removing the offending ciphers from the cipher list. Changing ciphers
is only necessary if you have a very specific custom setup.

For more information on why you would want to have http2 protocol enabled, check out
the [http2 whitepaper](https://assets.wp.nginx.com/wp-content/uploads/2015/09/NGINX_HTTP2_White_Paper_v4.pdf?_ga=1.127086286.212780517.1454411744).

If changing the ciphers is not an option you can disable http2 support by
specifying in `/etc/gitlab/gitlab.rb`:

```ruby
nginx['http2_enabled'] = false
```

Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
for the changes to take effect.

NOTE: **Note:** The `http2` setting only works for the main GitLab application and not for the other services.

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

   *Note: Make sure you have first installed Apache/NGINX so the webserver user is created, otherwise omnibus will fail while reconfiguring.*

   Let's say for example that the webserver user is `www-data`.
   In `/etc/gitlab/gitlab.rb` set:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   *Note: This setting is an array so you can specify more than one user to be added to `gitlab-www` group.*

   Run `sudo gitlab-ctl reconfigure` for the change to take effect.

   *Note: if you are using SELinux and your web server runs under a restricted SELinux profile you may have to [loosen the restrictions on your web server](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache#selinux-modifications).*

   *Note: make sure that the webserver user has the correct permissions on all directories used by external web-server, otherwise you will receive `failed (XX: Permission denied) while reading upstream` errors.

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

   *Note: The values below were added in GitLab 8.2, make sure you have the latest version installed.*

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

## Supporting proxied SSL

By default NGINX will auto-detect whether to use SSL if `external_url`
contains `https://`. If you are running GitLab behind a reverse proxy, you
may wish to terminate SSL at another proxy server or load balancer. To do this,
be sure the `external_url` contains `https://` and apply the following
configuration to `gitlab.rb`:

```ruby
nginx['listen_port'] = 80
nginx['listen_https'] = false
```

Other bundled components (Registry, Pages, etc) use a similar strategy for
proxied SSL. Set the particular component's `*_external_url` with `https://` and
prefix the `nginx[...]` configuration with the component name. For example, for
Registry use the following configuration:

```ruby
registry_external_url 'https://registry.example.com'

registry_nginx['listen_port'] = 80
registry_nginx['listen_https'] = false
```

The same format can be used for Pages (`pages_` prefix) and Mattermost (`mattermost_` prefix).

Note that you may need to configure your reverse proxy or load balancer to
forward certain headers (e.g. `Host`, `X-Forwarded-Ssl`, `X-Forwarded-For`,
`X-Forwarded-Port`) to GitLab (and Mattermost if you use one). You may see improper redirections or errors
(e.g. "422 Unprocessable Entity", "Can't verify CSRF token authenticity") if
you forget this step. For more information, see:

- <https://stackoverflow.com/questions/16042647/whats-the-de-facto-standard-for-a-reverse-proxy-to-tell-the-backend-ssl-is-used>
- <https://websiteforstudents.com/setup-apache2-reverse-proxy-nginx-ubuntu-17-04-17-10/>

## Setting HTTP Strict Transport Security

By default GitLab enables Strict Transport Security which informs browsers that
they should only contact the website using HTTPS. When a browser visits a
GitLab instance even once, it will remember to no longer attempt insecure connections,
even when the user is explicitly entering a `http://` URL. Such a URL will be automatically redirected by the browser to `https://` variant.

```ruby
nginx['hsts_max_age'] = 31536000
nginx['hsts_include_subdomains'] = false
```

By default `max_age` is set for one year, this is how long browser will remember to only connect through HTTPS.
Setting `max_age` to 0 will disable this feature. For more information see:

- <https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/>

NOTE: **Note:** The HSTS settings only work for the main GitLab application and not for the other services.

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

NOTE: **Note:** The `gzip` setting only works for the main GitLab application and not for the other services.

## Using custom SSL ciphers

By default GitLab is using SSL ciphers that are combination of testing on <https://gitlab.com> and various best practices contributed by the GitLab community.

However, you can change the ssl ciphers by adding to `gitlab.rb`:

```ruby
  nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
```

and running reconfigure.

You can also enable `ssl_dhparam` directive.

First, generate `dhparams.pem` with `openssl dhparam -out dhparams.pem 2048`. Then, in `gitlab.rb` add a path to the generated file, for example:

```ruby
  nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
```

After the change run `sudo gitlab-ctl reconfigure`.

## Enable 2-way SSL Client Authentication

To require web clients to authenticate with a trusted certificate, you can enable 2-way SSL by adding to `gitlab.rb`:

```ruby
  nginx['ssl_verify_client'] = "on"
```

and running reconfigure.

These additional options NGINX supports for configuring SSL client authentication can also be configured:

```ruby
  nginx['ssl_client_certificate'] = "/etc/pki/tls/certs/root-certs.pem"
  nginx['ssl_verify_depth'] = "2"
```

After making the changes run `sudo gitlab-ctl reconfigure`.

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

NOTE: **Note:** When disabling NGINX, you won't be able to access
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

**Note:** If you are running a version older than 8.16.0, you will have to
manually remove the Unicorn service file (`/opt/gitlab/service/unicorn`), if
exists, for reconfigure to succeed.

### Vhost (server block)

Then, in your custom Passenger/NGINX installation, create the following site
configuration file:

```plaintext
upstream gitlab-workhorse {
  server unix://var/opt/gitlab/gitlab-workhorse/socket fail_timeout=0;
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

**Note:** If you wind up with a 403 forbidden, it's possible that you haven't enabled passenger in `/etc/nginx/nginx.conf`, to do so simply uncomment:

```plaintext
# include /etc/nginx/passenger.conf;
```

then, `sudo service nginx reload`

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

Other than the Passenger configuration in place of Unicorn and the lack of HTTPS
(although this could be enabled) these files are mostly identical to:

- [Bundled GitLab NGINX configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-http.conf.erb)

Don't forget to restart NGINX to load the new configuration (on Debian-based
systems `sudo service nginx restart`).

## Troubleshooting

### 400 Bad Request: too many Host headers

Make sure you don't have the `proxy_set_header` configuration in
`nginx['custom_gitlab_server_config']` settings and instead use the
['proxy_set_headers'](#supporting-proxied-ssl) configuration in your `gitlab.rb` file.

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
/opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | openssl sha1

/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| openssl sha1
```

Once you verify that they match, you will need to reconfigure and reload NGINX:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl hup nginx
```
