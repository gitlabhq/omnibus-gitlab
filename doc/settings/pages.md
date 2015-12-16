# GitLab Pages (EE-only)

You can run a GitLab Pages
service on your GitLab server.

## Documentation version

Make sure you view this guide from the tag (version) of GitLab you would like to install. In most cases this should be the highest numbered production tag (without rc in it). You can select the tag in the version dropdown in the top left corner of GitLab (below the menu bar).

If the highest number stable branch is unclear please check the [GitLab Blog](https://about.gitlab.com/blog/) for installation guide links by version.

## Getting started

GitLab Pages expects to run on its own virtual host. In your DNS you need to add wildcard
entry pointing to the machine, e.g. `*.pages.example.com`.

It's strongly advised to not use GitLab domain to serve user pages.

GitLab Pages is disabled by default, to enable it just tell omnibus-gitlab what
the external URL for GitLab Pages is:

```ruby
# in /etc/gitlab/gitlab.rb
pages_external_url 'http://pages.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your newly created GitLab Pages
will be reachable at `http://group.pages.example.com/project`.

## Running GitLab Pages with HTTPS

Place the ssl wildcard certificate and ssl certificate key inside of `/etc/gitlab/ssl` directory. If directory doesn't exist, create one.

In `/etc/gitlab/gitlab.rb` specify the following configuration:

```ruby
pages_external_url 'https://pages.gitlab.example'

pages_nginx['redirect_http_to_https'] = true
pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
```

where `pages-nginx.crt` and `pages-nginx.key` are ssl cert and key, respectively.
Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.
