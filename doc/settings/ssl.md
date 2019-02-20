# SSL Configuration

## Available SSL Configuration Tasks

Omnibus-GitLab supports several common use cases for SSL configuration.

1. Allow `https` connections to GitLab instance services
1. Configure public certificate bundles for external resource connections

## Host Services

Administrators can enable secure http using any method supported by a GitLab service.

| **Service** | **Manual SSL** | **Let's Encrypt** |
|-|-|-|
| Primary GitLab Instance Domain | [Yes](nginx.md#manually-configuring-https) | [Yes](#lets-encrypthttpsletsencryptorg-integration) |
| Container Registry | [Yes](https://docs.gitlab.com/ce/administration/container_registry.html#configure-container-registry-under-its-own-domain) | [Yes](#lets-encrypthttpsletsencryptorg-integration) |
| Mattermost | [Yes](https://docs.gitlab.com/omnibus/gitlab-mattermost/README.html#running-gitlab-mattermost-with-https) | [Yes](#lets-encrypthttpsletsencryptorg-integration) |
| GitLab Pages | [Yes](https://docs.gitlab.com/ce/administration/pages/#wildcard-domains-with-tls-support) | No |

### [Let's Encrypt](https://letsencrypt.org) Integration

#### Primary GitLab Instance

> **Note**: Introduced in GitLab version ***10.5*** and disabled by default.
> Enabled by default in GitLab version ***10.7*** and later if `external_url` is set with the *https* protocol
> and no certificates are configured.

> **Caution**
> 
> Administrators installing or upgrading to GitLab version ***10.7*** or later and do not plan on using
> **Let's Encrypt** should set the following in `/etc/gitlab/gitlab.rb` to disable:
>
> ```ruby
> letsencrypt['enable'] = false
> ```

Add the following entries to `/etc/gitlab/gitlab.rb` to enable **Let's Encrypt**
support for the primary domain:

```ruby
letsencrypt['enable'] = true                      # GitLab 10.5 and 10.6 require this option
external_url "https://gitlab.example.com"	  # Must use https protocol
letsencrypt['contact_emails'] = ['foo@email.com'] # Optional
```

> **Maintenance Tip**
>
> Certificates issued by **Let's Encrypt** expire every ninety days. The optional `contact_emails`
> setting causes an expiration alert to be sent to the configured address when that expiration date approaches.

#### GitLab Components

> **Note**: Introduced in GitLab version ***11.0***

[Follow the steps to enable basic **Let's Encrypt** integration](#lets-encrypthttpsletsencryptorg-integration) and
modify `/etc/gitlab/gitlab.rb` with any of the following that apply:

```ruby
registry_external_url "https://registry.example.com"     # container registry, must use https protocol
mattermost_external_url "https://mattermost.example.com" # mattermost, must use https protocol
#registry_nginx['ssl_certificate'] = "path/to/cert"      # Must be absent or commented out
```

> **Under the Hood**
>
> The **Let's Encrypt** certificate is created with the GitLab primary
> instance as the primary name on the certificate. Additional services
> such as the registry are added as alternate names to the same
> certificate.
>
> Note in the example above, the primary domain is `gitlab.example.com` and
> the registry domain is `registry.example.com`. Administrators do not need
> to worry about setting up wildcard certificates.

#### Automatic Let's Encrypt Renewal

> **Note**: [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2433) in [GitLab](https://about.gitlab.com/pricing/) ***10.7***.

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

```sh
# gitlab-ctl reconfigure
```
```sh
# gitlab-ctl renew-le-certs
```

> **Tip**
>
> The above commands require root privileges and only generate a renewal if the certificate is close to expiration.
> [Consider the upstream rate limits](https://letsencrypt.org/docs/rate-limits/) if encountering an error during renewal.

## Connecting to External Resources

Some environments connect to external resources for various tasks. Omnibus-GitLab
allows these connections to use secure http (`https`).

### Default Configuration

Omnibus-GitLab ships with the official [CAcert.org](http://www.cacert.org/)
collection of trusted root certification authorities which are used to verify
certificate authenticity.

### Other Certificate Authorities

Omnibus-Gitlab supports connections to external services with
self-signed certificates.

> **Compatibility Note**
>
> Custom certificates were introduced in GitLab version **8.9**.

> **Further Reading**
> For installations that use self-signed certificates, Omnibus-GitLab
> provides a way to manage these certificates. For more technical details how
> this works, see the [details](#details-on-how-gitlab-and-ssl-work)
> at the bottom of this page.

#### Install Custom Public Certificates:

1. Generate the ***PEM*** or ***DER*** encoded public certificate from your private key certificate.
1. Copy the public certificate file only into the `/etc/gitlab/trusted-certs` directory.
1. Run `gitlab-ctl reconfigure`.

## Solving Problems

### git-LFS and other embedded services written in ***golang*** report custom certificate signed by unknown authority

NOTE: **Note:**
In GitLab 11.5, the following workaround is no longer necessary, embedded golang apps now [use the standard GitLab certificate directory automatically](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3701).

The `gitlab-workhorse` and other services written in ***golang*** use the **crypto/tls** library from ***golang***
instead of **OpenSSL**.

Add the following entry in `/etc/gitlab/gitlab.rb` to work around the
[issue as reported](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3701):

```ruby
gitlab_workhorse['env'] = {
  'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
}
```

> **Note:**
>
> If you have installed GitLab to a path other than `/opt/gitlab/` then modify the entry above
> with the correct path in your operating environment.

### Reconfigure Fails Due to Certificates

```sh
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

Check `/opt/gitlab/embedded/ssl/certs` and remove any files other than `README.md` that aren't valid x509 certificates.

> **Under the Hood**
>
> Running `gitlab-ctl reconfigure` constructs symlinks named from the subject hashes
> of your custom public certificates and places them in `/opt/gitlab/embedded/ssl/certs/`.
>
> Broken symlinks in `/opt/gitlab/embedded/ssl/certs/` will be automatically removed.
>
> Files other than `cacert.pem` and `README.md` stored in
> `/opt/gitlab/embedded/ssl/certs/` will be moved into the `/etc/gitlab/trusted-certs/`.

### Custom Certificates Missing or Skipped

GitLab versions ***8.9.0***, ***8.9.1***, and ***8.9.2*** all mistakenly used the
`/etc/gitlab/ssl/trusted-certs/` directory. This directory is safe to remove if it
is empty. If it still contains custom certificates then move them to `/etc/gitlab/trusted-certs/`
and run `gitlab-ctl reconfigure`.

If no symlinks are created in `/opt/gitlab/embedded/ssl/certs/` and you see
the message "Skipping `cert.pem`" after running `gitlab-ctl reconfigure`, that
means there may be one of two issues:

1. The file in `/etc/gitlab/ssl/trusted-certs/` is a symlink
2. The file is not a valid PEM or DER-encoded certificate

Test the certificate's validity using the commands below:

```sh
$ /opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
$ /opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

Invalid certificate files produce the following output:
```sh
unable to load certificate
140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
```

### **Let's Encrypt** Certificate signed by unknown authority

The initial implementation of **Let's Encrypt** integration only used the certificate, not the full certificate chain.

Starting in 10.5.4, the full certificate chain will be used. For installs which are already using a certificate, the switchover will not happen until the renewal logic indicates the certificate is near expiration. To force it sooner, run the following

```sh
# rm /etc/gitlab/ssl/HOSTNAME*
# gitlab-ctl reconfigure
```

Where HOSTNAME is the hostname of the certificate.

## Details on how GitLab and SSL work

GitLab-Omnibus includes its own library of OpenSSL and links all compiled
programs (e.g. Ruby, PostgreSQL, etc.) against this library.  This library is
compiled to look for certificates in `/opt/gitlab/embedded/ssl/certs`.

GitLab-Omnibus manages custom certificates by symlinking any certificate that
gets added to `/etc/gitlab/trusted-certs/` to `/opt/gitlab/embedded/ssl/certs`
using the [c_rehash](https://www.openssl.org/docs/man1.1.0/apps/c_rehash.html)
tool. For example, let's suppose we add `customcacert.pem` to
`/etc/gitlab/trusted-certs/`:

```sh
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
2. The `Net::HTTP` call then attempts to read the default certificate bundle in `/opt/gitlab/embedded/ssl/certs/cacert.pem`.
3. SSL negotiation occurs.
4. The server sends its SSL certificates.
4. If the certificates that are sent are covered by the bundle, SSL finishes successfully.
5. Otherwise, OpenSSL may validate other certificates by searching for files
that match their fingerprints inside the predefined certificate directory. For
example, if a certificate has the fingerprint `7f279c95`, OpenSSL will attempt
to read `/opt/gitlab/embedded/ssl/certs/7f279c95.0`.

Note that the OpenSSL library supports the definition of `SSL_CERT_FILE` and
`SSL_CERT_DIR` environment variables. The former defines the default
certificate bundle to load, while the latter defines a directory in which to
search for more certificates.  These variables should not be necessary if you
have added certificates to the `trusted-certs` directory. However, if for some
reason you need to set them, they can be [defined as envirnoment
variables](environment-variables.md). For example:

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```
