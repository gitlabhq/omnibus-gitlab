---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure SSL for a Linux package installation **(FREE SELF)**

The Linux package supports several common use cases for SSL configuration.

By default, HTTPS is not enabled. To enable HTTPS, you can:

- Use Let's Encrypt for free, automated HTTPS.
- Manually configure HTTPS with your own certificates.

NOTE:
If you use a proxy, load balancer or some other external device to terminate SSL for the GitLab host name,
see [External, proxy, and load balancer SSL termination](#configure-a-reverse-proxy-or-load-balancer-ssl-termination).

The following table shows which method each GitLab service supports.

| Service | Manual SSL | Let's Encrypt integration |
|-|-|-|
| GitLab instance domain | [Yes](#configure-https-manually) | [Yes](#enable-the-lets-encrypt-integration) |
| Container Registry | [Yes](https://docs.gitlab.com/ee/administration/packages/container_registry.html#configure-container-registry-under-its-own-domain) | [Yes](#enable-the-lets-encrypt-integration) |
| Mattermost | [Yes](https://docs.gitlab.com/ee/integration/mattermost/index.html#running-gitlab-mattermost-with-https) | [Yes](#enable-the-lets-encrypt-integration) |
| GitLab Pages | [Yes](https://docs.gitlab.com/ee/administration/pages/#wildcard-domains-with-tls-support) | No |

## Enable the Let's Encrypt integration

[Let's Encrypt](https://letsencrypt.org) is enabled by default if `external_url`
is set with the HTTPS protocol and no other certificates are configured.

Prerequisites:

- Ports `80` and `443` must be accessible to the public Let's Encrypt servers
  that run the validation checks. The validation
  [does not work with non-standard ports](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3580).
  If the environment is private or air-gapped, certbot (the tool used by Let's Encrypt) provides a
  [manual method](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)
  to install a Let's Encrypt certificate.

To enable Let's Encrypt:

1. Edit `/etc/gitlab/gitlab.rb` and add or change the following entries:

   ```ruby
   ## GitLab instance
   external_url "https://gitlab.example.com"         # Must use https protocol
   letsencrypt['contact_emails'] = ['foo@email.com'] # Optional

   ## Container Registry (optional), must use https protocol
   registry_external_url "https://registry.example.com"
   #registry_nginx['ssl_certificate'] = "path/to/cert"      # Must be absent or commented out

   ## Mattermost (optional), must use https protocol
   mattermost_external_url "https://mattermost.example.com"
   ```

   - Certificates expire every 90 days. Email addresses you specify for `contact_emails` receive an
     alert when the expiration date approaches.
   - The GitLab instance is the
     primary domain name on the certificate. Additional services
     such as the Container Registry are added as alternate domain names to the same
     certificate. In the example above, the primary domain is `gitlab.example.com` and
     the Container Registry domain is `registry.example.com`. You don't need
     to set up wildcard certificates.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Renew the certificates automatically

Default installations schedule renewals after midnight on every 4th day of the month.
The minute is determined by the value in `external_url` to help distribute the load
on the upstream Let's Encrypt servers.

To explicitly set the renewal times:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Renew every 7th day of the month at 12:30
   letsencrypt['auto_renew_hour'] = "12"
   letsencrypt['auto_renew_minute'] = "30"
   letsencrypt['auto_renew_day_of_month'] = "*/7"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
The certificate is renewed only if it expires in 30 days.
For example, if you set it to renew on the 1st of every month at 00:00 and the
certificate expires on the 31st, then the certificate will expire before it's renewed.

To disable the automatic renewal:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   letsencrypt['auto_renew'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Renew the certificates manually

Renew the Let's Encrypt certificates manually using either one of the following commands:

```shell
sudo gitlab-ctl reconfigure
```

```shell
sudo gitlab-ctl renew-le-certs
```

The previous commands only generate a renewal if the certificate is close to expiration.
If encountering an error during renewal, [consider the upstream rate limits](https://letsencrypt.org/docs/rate-limits/).

### Use an ACME server other than Let's Encrypt

You can use an ACME server other than Let's Encrypt, and configure GitLab to
use that to fetch a certificate. Some services that provide their own ACME
server are:

- [ZeroSSL](https://zerossl.com/documentation/acme/)
- [Buypass](https://www.buypass.com/products/tls-ssl-certificates/go-ssl)
- [SSL.com](https://www.ssl.com/guide/ssl-tls-certificate-issuance-and-revocation-with-acme/)
- [`step-ca`](https://smallstep.com/docs/step-ca/index.html)

To configure GitLab to use a custom ACME server:

1. Edit `/etc/gitlab/gitlab.rb` and set the ACME endpoints:

   ```ruby
   external_url 'https://example.com'
   letsencrypt['acme_staging_endpoint'] = 'https://ca.internal/acme/acme/directory'
   letsencrypt['acme_production_endpoint'] = 'https://ca.internal/acme/acme/directory'
   ```

   If the custom ACME server provides it, use a staging endpoint as well.
   Checking the staging endpoint first ensures that the ACME configuration is correct
   before submitting the request to ACME production. Do this to avoid ACME
   rate-limits while working on your configuration.

   The default values are:

   ```plaintext
   https://acme-staging-v02.api.letsencrypt.org/directory
   https://acme-v02.api.letsencrypt.org/directory
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Add alternative domains to the certificate

You can add alternative domains (or subject alternative names) to the Let's Encrypt certificate.
This can be helpful if you would like to use the [bundled NGINX](../nginx.md) as a
[reverse proxy for other backend applications](../nginx.md#inserting-custom-settings-into-the-nginx-configuration).

The DNS records for the alternative domains must point to the GitLab instance.

To add alternative domains to your Let's Encrypt certificate:

1. Edit `/etc/gitlab/gitlab.rb` and add the alternative domains:

    ```ruby
    # Separate multiple domains with commas
    letsencrypt['alt_names'] = ['another-application.example.com']
    ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```  

The resulting Let's Encrypt certificates generated for the main GitLab application will
include the alternative domains specified. The generated files are located at:

- `/etc/gitlab/ssl/gitlab.example.com.key` for the key.
- `/etc/gitlab/ssl/gitlab.example.com.crt` for the certificate.

## Configure HTTPS manually

WARNING:
The NGINX configuration tells browsers and clients to only communicate with your
GitLab instance over a secure connection for the next 365 days using
[HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security).
See [Configure the HTTP Strict Transport Security](#configure-the-http-strict-transport-security-hsts)
for more configuration options. If enabling HTTPS, you must provide a
secure connection to your instance for at least the next 24 months.

To enable HTTPS:

1. Edit `/etc/gitlab/gitlab.rb`:
   1. Set the `external_url` to your domain. Note the `https` in the URL:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   1. Disable the Let's Encrypt integration:

      ```ruby
      letsencrypt['enable'] = false
      ```

      GitLab attempts to renew any Let's Encrypt certificate with every reconfigure.
      If you plan to use your own manually created certificate you must disable
      the Let's Encrypt integration, otherwise the certificate could be overwritten
      due to the automatic renewal.

1. Create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
   ```

   In the example, the hostname is `gitlab.example.com`, so the Linux package installation
   looks for private key and public certificate files called
   `/etc/gitlab/ssl/gitlab.example.com.key` and `/etc/gitlab/ssl/gitlab.example.com.crt`,
   respectively. If you want, you can
   [use a different location and certificates names](#change-the-default-ssl-certificate-location).

   You must use the full certificate chain, in the correct order, to prevent
   SSL errors when clients connect: first the server certificate,
   then all intermediate certificates, and finally the root CA.

1. Optional. If the `certificate.key` file is password protected, NGINX doesn't ask for
   the password when you reconfigure GitLab. In that case, the Linux package installation
   fails silently with no error messages.

   To specify the password for the key file, store the password in a text file
   (for example, `/etc/gitlab/ssl/key_file_password.txt`) and add the following
   to `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_password_file'] = '/etc/gitlab/ssl/key_file_password.txt'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. If you are using a firewall, you may have to open port 443 to allow inbound
   HTTPS traffic:

   ```shell
   # UFW example (Debian, Ubuntu)
   sudo ufw allow https

   # lokkit example (RedHat, CentOS 6)
   sudo lokkit -s https

   # firewall-cmd (RedHat, Centos 7)
   sudo firewall-cmd --permanent --add-service=https
   sudo systemctl reload firewalld
   ```

If you are updating existing certificates, follow a
[different process](#update-the-ssl-certificates).

### Redirect `HTTP` requests to `HTTPS`

By default, when you specify an `external_url` starting with `https`, NGINX
no longer listens for unencrypted HTTP traffic on port 80. To redirect all HTTP
traffic to HTTPS:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['redirect_http_to_https'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
This behavior is enabled by default when using the [Let's Encrypt integration](#enable-the-lets-encrypt-integration).

### Change the default HTTPS port

If you need to use an HTTPS port other than the default (443), specify it
as part of the `external_url`:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   external_url "https://gitlab.example.com:2443"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Change the default SSL certificate location

If your hostname is `gitlab.example.com`, a Linux package installation
looks for a private key called `/etc/gitlab/ssl/gitlab.example.com.key`
and a public certificate called `/etc/gitlab/ssl/gitlab.example.com.crt`
by default.

To set a different location of the SSL certificates:

1. Create a directory, give it the appropriate permissions, and place the
   `.crt` and `.key` files in the directory:

   ```shell
   sudo mkdir -p /mnt/gitlab/ssl
   sudo chmod 755 /mnt/gitlab/ssl
   sudo cp gitlab.key gitlab.crt /mnt/gitlab/ssl/
   ```

   You must use the full certificate chain, in the correct order, to prevent
   SSL errors when clients connect: first the server certificate,
   then all intermediate certificates, and finally the root CA.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_certificate'] = "/mnt/gitlab/ssl/gitlab.crt"
   nginx['ssl_certificate_key'] = "/mnt/gitlab/ssl/gitlab.key"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Update the SSL certificates

If the content of your SSL certificates has been updated, but no configuration
changes have been made to `/etc/gitlab/gitlab.rb`, then reconfiguring GitLab
doesn't affect NGINX. Instead, you must cause NGINX to
[reload the existing configuration and new certificates](http://nginx.org/en/docs/control.html)
gracefully:

```shell
sudo gitlab-ctl hup nginx 
sudo gitlab-ctl hup registry
```

## Configure a reverse proxy or load balancer SSL termination

By default, Linux package installations auto-detect whether to use SSL if `external_url`
contains `https://` and configures NGINX for SSL termination.
However, if you configure GitLab to run behind a reverse proxy or an external load balancer,
some environments may want to terminate SSL outside the GitLab application.

To prevent the bundled NGINX from handling SSL termination:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['listen_port'] = 80
   nginx['listen_https'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

The external load balancer may need access to a GitLab endpoint
that returns a `200` status code (for installations requiring login, the root
page returns a `302` redirect to the login page). In that case, it's
recommended to leverage a
[health check endpoint](https://docs.gitlab.com/ee/administration/monitoring/health_check.html).

Other bundled components, like the Container Registry, GitLab Pages, or Mattermost,
use a similar strategy for proxied SSL. Set the particular component's `*_external_url` with `https://` and
prefix the `nginx[...]` configuration with the component name. For example, the
GitLab Container Registry configuration is prefixed with `registry_`:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry_external_url 'https://registry.example.com'

   registry_nginx['listen_port'] = 80
   registry_nginx['listen_https'] = false
   ```

   The same format can be used for Pages (`pages_` prefix) and Mattermost (`mattermost_` prefix).

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. You may need to configure your reverse proxy or load balancer to
   forward certain headers (for example `Host`, `X-Forwarded-Ssl`, `X-Forwarded-For`,
   `X-Forwarded-Port`) to GitLab (and Mattermost if you use one). If you forget
   this step, you may see improper redirections or errors, like
   "422 Unprocessable Entity" or "Can't verify CSRF token authenticity".

Some cloud provider services, such as AWS Certificate Manager (ACM), do not allow
the download of certificates. This prevents them from being used to terminate
on the GitLab instance. If SSL is desired between such a cloud service and
GitLab, another certificate must be used on the GitLab instance.

## Use custom SSL ciphers

By default, GitLab is using SSL ciphers that are a combination of testing on
<https://gitlab.com> and various best practices contributed by the GitLab community.

To change the SSL ciphers:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

To enable the `ssl_dhparam` directive:

1. Generate `dhparams.pem`:

   ```shell
   openssl dhparam -out /etc/gitlab/ssl/dhparams.pem 2048
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the HTTP/2 protocol

By default, when you specify that your GitLab instance is reachable
through HTTPS, the [HTTP/2 protocol](https://www.rfc-editor.org/rfc/rfc7540) is
also enabled.

The Linux package sets the required SSL ciphers that are compatible with
the HTTP/2 protocol.

If you specify your own [custom SSL ciphers](#use-custom-ssl-ciphers) and a cipher is
in the [HTTP/2 cipher blacklist](https://www.rfc-editor.org/rfc/rfc7540#appendix-A),
when you try to reach your GitLab instance you are presented with the
`INADEQUATE_SECURITY` error in your browser. In that case, consider removing the
offending ciphers from the cipher list. Changing ciphers is only necessary if
you have a very specific custom setup.

For more information on why you would want to have the HTTP/2 protocol enabled,
check out the
[NGINX HTTP/2 whitepaper](https://assets.wp.nginx.com/wp-content/uploads/2015/09/NGINX_HTTP2_White_Paper_v4.pdf?_ga=1.127086286.212780517.1454411744).

If changing the ciphers is not an option, you can disable the HTTP/2 support:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['http2_enabled'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
The HTTP/2 setting only works for the main GitLab application and not for the other services,
like GitLab Pages, Container Registry, and Mattermost.

## Enable 2-way SSL client authentication

To require web clients to authenticate with a trusted certificate, you can
enable 2-way SSL:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_verify_client'] = "on"
   nginx['ssl_client_certificate'] = "/etc/pki/tls/certs/root-certs.pem"
   ```

1. Optional. You can configure how deeply in the certificate chain NGINX should verify
   before deciding that the clients don't have a valid certificate (default is `1`).
   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['ssl_verify_depth'] = "2"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the HTTP Strict Transport Security (HSTS)

NOTE:
The HSTS settings only work for the main GitLab application and not for the other services,
like GitLab Pages, Container Registry, and Mattermost.

HTTP Strict Transport Security (HSTS) is enabled by default and it informs browsers that
they should only contact the website using HTTPS. When a browser visits a
GitLab instance even once, it remembers to no longer attempt insecure connections,
even when the user is explicitly entering a plain HTTP URL (`http://`). Plain
HTTP URLs are automatically redirected by the browser to the `https://` variant.

By default, `max_age` is set for two years, this is how long a browser will
remember to only connect through HTTPS.

To change the max age value:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['hsts_max_age'] = 63072000
   nginx['hsts_include_subdomains'] = false
   ```

   Setting `max_age` to `0` disables HSTS.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

For more information on HSTS and NGINX, see <https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/>.

## Install custom public certificates

Some environments connect to external resources for various tasks and GitLab
allows these connections to use HTTPS, and supports connections with self-signed certificates.
GitLab has its own ca-cert bundle that you can add certs to by placing the
individual custom certs in the `/etc/gitlab/trusted-certs` directory. They then
get added to the bundle. They are added using openssl's `c_rehash` method, which
only works on a [single certificate](#using-a-custom-certificate-chain).

GitLab ships with the official [CAcert.org](http://www.cacert.org/)
collection of trusted root certification authorities which are used to verify
certificate authenticity.

NOTE:
For installations that use self-signed certificates, the Linux package
provides a way to manage these certificates. For more technical details how
this works, see the [details](#details-on-how-gitlab-and-ssl-work)
at the bottom of this page.

To install custom public certificates:

1. Generate the **PEM** or **DER** encoded public certificate from your private key certificate.
1. Copy only the public certificate file into the `/etc/gitlab/trusted-certs` directory.
   If you have a multi-node installation, make sure to copy the certificate in all nodes.
   - When configuring GitLab to use a custom public certificate, by default, GitLab expects to find a certificate named
     after your GitLab domain name with a `.crt` extension. For example, if your server address is
     `https://gitlab.example.com`, the certificate should be named `gitlab.example.com.crt`.
   - If GitLab needs to connect to an external resource that uses a custom public certificate, store the certificate in
     the `/etc/gitlab/trusted-certs` directory with a `.crt` extension. You don't have to name the file based on the
     domain name of the related external resource, though it helps to use a consistent naming scheme.

   To specify a different path and file name, you can
   [change the default SSL certificate location](#change-the-default-ssl-certificate-location).

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Using a custom certificate chain

Because of a [known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1425), if using a custom certificate
chain, the server, intermediate, and root certificates **must** be put into separate files in the `/etc/gitlab/trusted-certs`
directory.

This applies in both cases where GitLab itself, or external resources GitLab must connect to, are using a custom
certificate chain.

For example, for GitLab itself you can use:

- `/etc/gitlab/trusted-certs/example.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_root.crt`

For external resources GitLab must connect to, you can use:

- `/etc/gitlab/trusted-certs/external-service.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_root.crt`

## Details on how GitLab and SSL work

The Linux package includes its own library of OpenSSL and links all compiled
programs (e.g. Ruby, PostgreSQL, etc.) against this library. This library is
compiled to look for certificates in `/opt/gitlab/embedded/ssl/certs`.

The Linux package manages custom certificates by symlinking any certificate that
gets added to `/etc/gitlab/trusted-certs/` to `/opt/gitlab/embedded/ssl/certs`
using the [c_rehash](https://www.openssl.org/docs/manmaster/man1/c_rehash.html)
tool. For example, let's suppose we add `customcacert.pem` to
`/etc/gitlab/trusted-certs/`:

```shell
$ sudo ls -al /opt/gitlab/embedded/ssl/certs

total 272
drwxr-xr-x 2 root root   4096 Jul 12 04:19 .
drwxr-xr-x 4 root root   4096 Jul  6 04:00 ..
lrwxrwxrwx 1 root root     42 Jul 12 04:19 7f279c95.0 -> /etc/gitlab/trusted-certs/customcacert.pem
-rw-r--r-- 1 root root 263781 Jul  5 17:52 cacert.pem
-rw-r--r-- 1 root root    147 Feb  6 20:48 README
```

Here we see the fingerprint of the certificate is `7f279c95`, which links to
the custom certificate.

What happens when we make an HTTPS request? Let's take a simple Ruby program:

```ruby
#!/opt/gitlab/embedded/bin/ruby
require 'openssl'
require 'net/http'

Net::HTTP.get(URI('https://www.google.com'))
```

This is what happens behind the scenes:

1. The "require `openssl`" line causes the interpreter to load `/opt/gitlab/embedded/lib/ruby/2.3.0/x86_64-linux/openssl.so`.
1. The `Net::HTTP` call then attempts to read the default certificate bundle in `/opt/gitlab/embedded/ssl/certs/cacert.pem`.
1. SSL negotiation occurs.
1. The server sends its SSL certificates.
1. If the certificates that are sent are covered by the bundle, SSL finishes successfully.
1. Otherwise, OpenSSL may validate other certificates by searching for files
   that match their fingerprints inside the predefined certificate directory. For
   example, if a certificate has the fingerprint `7f279c95`, OpenSSL will attempt
   to read `/opt/gitlab/embedded/ssl/certs/7f279c95.0`.

Note that the OpenSSL library supports the definition of `SSL_CERT_FILE` and
`SSL_CERT_DIR` environment variables. The former defines the default
certificate bundle to load, while the latter defines a directory in which to
search for more certificates. These variables should not be necessary if you
have added certificates to the `trusted-certs` directory. However, if for some
reason you need to set them, they can be [defined as environment variables](../environment-variables.md). For example:

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```

## Troubleshooting

See our [guide for troubleshooting SSL](ssl_troubleshooting.md).
