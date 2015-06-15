# NGINX settings

## Enable HTTPS

### Warning

The Nginix config will tell browsers and clients to only communicate with your
GitLab instance over a secure connection for the next 24 months. By enabling
HTTPS you'll need to provide a secure connection to your instance for at least
the next 24 months.

By default, omnibus-gitlab does not use HTTPS. If you want to enable HTTPS for
gitlab.example.com, add the following statement to `/etc/gitlab/gitlab.rb`:

```ruby
# note the 'https' below
external_url "https://gitlab.example.com"

# For GitLab CI:
ci_external_url "https://ci.example.com"
```

Because the hostname in our example is 'gitlab.example.com', omnibus-gitlab
will look for key and certificate files called
`/etc/gitlab/ssl/gitlab.example.com.key` and
`/etc/gitlab/ssl/gitlab.example.com.crt`, respectively. Create the
`/etc/gitlab/ssl` directory and copy your key and certificate there.

```
sudo mkdir -p /etc/gitlab/ssl
sudo chmod 700 /etc/gitlab/ssl
sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
```

Now run `sudo gitlab-ctl reconfigure`. When the reconfigure finishes your
GitLab instance should be reachable at `https://gitlab.example.com`.

The SSL certificate and key paths are derived the same way for GitLab CI. If
you write `ci_external_url "https://ci.example.com"` then `gitlab-ctl
reconfigure` will look for `/etc/gitlab/ssl/ci.example.com.crt` and
 `/etc/gitlab/ssl/ci.example.com.key`.

If you are using a firewall you may have to open port 443 to allow inbound
HTTPS traffic.

```
# UFW example (Debian, Ubuntu)
sudo ufw allow https

# lokkit example (RedHat, CentOS 6)
sudo lokkit -s https

# firewall-cmd (RedHat, Centos 7)
sudo firewall-cmd --permanent --add-service=https
sudo systemctl reload firewalld
```

## Redirect `HTTP` requests to `HTTPS`

By default, when you specify an external_url starting with 'https', Nginx will
no longer listen for unencrypted HTTP traffic on port 80. If you want to
redirect all HTTP traffic to HTTPS you can use the `redirect_http_to_https`
setting.

```ruby
external_url "https://gitlab.example.com"
nginx['redirect_http_to_https'] = true
```

To enable HTTP to HTTPS redirects for GitLab CI, use the `nginx_ci` directive.

```ruby
ci_external_url "https://ci.example.com"
ci_nginx['redirect_http_to_https'] = true
```

## Change the default port and the SSL certificate locations

If you need to use an HTTPS port other than the default (443), just specify it
as part of the external_url.

```ruby
external_url "https://gitlab.example.com:2443"
```

The same syntax works for GitLab CI with `ci_external_url`.

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Using a non-bundled web-server

By default, omnibus-gitlab installs GitLab with bundled Nginx.
Omnibus-gitlab allows webserver access through user `gitlab-www` which resides
in the group with the same name. To allow an external webserver access to
GitLab, external webserver user needs to be added `gitlab-www` group.

To use another web server like Apache or an existing Nginx installation you will have to do
the following steps:

* Disable bundled Nginx by specifying in `/etc/gitlab/gitlab.rb`:

```ruby
nginx['enable'] = false

# For GitLab CI, use the following:
ci_nginx['enable'] = false
```

* Check the username of the non-bundled web-server user. By default, omnibus-gitlab has no default setting for external webserver user.
You have to specify the external webserver user username in the configuration!
Let's say for example that webserver user is `www-data`.
In `/etc/gitlab/gitlab.rb` set:

```ruby
web_server['external_users'] = ['www-data']
```

*This setting is an array so you can specify more than one user to be added to gitlab-www group.*

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

Note: if you are using SELinux and your web server runs under a restricted
SELinux profile you may have to [loosen the restrictions on your web
server](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache#selinux-modifications).

## Setting the NGINX listen address or addresses

By default NGINX will accept incoming connections on all local IPv4 addresses.
You can change the list of addresses in `/etc/gitlab/gitlab.rb`.

```ruby
nginx['listen_addresses'] = ["0.0.0.0", "[::]"] # listen on all IPv4 and IPv6 addresses
```

For GitLab CI, use the `ci_nginx['listen_addresses']` setting.

## Setting the NGINX listen port

By default NGINX will listen on the port specified in `external_url` or
implicitly use the right port (80 for HTTP, 443 for HTTPS). If you are running
GitLab behind a reverse proxy, you may want to override the listen port to
something else.  For example, to use port 8080:

```ruby
nginx['listen_port'] = 8080
```

Similarly, for GitLab CI:

```ruby
ci_nginx['listen_port'] = 8081
```

## Supporting proxied SSL

By default NGINX will auto-detect whether to use SSL if `external_url`
contains `https://`.  If you are running GitLab behind a reverse proxy, you
may wish to keep the `external_url` as an HTTPS address but communicate with
the GitLab NGINX internally over HTTP. To do this, you can disable HTTPS using
the `listen_https` option:

```ruby
nginx['listen_https'] = false
```

Similarly, for GitLab CI:

```ruby
ci_nginx['listen_https'] = false
```

Note that you may need to configure your reverse proxy to forward certain
headers (e.g. `Host`, `X-Forwarded-Ssl'`, `X-Forwarded-For``) to GitLab. You
may see improper redirections or errors (e.g. "422 Unprocessable Entity",
"Can't verify CSRF token authenticity") if you forget this step. For more
information, see:

http://stackoverflow.com/questions/16042647/whats-the-de-facto-standard-for-a-reverse-proxy-to-tell-the-backend-ssl-is-used
https://wiki.apache.org/couchdb/Nginx_As_a_Reverse_Proxy

## Using custom ssl ciphers

By default GitLab is using SSL ciphers that are combination of testing on gitlab.com and various best practices contributed by the GitLab community.

However, you can change the ssl ciphers by adding to `gitlab.rb`:

```ruby
  nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
```

and running reconfigure. Similar, for GitLab CI:

```ruby
  ci_nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
```

You can also enable `ssl_dhparam` directive.

First, generate `dhparams.pem` with `openssl dhparam -out dhparams.pem 2048`. Then, in `gitlab.rb` add a path to the generated file, for example:

```ruby
  nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
```

After the change run `sudo gitlab-ctl reconfigure`. Similar, for GitLab CI:

```ruby
  ci_nginx['ssl_dhparam'] = "/etc/gitlab/ssl/ci_dhparams.pem"
```

## Inserting custom NGINX settings into the GitLab server block

If you need to add custom settings into the NGINX `server` block for GitLab for
some reason you can use the following setting.

```ruby
# Example: block raw file downloads from a specific repository
nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"

# You can do the same for GitLab-CI
ci_nginx['custom_gitlab_ci_server_config'] = "some settings"
```

Run `gitlab-ctl reconfigure` to rewrite the NGINX configuration and restart
NGINX.

## Inserting custom settings into the NGINX config

If you need to add custom settings into the NGINX config, for example to include
existing server blocks, you can use the following setting.

```ruby
# Example: include a directory to scan for additional config files
nginx['custom_nginx_config'] = "include /etc/nginx/conf.d/*.conf;"
```

Run `gitlab-ctl reconfigure` to rewrite the NGINX configuration and restart
NGINX.

## Using an existing Passenger/Nginx installation

In some cases you may want to host GitLab using an existing Passenger/Nginx
installation but still have the convenience of updating and installing using
the omnibus packages.

### Configuration

First, you'll need to setup your `/etc/gitlab/gitlab.rb` to disable the built-in
Nginx and Unicorn:

```ruby
# Disable the built-in nginx
nginx['enable'] = false

# Disable the built-in nginx for Gitlab CI
ci_nginx['enable'] = false

# Disable the built-in unicorn
unicorn['enable'] = false

# Set the internal API URL
gitlab_rails['internal_api_url'] = 'http://git.yourdomain.com'
```

Make sure you run `sudo gitlab-ctl reconfigure` for the changes to take effect.

### Vhost (server block)

Then, in your custom Passenger/Nginx installation, create the following site
configuration files:

#### Gitlab

```
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

  error_page 502 /502.html;
}
```

For a typical Passenger installation this file should probably
be located at `/etc/nginx/sites-available/gitlab` and symlinked to
`/etc/nginx/sites-enabled/gitlab`.

#### Gitlab CI

```
upstream gitlab_ci {
  server unix:/var/opt/gitlab/gitlab-ci/sockets/gitlab.socket;
}

server {
  listen *:80;
  server_name ci.example.com;
  server_tokens off;
  root /opt/gitlab/embedded/service/gitlab-ci/public;

  client_max_body_size 250m;

  access_log  /var/log/gitlab/nginx/gitlab_ci_access.log;
  error_log   /var/log/gitlab/nginx/gitlab_ci_error.log;

  location / {
    ## Serve static files from defined root folder.
    ## @gitlab_ci is a named location for the upstream fallback, see below.
    try_files $uri $uri/index.html $uri.html @gitlab_ci;
  }

  ## If a file, which is not found in the root folder is requested,
  ## then the proxy passes the request to the upsteam (gitlab-ci unicorn).
  location @gitlab_ci {
    ## https://github.com/gitlabhq/gitlabhq/issues/694
    ## Some requests take more than 30 seconds.
    proxy_read_timeout      300;
    proxy_connect_timeout   300;
    proxy_redirect          off;

    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Frame-Options   SAMEORIGIN;

    proxy_pass http://gitlab_ci;
  }

}
```

For a typical Passenger installation this file should probably
be located at `/etc/nginx/sites-available/gitlab_ci` and symlinked to
`/etc/nginx/sites-enabled/gitlab_ci`.

#### Warning

To ensure that user uploads are accessible your Nginx user (usually `www-data`)
should be added to the `gitlab-www` group. This can be done using the following command:

```shell
sudo usermod -aG gitlab-www www-data
```

#### Templates

Other than the Passenger configuration in place of Unicorn and the lack of HTTPS
(although this could be enabled) these files are mostly identical to :

- [bundled Gitlab Nginx configuration](files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-http.conf.erb)
- [bundled Gitlab CI Nginx configuration](files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-ci-http.conf.erb)

Don't forget to restart Nginx to load the new configuration (on Debian-based
systems `sudo service nginx restart`).
