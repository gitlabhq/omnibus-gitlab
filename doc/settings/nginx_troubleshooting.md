---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting NGINX

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

When [configuring NGINX](nginx.md), you might encounter the following issues.

## Error: `400 Bad Request: too many Host headers`

The workaround is to make sure you don't have the `proxy_set_header` configuration in
`nginx['custom_gitlab_server_config']` settings.
Instead, use the
[`roxy_set_headers`](ssl/index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)
configuration in your `gitlab.rb` file.

## Error: `Received fatal alert: handshake_failure`

You might get an error that states:

```plaintext
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

This issue occurs when you use an older Java-based IDE client to interact with your GitLab instance.
Those IDEs can use the TLS 1 protocol, which the Linux package installations don't support by default.

To resolve this issue, upgrade ciphers on your server, similar to the user in
[issue 624](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/624#note_299061).

If it is not possible to make this server change, you can default back to the old
behavior by changing the values in your `/etc/gitlab/gitlab.rb`:

```ruby
nginx['ssl_protocols'] = "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3"
```

## Mismatch between private key and certificate

In the [NGINX logs](https://docs.gitlab.com/ee/administration/logs/index.html#nginx-logs), you might find:

```plaintext
x509 certificate routines:X509_check_private_key:key values mismatch)
```

This issue occurs when there is a mismatch between your private key and certificate.

To resolve this, match the correct private key with your certificate:

1. To ensure you have the correct key and certificate, check whether the moduli of the private key and
   certificate match:

   ```shell
   /opt/gitlab/embedded/bin/openssl rsa -in /etc/gitlab/ssl/gitlab.example.com.key -noout -modulus | /opt/gitlab/embedded/bin/openssl sha256

   /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/ssl/gitlab.example.com.crt -noout -modulus| /opt/gitlab/embedded/bin/openssl sha256
   ```

1. After you verify that they match, reconfigure and reload NGINX:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl hup nginx
   ```

## `Request Entity Too Large`

In the [NGINX logs](https://docs.gitlab.com/ee/administration/logs/index.html#nginx-logs), you might find:

```plaintext
Request Entity Too Large
```

This issue occurs when you have increased the [max import size](https://docs.gitlab.com/ee/administration/settings/import_and_export_settings.html#max-import-size).

To resolve this, increase the
[client max body size](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size).

In a Kubernetes-based GitLab installation, this setting is
[named differently](https://docs.gitlab.com/charts/charts/gitlab/webservice/#proxybodysize).

To increase the value of `client_max_body_size`:

1. Edit `/etc/gitlab/gitlab.rb` and set the preferred value:

   ```ruby
   nginx['client_max_body_size'] = '250m'
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX to cause it to reload with the updated
   configuration gracefully:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Security scan warning: `NGINX HTTP Server Detection`

This issue occurs when some security scanners detect the `Server: nginx` HTTP header.
Most scanners with this alert mark it as `Low` or `Info` severity.
For example, see [Nessus](https://www.tenable.com/plugins/nessus/106375).

You should ignore this warning, as the benefit of removing the header is low, and its presence
[helps support the NGINX project in usage statistics](https://trac.nginx.org/nginx/ticket/1644).

The workaround is to turn the header off by using `hide_server_tokens`:

1. Edit `/etc/gitlab/gitlab.rb` and set the value:

   ```ruby
   nginx['hide_server_tokens'] = 'on'
   ```

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#reconfigure-a-linux-package-installation).
1. [`HUP`](https://nginx.org/en/docs/control.html) NGINX to cause it to reload with the updated
   configuration gracefully:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

## Branch not found when using Web IDE and external NGINX

You might get an error that states:

```plaintext
Branch 'branch_name' was not found in this project's repository
```

This issue occurs when there's a trailing slash in `proxy_pass` in your NGINX configuration file.

To resolve it:

1. Edit your NGINX configuration file so there's no trailing slash in `proxy_pass`:

   ```plaintext
   proxy_pass https://1.2.3.4;
   ```

1. Restart NGINX:

   ```shell
   sudo systemctl restart nginx
   ```

## Error: `worker_connections are not enough`

You might get `502` errors from GitLab, and find the following in
[NGINX logs](https://docs.gitlab.com/ee/administration/logs/index.html#nginx-logs):

```plaintext
worker_connections are not enough
```

This issue occurs when worker connections are set to a value that's too low.

To resolve it, configure the NGINX worker connections to a higher value:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab['nginx']['worker_connections'] = 10240
   ```

   10240 connections is
   [the default value](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/374b34e2bdc4bccb73665e0dc856ae32d6082d77/files/gitlab-cookbooks/gitlab/attributes/default.rb#L883).

1. Save the file and [reconfigure GitLab](https://docs.gitlab.com/ee/administration/restart_gitlab.html#reconfigure-a-linux-package-installation)
   for the changes to take effect.
