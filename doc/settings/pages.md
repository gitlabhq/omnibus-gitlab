# GitLab Pages (EE-only)

_**Note:** This feature was [introduced][ee-80] in GitLab EE 8.3_

If you are looking for ways to upload your static content in GitLab Pages, you
probably want to read the [user documentation][user-doc].

## Documentation version

Make sure you view this guide from the tag (version) of GitLab you would like
to install. In most cases this should be the highest numbered production tag
(without rc in it). You can select the tag in the version dropdown in the top
left corner of GitLab (below the menu bar).

If the highest number stable branch is unclear please check the
[GitLab Blog](https://about.gitlab.com/blog/) for installation guide links by
version.

## Getting started

GitLab Pages expect to run on their own virtual host. In your DNS you need to
add a [wildcard DNS A record][wiki-wildcard-dns] pointing to the host that
GitLab runs. For example, an entry would look like this:

```
*.gitlabpages.com. 60 IN A 1.2.3.4
```

where `gitlabpages.com` is the domain under which GitLab Pages will be served
and `1.2.3.4` is the IP address of your GitLab instance.

It is strongly advised to **not** use the GitLab domain to serve user pages to
prevent XSS attacks.

GitLab Pages is disabled by default, to enable it just tell omnibus-gitlab what
the external URL for GitLab Pages is:

```ruby
# in /etc/gitlab/gitlab.rb
pages_external_url 'http://gitlabpages.com'
```

Run `sudo gitlab-ctl reconfigure` for the changes to take effect and read the
[user documentation][user-doc] to learn how to create a static webpage for your
project, your user or group.

## Running GitLab Pages with HTTPS

If you want the pages to be served under HTTPS, a wildcard SSL certificate is
required.

Place the certificate and key inside `/etc/gitlab/ssl` and in
`/etc/gitlab/gitlab.rb` specify the following configuration:

```ruby
pages_external_url 'https://gitlabpages.com'

pages_nginx['redirect_http_to_https'] = true
pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
```

where `pages-nginx.crt` and `pages-nginx.key` are the SSL cert and key,
respectively. Once the configuration is set, run `sudo gitlab-ctl reconfigure`
for the changes to take effect.

## Change storage path

Pages are stored by default in `/var/opt/gitlab/gitlab-rails/shared/pages`.
If you wish to store them in another location you must set it up in
`/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['pages_path'] = "/mnt/storage/pages"
```

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

[user-doc]: http://doc.gitlab.com/pages/README.md
[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
[wiki-wildcard-dns]: https://en.wikipedia.org/wiki/Wildcard_DNS_record
