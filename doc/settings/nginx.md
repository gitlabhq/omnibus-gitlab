---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# NGINX settings

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page provides configuration information for administrators and DevOps engineers configuring NGINX for GitLab installations.
It includes essential instructions for optimizing performance and security specific to bundled NGINX (Linux package), Helm charts, or custom setups.

## Service-specific NGINX settings

To configure NGINX settings for different services, edit the `gitlab.rb` file.

WARNING:
Incorrect or incompatible configuration
might cause the service to become unavailable.

Use `nginx['<setting>']` keys to configure settings for the GitLab Rails application.
GitLab provides similar keys for other services like
`pages_nginx`, `mattermost_nginx`, and `registry_nginx`.
Configurations for `nginx` are also available for these `<service_nginx>` settings, and
share the same default values as GitLab NGINX.

To operate NGINX for isolated services like Mattermost, use `gitlab_rails['enable'] = false` instead of `nginx['enable'] = false`.
For more information, see [Running GitLab Mattermost on its own server](https://docs.gitlab.com/ee/integration/mattermost/#running-gitlab-mattermost-on-its-own-server).

When you modify the `gitlab.rb` file, configure NGINX settings for each
service separately.
Settings specified using `nginx['foo']` are not replicated to
service-specific NGINX configurations (such as `registry_nginx['foo']` or
`mattermost_nginx['foo']`).
For example, to configure HTTP to HTTPS
redirection for GitLab, Mattermost and Registry, add the following settings
to `gitlab.rb`:

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
mattermost_nginx['redirect_http_to_https'] = true
```

## Enable HTTPS

By default, Linux package installations do not use HTTPS. To enable HTTPS for
`gitlab.example.com`:

- [Use Let's Encrypt for free, automated HTTPS](ssl/index.md#enable-the-lets-encrypt-integration).
- [Manually configure HTTPS with your own certificates](ssl/index.md#configure-https-manually).

If you use a proxy, load balancer, or other external device to terminate SSL for the GitLab host name,
see [External, proxy, and load balancer SSL termination](ssl/index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination).

## Change the default proxy headers

By default, when you specify `external_url`, a Linux package installation sets NGINX proxy headers
that are suitable for most environments.

For example, if you specify the `https` schema in the `external_url`, a Linux package installation sets:

```plaintext
"X-Forwarded-Proto" => "https",
"X-Forwarded-Ssl" => "on"
```

If your GitLab instance is in a more complex setup, such as behind a reverse proxy, you might need
to adjust the proxy headers to avoid errors like:

- `The change you wanted was rejected`
- `Can't verify CSRF token authenticity Completed 422 Unprocessable`

To override the default headers:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['proxy_set_headers'] = {
     "X-Forwarded-Proto" => "http",
     "CUSTOM_HEADER" => "VALUE"
   }
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

You can specify any header supported by NGINX.

## Configure GitLab trusted proxies and NGINX `real_ip` module

By default, NGINX and GitLab log the IP address of the connected client.

If GitLab is behind a reverse proxy, you might not want the IP address of
the proxy to show as the client address.

To configure NGINX to use a different address, add your reverse
proxy to the `real_ip_trusted_addresses` list:

```ruby
# Each address is added to the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# Other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

For a description of these options, see the
[NGINX `realip` module documentation](http://nginx.org/en/docs/http/ngx_http_realip_module.html).

By default, Linux package installations use the IP addresses in `real_ip_trusted_addresses`
as GitLab trusted proxies.
The trusted proxy configuration prevents users from being listed as signed in from those IP addresses.

Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
for the changes to take effect.

## Configure the PROXY protocol

To use a proxy like HAProxy in front of GitLab with the
[PROXY protocol](https://www.haproxy.org/download/3.1/doc/proxy-protocol.txt):

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

After you enable this setting, NGINX only accepts PROXY protocol traffic on these listeners.
Adjust any other environments you might have, such as monitoring checks.

## Use a non-bundled web server

By default, the Linux package installs GitLab with bundled NGINX.
Linux package installations allow web server access through the `gitlab-www` user, which resides
in the group with the same name. To allow an external web server access to
GitLab, add the external web server user to the `gitlab-www` group.

To use another web server like Apache or an existing NGINX installation:

1. Disable bundled NGINX:

   In `/etc/gitlab/gitlab.rb` set:

   ```ruby
   nginx['enable'] = false
   ```

1. Set the username of the non-bundled web server user:

   Linux package installations have no default setting for the external web server
   user. You must specify it in the configuration. For example:

   - Debian/Ubuntu: The default user is `www-data` for both Apache and NGINX.
   - RHEL/CentOS: The NGINX user is `nginx`.

   Install Apache or NGINX before continuing, so the web server user is created.
   Otherwise, the Linux package installation fails during reconfiguration.

   If the web server user is `www-data`, in `/etc/gitlab/gitlab.rb` set:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   This setting is an array, so you can specify multiple users to add to the `gitlab-www` group.

   Run `sudo gitlab-ctl reconfigure` for the change to take effect.

   If you use SELinux and your web server runs under a restricted SELinux profile, you might need to
   [loosen the restrictions on your web server](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache#selinux-modifications).

   Ensure the web server user has the correct permissions on all directories used by the external web server.
   Otherwise, you might receive `failed (XX: Permission denied) while reading upstream` errors.

1. Add the non-bundled web server to the list of trusted proxies:

   Linux package installations usually default the list of trusted proxies to the
   configuration in the `real_ip` module for the bundled NGINX.

   For non-bundled web servers, configure the list directly. Include the IP address of your web server
   if it is not on the same machine as GitLab.
   Otherwise, users appear to be signed in from your web server's IP address.

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. Optional. If you use Apache, set GitLab Workhorse settings:

   Apache cannot connect to a UNIX socket and must connect to a
   TCP port. To allow GitLab Workhorse to listen on TCP (by default port 8181),
   edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   Run `sudo gitlab-ctl reconfigure` for the change to take effect.

1. Download the correct web server configuration:

   Go to the [GitLab repository](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/support/nginx) and download
   the required configuration.
   Select the correct configuration file for serving GitLab with or without SSL.
   You might need to change:

   - The value of `YOUR_SERVER_FQDN` to your FQDN.
   - If you use SSL, the location of your SSL keys.
   - The location of your log files.

## NGINX configuration options

GitLab provides various configuration options to customize NGINX behavior for your specific needs.
Use these reference items to fine-tune your NGINX setup and optimize GitLab performance and security.

### Set the NGINX listen addresses

By default, NGINX accepts incoming connections on all local IPv4 addresses.

To change the list of addresses:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Listen on all IPv4 and IPv6 addresses
   nginx['listen_addresses'] = ["0.0.0.0", "[::]"]
   registry_nginx['listen_addresses'] = ['*', '[::]']
   mattermost_nginx['listen_addresses'] = ['*', '[::]']
   pages_nginx['listen_addresses'] = ['*', '[::]']
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

### Set the NGINX listen port

By default, NGINX listens on the port specified in `external_url` or
uses the standard port (80 for HTTP, 443 for HTTPS). If you run
GitLab behind a reverse proxy, you might want to override the listen port.

To change the listen port:

1. Edit `/etc/gitlab/gitlab.rb`.
   For example, to use port 8081:

   ```ruby
   nginx['listen_port'] = 8081
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

### Change the verbosity level of NGINX logs

By default, NGINX logs at the `error` verbosity level.

To change the log level:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['error_log_level'] = "debug"
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

For valid log level values, see the [NGINX documentation](https://nginx.org/en/docs/ngx_core_module.html#error_log).

### Set the Referrer-Policy header

By default, GitLab sets the `Referrer-Policy` header to `strict-origin-when-cross-origin` on all responses.
This setting makes the client:

- Send the full URL as referrer for same-origin requests.
- Send only the origin for cross-origin requests.

To change this header:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['referrer_policy'] = 'same-origin'
   ```

   To disable this header and use the client's default setting:

   ```ruby
   nginx['referrer_policy'] = false
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

WARNING:
Setting this to `origin` or `no-referrer` breaks GitLab features that require the full referrer URL.

For more information, see the [Referrer Policy specification](https://www.w3.org/TR/referrer-policy/).

### Disable Gzip compression

By default, GitLab enables Gzip compression for text data over 10240 bytes. To disable Gzip compression:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['gzip_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

NOTE:
The `gzip` setting applies only to the main GitLab application, not to other services.

### Disable proxy request buffering

To disable request buffering for specific locations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.
1. Reload NGINX configuration gracefully:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

For more information about the `hup` command, see the
[NGINX documentation](https://nginx.org/en/docs/control.html).

### Configure `robots.txt`

To configure a custom [`robots.txt`](https://www.robotstxt.org/robotstxt.html) file for your instance:

1. Create your custom `robots.txt` file and note its path.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

   Replace `/path/to/custom/robots.txt` with the actual path to your custom `robots.txt` file.

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

This configuration adds a [custom NGINX setting](#insert-custom-nginx-settings-into-the-gitlab-server-block)
to serve your custom `robots.txt` file.

### Insert custom NGINX settings into the GitLab server block

To add custom settings to the NGINX `server` block for GitLab:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Example: block raw file downloads from a specific repository
   nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

This inserts the defined string at the end of the `server` block in
`/var/opt/gitlab/nginx/conf/gitlab-http.conf`.

WARNING:
Custom settings might conflict with settings defined elsewhere in your `gitlab.rb` file.

#### Notes

- If you're adding a new location, you might need to include:

  ```conf
  proxy_cache off;
  proxy_http_version 1.1;
  proxy_pass http://gitlab-workhorse;
  ```

  Without these, any sub-location might return a 404 error.

- You cannot add the root `/` location or the `/assets` location, as they already
  exist in `gitlab-http.conf`.

### Insert custom settings into the NGINX configuration

To add custom settings to the NGINX configuration:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Example: include a directory to scan for additional config files
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/sites-enabled/*.conf;"
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

This inserts the defined string at the end of the `http` block in
`/var/opt/gitlab/nginx/conf/nginx.conf`.

For example, to create and enable custom server blocks:

1. Create custom server blocks in the `/etc/gitlab/nginx/sites-available` directory.
1. Create the `/etc/gitlab/nginx/sites-enabled` directory if it doesn't exist.
1. To enable a custom server block, create a symlink:

   ```shell
   sudo ln -s /etc/gitlab/nginx/sites-available/example.conf /etc/gitlab/nginx/sites-enabled/example.conf
   ```

1. Reload NGINX configuration:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

   Alternatively, you can restart NGINX:

   ```shell
   sudo gitlab-ctl restart nginx
   ```

You can add domains for server blocks [as an alternative name](ssl/index.md#add-alternative-domains-to-the-certificate)
to the generated Let's Encrypt SSL certificate.

Custom NGINX settings inside the `/etc/gitlab/` directory are backed up to `/etc/gitlab/config_backup/`
during an upgrade and when `sudo gitlab-ctl backup-etc` is manually executed.

### Configure custom error pages

To modify text on the default GitLab error pages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['custom_error_pages'] = {
    '404' => {
      'title' => 'Example title',
      'header' => 'Example header',
      'message' => 'Example message'
    }
   }
   ```

   This example modifies the default 404 error page. You can use this format for any valid HTTP error code, such as 404 or 502.

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

The result for the 404 error page would look like this:

![custom 404 error page](img/error_page_example.png)

### Use an existing Passenger and NGINX installation

You can host GitLab with an existing Passenger and NGINX installation and still use Linux packages for updates and installation.

If you disable NGINX, you can't access other services included in a Linux package installation, such as
Mattermost, unless you manually add them to `nginx.conf`.

#### Configuration

To set up GitLab with an existing Passenger and NGINX installation:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Define the external url
   external_url 'http://git.example.com'

   # Disable the built-in NGINX
   nginx['enable'] = false

   # Disable the built-in Puma
   puma['enable'] = false

   # Set the internal API URL
   gitlab_rails['internal_api_url'] = 'http://git.example.com'

   # Define the web server process user (ubuntu/nginx)
   web_server['external_users'] = ['www-data']
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

#### Configure the virtual host (server block)

In your custom Passenger/NGINX installation:

1. Create a new site configuration file with the following content:

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

      proxy_http_version 1.1;
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

    error_page 502 /502.html;
   }
   ```

   Replace `git.example.com` with your server URL.

If you receive a 403 Forbidden error, ensure Passenger is enabled in `/etc/nginx/nginx.conf`:

1. Uncomment this line:

   ```plaintext
   # include /etc/nginx/passenger.conf;
   ```

1. Reload the NGINX configuration:

   ```shell
   sudo service nginx reload
   ```

### Configure NGINX status monitoring

By default, GitLab configures an NGINX health-check endpoint at `127.0.0.1:8060/nginx_status` to
monitor your NGINX server status.

The endpoint displays the following information:

```plaintext
Active connections: 1
server accepts handled requests
18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- Active connections: Open connections in total.
- Three figures showing:
  - All accepted connections.
  - All handled connections.
  - Total number of handled requests.
- Reading: NGINX reads request headers.
- Writing: NGINX reads request bodies, processes requests, or writes responses to a client.
- Waiting: Keep-alive connections. This number depends on the `keepalive_timeout` directive.

#### Configure NGINX status options

To configure NGINX status options:

1. Edit `/etc/gitlab/gitlab.rb`:

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

   To disable the NGINX status endpoint:

   ```ruby
   nginx['status'] = {
    'enable' => false
   }
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#linux-package-installations)
   for the changes to take effect.

#### Configure user permissions for uploads

To ensure user uploads are accessible, add your NGINX user (usually `www-data`) to the `gitlab-www`
group:

```shell
sudo usermod -aG gitlab-www www-data
```

### Templates

The configuration files are similar to the [bundled GitLab NGINX configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-http.conf.erb), with these differences:

- Passenger configuration is used instead of Puma.
- HTTPS is not enabled by default, but you can enable it.

After making changes to the NGINX configuration:

- For Debian-based systems, restart NGINX:

  ```shell
  sudo service nginx restart
  ```

- For other systems, refer to your operating system's documentation for the correct command to restart NGINX.
