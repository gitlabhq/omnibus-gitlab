---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# SSL Configuration

## Available SSL Configuration Tasks

Omnibus-GitLab supports several common use cases for SSL configuration.

1. Allow `https` connections to GitLab instance services
1. Configure public certificate bundles for external resource connections

## Host Services

Administrators can enable secure http using any method supported by a GitLab service.

| **Service** | **Manual SSL** | **Let's Encrypt** |
|-|-|-|
| Primary GitLab Instance Domain | [Yes](nginx.md#manually-configuring-https) | [Yes](#lets-encrypt-integration) |
| Container Registry | [Yes](https://docs.gitlab.com/ee/administration/packages/container_registry.html#configure-container-registry-under-its-own-domain) | [Yes](#lets-encrypt-integration) |
| Mattermost | [Yes](../gitlab-mattermost/README.md#running-gitlab-mattermost-with-https) | [Yes](#lets-encrypt-integration) |
| GitLab Pages | [Yes](https://docs.gitlab.com/ee/administration/pages/#wildcard-domains-with-tls-support) | No |

### Let's Encrypt Integration

GitLab can be integrated with [Let's Encrypt](https://letsencrypt.org).

#### Primary GitLab Instance

> - Introduced in GitLab 10.5 and disabled by default.
> - Enabled by default in GitLab 10.7 and later if `external_url` is set with
>   the *https* protocol and no certificates are configured.

NOTE: **Note**: In order for Let's Encrypt verification to work correctly, ports 80 and 443 will
need to be accessible to the Let's Encrypt servers that run the validation. Also note that the validation
currently [does not work with non-standard ports](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3580).

CAUTION: **Caution:**
Administrators installing or upgrading to GitLab 10.7 or later and do not plan on using
**Let's Encrypt** should set `letsencrypt['enable'] = false` in `/etc/gitlab/gitlab.rb` to disable.

Add the following entries to `/etc/gitlab/gitlab.rb` to enable **Let's Encrypt**
support for the primary domain:

```ruby
letsencrypt['enable'] = true                      # GitLab 10.5 and 10.6 require this option
external_url "https://gitlab.example.com"         # Must use https protocol
letsencrypt['contact_emails'] = ['foo@email.com'] # Optional
```

TIP: **Maintenance Tip**
Certificates issued by **Let's Encrypt** expire every ninety days. The optional `contact_emails`
setting causes an expiration alert to be sent to the configured address when that expiration date approaches.

#### GitLab Components

> Introduced in GitLab 11.0.

[Follow the steps to enable basic **Let's Encrypt** integration](#lets-encrypt-integration) and
modify `/etc/gitlab/gitlab.rb` with any of the following that apply:

```ruby
registry_external_url "https://registry.example.com"     # container registry, must use https protocol
mattermost_external_url "https://mattermost.example.com" # mattermost, must use https protocol
#registry_nginx['ssl_certificate'] = "path/to/cert"      # Must be absent or commented out
```

NOTE: **Under the Hood**
The **Let's Encrypt** certificate is created with the GitLab primary
instance as the primary name on the certificate. Additional services
such as the registry are added as alternate names to the same
certificate. Note in the example above, the primary domain is `gitlab.example.com` and
the registry domain is `registry.example.com`. Administrators do not need
to worry about setting up wildcard certificates.

#### Automatic Let's Encrypt Renewal

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2433) in [GitLab](https://about.gitlab.com/pricing/) 10.7.

CAUTION: **Caution:**
Administrators installing or upgrading to GitLab 12.1 or later and plan on using
their own **Let's Encrypt** certificate should set `letsencrypt['enable'] = false` in `/etc/gitlab/gitlab.rb` to
disable automatic renewal. **Otherwise, a `gitlab-ctl reconfigure` may attempt to renew the
certificates, and thus overwrite them.**

Default installations schedule renewals after midnight on every 4th day. The minute is determined by the value in `external_url` to help distribute the load
on the upstream `Let's Encrypt` servers.

Explicitly set renewal times by adding the following to `/etc/gitlab/gitlab.rb`:

```ruby
# This example renews every 7th day at 12:30
letsencrypt['auto_renew_hour'] = "12"
letsencrypt['auto_renew_minute'] = "30"
letsencrypt['auto_renew_day_of_month'] = "*/7"
```

Disable automatic renewal with the following in `/etc/gitlab/gitlab.rb`:

```ruby
letsencrypt['auto_renew'] = false
```

#### Manual Let's Encrypt Renewal

Renew **Let's Encrypt** certificates manually using ***one*** of the following commands:

```shell
sudo gitlab-ctl reconfigure
```

```shell
sudo gitlab-ctl renew-le-certs
```

CAUTION: **Caution:**
GitLab 12.1 or later will attempt to renew any **Let's Encrypt** certificate.
If you plan to use your own **Let's Encrypt** certificate you must set `letsencrypt['enable'] = false`
in `/etc/gitlab/gitlab.rb` to disable integration. **Otherwise the certificate
could be overwritten due to the renewal.**

TIP: **Tip**
The above commands require root privileges and only generate a renewal if the certificate is close to expiration.
[Consider the upstream rate limits](https://letsencrypt.org/docs/rate-limits/) if encountering an error during renewal.

## Connecting to External Resources

Some environments connect to external resources for various tasks. Omnibus-GitLab
allows these connections to use secure http (`https`).

### Default Configuration

Omnibus-GitLab ships with the official [CAcert.org](http://www.cacert.org/)
collection of trusted root certification authorities which are used to verify
certificate authenticity.

### Other Certificate Authorities

Omnibus GitLab supports connections to external services with
self-signed certificates.

NOTE: **Compatibility Note**
Custom certificates were introduced in GitLab 8.9.

TIP: **Further Reading**
For installations that use self-signed certificates, Omnibus-GitLab
provides a way to manage these certificates. For more technical details how
this works, see the [details](#details-on-how-gitlab-and-ssl-work)
at the bottom of this page.

#### Install Custom Public Certificates

NOTE: **Note:**
A perl interpreter is required for `c_rehash` dependency to properly symlink the certificates.
[Perl is currently not bundled in Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2275).

1. Generate the ***PEM*** or ***DER*** encoded public certificate from your private key certificate.
1. Copy the public certificate file only into the `/etc/gitlab/trusted-certs` directory.
1. Run `gitlab-ctl reconfigure`.

CAUTION: **Caution:**
If using a custom certificate chain, the root and/or intermediate certificates must be put into separate files in `/etc/gitlab/trusted-certs` [due to `c_rehash` creating a hash for the first certificate only](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1425).

## Troubleshooting

### Useful OpenSSL Debugging Commands

Sometimes it's helpful to get a better picture of the SSL certificate chain by viewing it directly
at the source. These commands are part of the standard OpenSSL library of tools for diagnostics and
debugging.

NOTE: **Note:**
GitLab includes its own [custom-compiled version of OpenSSL](#details-on-how-gitlab-and-ssl-work)
that all GitLab libraries are linked against. It's important to run the following commands using
this OpenSSL version.

- Perform a test connection to the host over HTTPS. Replace `HOSTNAME` with your GitLab URL
  (excluding HTTPS), and replace `port` with the port that serves HTTPS connections (usually 443):
  
  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port
  ```  
  
  The `echo` command sends a null request to the server, causing it to close the connection rather
  than wait for additional input. You can use the same command to test remote hosts (for example, a
  server hosting an external repository), by replacing `HOSTNAME:port` with the remote host's domain
  and port number.

  This command's output shows you the certificate chain, any public certificates the server
  presents, along with validation or connection errors if they occur. This makes for a quick check
  for any immediate issues with your SSL settings.

- View a certificate's details in text form using `x509`. Be sure to replace
  `/path/to/certificate.crt` with the certificate's path:

  ```shell
  /opt/gitlab/embedded/bin/openssl x509 -in /path/to/certificate.crt -text -noout
  ```

  For example, GitLab automatically fetches and places certificates acquired from Let's Encrypt at
  `/etc/gitlab/ssl/hostname.crt`. You can use the `x509` command with that path to quickly display
  the certificate's information (for example, the hostname, issuer, validity period, and more).

  If there's a problem with the certificate, [an error occurs](#custom-certificates-missing-or-skipped).

- Fetch a certificate from a server and decode it. This combines both of the above commands to fetch
  the server's SSL certificate and decode it to text:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port | /opt/gitlab/embedded/bin/openssl x509 -text -noout
  ```

See the [troubleshooting SSL documentation](https://docs.gitlab.com/ee/administration/troubleshooting/ssl.html)
for more examples of troubleshooting SSL problems with OpenSSL.

### Common SSL errors

1. `SSL certificate problem: unable to get local issuer certificate`

    This error indicates the client cannot get the root CA. To fix this, you can either [trust the root CA](#install-custom-public-certificates) of the server you are trying to connect to on the client or [modify the certificate](nginx.md#manually-configuring-https) to present the full chained certificate on the server you are trying to connect to.

    NOTE: **Note:**
    It is recommended to use the full certificate chain in order to prevent SSL errors when clients connect. The full certificate chain order should consist of the server certificate first, followed by all intermediate certificates, with the root CA last.

1. `unable to verify the first certificate`

    This error indicates that an incomplete certificate chain is being presented by the server. To fix this error, you will need to [replace server's certificate with the full chained certificate](nginx.md#manually-configuring-https). The full certificate chain order should consist of the server certificate first, followed by all intermediate certificates, with the root CA last.

1. `certificate signed by unknown authority`

    This error indicates that the client does not trust the certificate or CA. To fix this error, the client connecting to server will need to [trust the certificate or CA](#install-custom-public-certificates).

1. `SSL certificate problem: self signed certificate in certificate chain`

    This error indicates that the client does not trust the certificate or CA. To fix this error, the client connecting to server will need to [trust the certificate or CA](#install-custom-public-certificates).

### Git-LFS and other embedded services written in ***golang*** report custom certificate signed by unknown authority

NOTE: **Note:**
In GitLab 11.5, the following workaround is no longer necessary, embedded golang apps now [use the standard GitLab certificate directory automatically](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3701).

The `gitlab-workhorse` and other services written in ***golang*** use the **crypto/tls** library from ***golang***
instead of **OpenSSL**.

Add the following entry in `/etc/gitlab/gitlab.rb` to work around the
[issue as reported](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/177#note_90203818):

```ruby
gitlab_workhorse['env'] = {
  'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
}
```

NOTE: **Note:**
If you have installed GitLab to a path other than `/opt/gitlab/` then modify the entry above
with the correct path in your operating environment.

### Reconfigure Fails Due to Certificates

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

Check `/opt/gitlab/embedded/ssl/certs` and remove any files other than `README.md` that aren't valid X.509 certificates.

NOTE: **Under the Hood**
Running `gitlab-ctl reconfigure` constructs symlinks named from the subject hashes
of your custom public certificates and places them in `/opt/gitlab/embedded/ssl/certs/`.
Broken symlinks in `/opt/gitlab/embedded/ssl/certs/` will be automatically removed.
Files other than `cacert.pem` and `README.md` stored in
`/opt/gitlab/embedded/ssl/certs/` will be moved into the `/etc/gitlab/trusted-certs/`.

### Custom Certificates Missing or Skipped

GitLab versions ***8.9.0***, ***8.9.1***, and ***8.9.2*** all mistakenly used the
`/etc/gitlab/ssl/trusted-certs/` directory. This directory is safe to remove if it
is empty. If it still contains custom certificates then move them to `/etc/gitlab/trusted-certs/`
and run `gitlab-ctl reconfigure`.

If no symlinks are created in `/opt/gitlab/embedded/ssl/certs/` and you see
the message "Skipping `cert.pem`" after running `gitlab-ctl reconfigure`, that
means there may be one of four issues:

1. The file in `/etc/gitlab/trusted-certs/` is a symlink
1. The file is not a valid PEM or DER-encoded certificate
1. Perl is not installed on the operating system which is needed for c_rehash to properly symlink certificates.
1. The certificate contains the string `TRUSTED`

Test the certificate's validity using the commands below:

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

Invalid certificate files produce the following output:

```shell
unable to load certificate
140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
```

To test if `c_rehash` is not symlinking the certificate due to a missing perl interpreter:

```shell
$ /opt/gitlab/embedded/bin/c_rehash /etc/gitlab/trusted-certs
bash: /opt/gitlab/embedded/bin/c_rehash: /usr/bin/perl: bad interpreter: No such file or directory
```

If you see this message, you will need to install perl with your distribution's package manager.

If you inspect the certificate itself, then look for the string `TRUSTED`:

```plaintext
-----BEGIN TRUSTED CERTIFICATE-----
...
-----END TRUSTED CERTIFICATE-----
```

If it does, like the example above, then try removing the string `TRUSTED` and running `gitlab-ctl reconfigure` again.

### Custom certificates not detected

If after running `gitlab-ctl reconfigure`:

1. no symlinks are created in `/opt/gitlab/embedded/ssl/certs/`;
1. you have placed custom certificates in `/etc/gitlab/trusted-certs/`; and
1. you do not see any skipped or symlinked custom certificate messages

You may be encountering an issue where Omnibus GitLab thinks that the custom
certificates have already been added.

To resolve, delete the trusted certificates directory hash:

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

Then run `gitlab-ctl reconfigure` again. The reconfigure should now detect and symlink
your custom certificates.

### **Let's Encrypt** Certificate signed by unknown authority

The initial implementation of **Let's Encrypt** integration only used the certificate, not the full certificate chain.

Starting in 10.5.4, the full certificate chain will be used. For installs which are already using a certificate, the switchover will not happen until the renewal logic indicates the certificate is near expiration. To force it sooner, run the following

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

Where HOSTNAME is the hostname of the certificate.

### **Let's Encrypt** fails on reconfigure

When you reconfigure, there are common scenarios under which Let's Encrypt may fail:

1. Let's Encrypt may fail if your server isn't able to reach the Let's Encrypt verification servers or vice versa:

   ```shell
   letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
   ```

    If you run into issues reconfiguring GitLab due to Let's Encrypt [make sure you have ports 80 and 443 open and accessible](#lets-encrypt-integration).

1. Your domain's Certification Authority Authorization (CAA) record does not allow Let's Encrypt to issue a certificate for your domain. Look for the following error in the reconfigure output:

   ```shell
   letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
   ```

1. If you're using a test domain such as `gitlab.example.com`, without a certificate, you'll see the `unable to request certificate` error shown above. In that case, disable Let's Encrypt by setting `letsencrypt['enable'] = false` in `/etc/gitlab/gitlab.rb`.

You can test your domain using the [Let's Debug](https://letsdebug.net/) diagnostic tool. It can help you figure out why you can't issue a Let's Encrypt certificate.

### Additional troubleshooting

For additional troubleshooting steps, see [Troubleshooting SSL](https://docs.gitlab.com/ee/administration/troubleshooting/ssl.html).

## Details on how GitLab and SSL work

GitLab-Omnibus includes its own library of OpenSSL and links all compiled
programs (e.g. Ruby, PostgreSQL, etc.) against this library. This library is
compiled to look for certificates in `/opt/gitlab/embedded/ssl/certs`.

GitLab-Omnibus manages custom certificates by symlinking any certificate that
gets added to `/etc/gitlab/trusted-certs/` to `/opt/gitlab/embedded/ssl/certs`
using the [c_rehash](https://www.openssl.org/docs/man1.1.0/man1/c_rehash.html)
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
reason you need to set them, they can be [defined as environment
variables](environment-variables.md). For example:

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```
