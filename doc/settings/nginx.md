# NGINX settings

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
