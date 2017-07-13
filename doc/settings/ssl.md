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
