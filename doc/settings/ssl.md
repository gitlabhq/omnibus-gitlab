# SSL settings

Omnibus-gitlab ships with the official [CAcert.org](http://www.cacert.org/)
collection of trusted root certification authorities which are used to verify
certificate authenticity.

For installations that use self-signed or custom certificates, Omnibus-gitlab
provides a way to manage these certificates. For more technical details how
this works, see the [details](#details-on-how-gitlab-and-ssl-work)
at the bottom of this page.

## Install custom certificate authorities:

Starting from GitLab version *8.9*, the omnibus-gitlab package will handle
custom certificates.

1. Place your custom (Root CA) or a self-signed certificate in the
`/etc/gitlab/trusted-certs/` directory;
For example, `/etc/gitlab/trusted-certs/customcacert.pem`.
**Note**: The certificate must be either **DER- or PEM-encoded**.
1. Run `gitlab-ctl reconfigure`.

This will create a symlink in `/opt/gitlab/embedded/ssl/certs/` pointing to
your custom certificate. The symlink name is the subject hash.
**Warning** Any broken symlink found in `/opt/gitlab/embedded/ssl/certs` will be
removed and any existing symlink will not be changed.
If the directory contains valid certificates, they will be automatically moved
to `/etc/gitlab/trusted-certs`. If the directory contains any other files,
reconfigure run will fail with:

```
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE -> /opt/gitlab/embedded/ssl/certs/FILE
```

Move the files that are not certificates out of `/opt/gitlab/embedded/ssl/certs`
and run reconfigure once more.

**WARNING** In GitLab version 8.9.0, 8.9.1 and 8.9.2, the directory that was used
to hold the custom certificates was mistakenly set to `/etc/gitlab/ssl/trusted-certs/`.
If you **do not** have any files inside of this directory, it is safe to remove it.
If you do have custom certificates in there, move them to `/etc/gitlab/trusted-certs/`
and run `sudo gitlab-ctl reconfigure`.

[CAcert.org]: http://www.cacert.org/

## Let's Encrypt Integration

Omnibus-gitlab can automatically fetch and renew certificates from Let's Encrypt for you. Currently only the primary GitLab domain is supported. Other services like pages, registry, and Mattermost will be supported in a future release.

### Enabling
> **Note**: For GitLab 10.5 and 10.6, you will need to also set `letsencrypt['enable'] = true`.

To enable, ensure your `external_url` specifies `https` as the protocol, and add the following to your `/etc/gitlab/gitlab.rb`
```ruby
letsencrypt['contact_emails'] = ['foo@email.com'] # Optional
```

While the contact information is optional, it is recommended. You will receive an email alert when your certificate is nearing its 3 month expiration.

### Disabling auto-configuration

From 10.7 we will automatically use Let's Encrypt certificates if the `external_url` specifies `https`, the certificate files are absent, and the embedded nginx will be used to terminate ssl connections.

To disable this, add the following to your `/etc/gitlab/gitlab.rb`
```ruby
letsencrypt['enable'] = false
```

### Renewing

There are two commands that can be used to renew your Let's Encrypt certificates.

1. `gitlab-ctl reconfigure`
1. `gitlab-ctl renew-le-certs`

Both commands require root privileges and will only perform a request to Let's Encrypt if the certificates are close to expiration date. Please consider [LE rate limits](https://letsencrypt.org/docs/rate-limits/) if you get an error during renewal.

It is recommended to setup a scheduled task to run `gitlab-ctl renew-le-certs` to ensure your Let's Encrypt certificates stay up to date automatically.

An example cron entry to check daily
```sh
0 0 * * * /opt/gitlab/bin/gitlab-ctl renew-le-certs > /dev/null
```

## Troubleshooting

If no symlinks are created in `/opt/gitlab/embedded/ssl/certs/` and you see
the message "Skipping `cert.pem`" after running `gitlab-ctl reconfigure`, that
means there may be one of two issues:

1. The file in `/etc/gitlab/ssl/trusted-certs/` is a symlink
2. The file is not a valid PEM or DER-encoded certificate

To test whether the certificate is in a valid PEM format, you can run
`openssl` to decode the certificate. For example:

```
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
```

To test whether the certificate is in a valid DER format:

```
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

The output of a valid certificate will look something like the following:

```
Certificate:
        Data:
            Version: 1 (0x0)
            Serial Number: 3578 (0xdfa)
        Signature Algorithm: sha1WithRSAEncryption
            Issuer: C=JP, ST=Tokyo, L=Chuo-ku, O=Frank4DD, OU=WebCert Support, CN=Frank4DD Web CA/emailAddress=support@frank4dd.com
            Validity
                Not Before: Aug 22 05:26:54 2012 GMT
                Not After : Aug 21 05:26:54 2017 GMT
            Subject: C=JP, ST=Tokyo, O=Frank4DD, CN=www.example.com
            Subject Public Key Info:
                Public Key Algorithm: rsaEncryption
                    Public-Key: (512 bit)
                    Modulus:
                        00:9b:fc:66:90:79:84:42:bb:ab:13:fd:2b:7b:f8:
                        de:15:12:e5:f1:93:e3:06:8a:7b:b8:b1:e1:9e:26:
                        bb:95:01:bf:e7:30:ed:64:85:02:dd:15:69:a8:34:
                        b0:06:ec:3f:35:3c:1e:1b:2b:8f:fa:8f:00:1b:df:
                        07:c6:ac:53:07
                    Exponent: 65537 (0x10001)
        Signature Algorithm: sha1WithRSAEncryption
             14:b6:4c:bb:81:79:33:e6:71:a4:da:51:6f:cb:08:1d:8d:60:
             ec:bc:18:c7:73:47:59:b1:f2:20:48:bb:61:fa:fc:4d:ad:89:
             8d:d1:21:eb:d5:d8:e5:ba:d6:a6:36:fd:74:50:83:b6:0f:c7:
             1d:df:7d:e5:2e:81:7f:45:e0:9f:e2:3e:79:ee:d7:30:31:c7:
             20:72:d9:58:2e:2a:fe:12:5a:34:45:a1:19:08:7c:89:47:5f:
             4a:95:be:23:21:4a:53:72:da:2a:05:2f:2e:c9:70:f6:5b:fa:
             fd:df:b4:31:b2:c1:4a:9c:06:25:43:a1:e6:b4:1e:7f:86:9b:
             16:40
```

An invalid file will display something like:

```
unable to load certificate
140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
```

### Let's Encrypt issues

#### Certificate signed by unknown authority issues

The initial implementation of Let's Encrypt integration only used the certificate, and not the full certificate chain.

Starting in 10.5.4, the full certificate chain will be used. For installs which are already using a certificate, the switchover will not happen until the renewal logic indicates the certificate is near expiration. To force it sooner, run the following

```shell
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

```
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
