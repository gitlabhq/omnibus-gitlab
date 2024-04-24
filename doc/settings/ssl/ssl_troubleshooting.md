---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting SSL

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page contains a list of common SSL-related errors and scenarios that you
may encounter while working with GitLab. It should serve as an addition to the
main SSL documentation:

- [Configure SSL for a Linux package installation](index.md).
- [Self-signed certificates or custom Certification Authorities for GitLab Runner](https://docs.gitlab.com/runner/configuration/tls-self-signed.html).
- [Configure HTTPS manually](index.md#configure-https-manually).

## Useful OpenSSL Debugging Commands

Sometimes it's helpful to get a better picture of the SSL certificate chain by viewing it directly
at the source. These commands are part of the standard OpenSSL library of tools for diagnostics and
debugging.

NOTE:
GitLab includes its own [custom-compiled version of OpenSSL](index.md#details-on-how-gitlab-and-ssl-work)
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

## Common SSL errors

1. `SSL certificate problem: unable to get local issuer certificate`

   This error indicates the client cannot get the root CA. To fix this, you can either [trust the root CA](index.md#install-custom-public-certificates) of the server you are trying to connect to on the client or [modify the certificate](index.md#configure-https-manually) to present the full chained certificate on the server you are trying to connect to.

   NOTE:
   It is recommended to use the full certificate chain in order to prevent SSL errors when clients connect. The full certificate chain order should consist of the server certificate first, followed by all intermediate certificates, with the root CA last.

1. `unable to verify the first certificate`

   This error indicates that an incomplete certificate chain is being presented by the server. To fix this error, you will need to [replace server's certificate with the full chained certificate](index.md#configure-https-manually). The full certificate chain order should consist of the server certificate first, followed by all intermediate certificates, with the root CA last.

1. `certificate signed by unknown authority`

   This error indicates that the client does not trust the certificate or CA. To fix this error, the client connecting to server will need to [trust the certificate or CA](index.md#install-custom-public-certificates).

1. `SSL certificate problem: self signed certificate in certificate chain`

   This error indicates that the client does not trust the certificate or CA. To fix this error, the client connecting to server will need to [trust the certificate or CA](index.md#install-custom-public-certificates).

1. `x509: certificate relies on legacy Common Name field, use SANs instead`

   This error indicates that [SANs](http://wiki.cacert.org/FAQ/subjectAltName) (subjectAltName) must be configured in the certificate. For more information, see [this issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28841).

## Reconfigure Fails Due to Certificates

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

Check `/opt/gitlab/embedded/ssl/certs` and remove any files other than `README.md` that aren't valid X.509 certificates.

NOTE:
Running `gitlab-ctl reconfigure` constructs symlinks named from the subject hashes
of your custom public certificates and places them in `/opt/gitlab/embedded/ssl/certs/`.
Broken symlinks in `/opt/gitlab/embedded/ssl/certs/` will be automatically removed.
Files other than `cacert.pem` and `README.md` stored in
`/opt/gitlab/embedded/ssl/certs/` will be moved into the `/etc/gitlab/trusted-certs/`.

## Custom Certificates Missing or Skipped

GitLab versions ***8.9.0***, ***8.9.1***, and ***8.9.2*** all mistakenly used the
`/etc/gitlab/ssl/trusted-certs/` directory. This directory is safe to remove if it
is empty. If it still contains custom certificates then move them to `/etc/gitlab/trusted-certs/`
and run `gitlab-ctl reconfigure`.

If no symlinks are created in `/opt/gitlab/embedded/ssl/certs/` and you see
the message "Skipping `cert.pem`" after running `gitlab-ctl reconfigure`, that
means there may be one of four issues:

1. The file in `/etc/gitlab/trusted-certs/` is a symlink
1. The file is not a valid PEM- or DER-encoded certificate
1. Perl is not installed on the operating system which is needed for c_rehash to properly symlink certificates
1. The certificate contains the string `TRUSTED`

Test the certificate's validity using the commands below:

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

Invalid certificate files produce the following outputs:

- ```shell
  unable to load certificate
  140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
  ```

- ```shell
  cannot load certificate
  PEM_read_bio_X509_AUX() failed (SSL: error:0909006C:PEM routines:get_name:no start line:Expecting: TRUSTED CERTIFICATE)
  ```

In either of those cases, and if your certificates begin and end with anything other than the following:

```shell
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

Then they are not compatible with GitLab. You should separate them into the certificate components (server, intermediate, root), and convert them to the compatible PEM format.

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

## Custom certificates not detected

If after running `gitlab-ctl reconfigure`:

1. no symlinks are created in `/opt/gitlab/embedded/ssl/certs/`;
1. you have placed custom certificates in `/etc/gitlab/trusted-certs/`; and
1. you do not see any skipped or symlinked custom certificate messages

You may be encountering an issue where a Linux package installation thinks that the custom
certificates have already been added.

To resolve, delete the trusted certificates directory hash:

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

Then run `gitlab-ctl reconfigure` again. The reconfigure should now detect and symlink
your custom certificates.

## Let's Encrypt Certificate signed by unknown authority

The initial implementation of Let's Encrypt integration only used the certificate, not the full certificate chain.

Starting in 10.5.4, the full certificate chain will be used. For installs which are already using a certificate, the switchover will not happen until the renewal logic indicates the certificate is near expiration. To force it sooner, run the following

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

Where HOSTNAME is the hostname of the certificate.

## Let's Encrypt fails on reconfigure

NOTE:
You can test your domain using the [Let's Debug](https://letsdebug.net/)
diagnostic tool. It can help you figure out why you can't issue a Let's Encrypt
certificate.

When you reconfigure, there are common scenarios under which Let's Encrypt may fail:

- Let's Encrypt may fail if your server isn't able to reach the Let's Encrypt verification servers or vice versa:

  ```shell
  letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
  ```

  If you run into issues reconfiguring GitLab due to Let's Encrypt [make sure you have ports 80 and 443 open and accessible](index.md#enable-the-lets-encrypt-integration).

- Your domain's Certification Authority Authorization (CAA) record does not allow Let's Encrypt to issue a certificate for your domain. Look for the following error in the reconfigure output:

  ```shell
  letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
  ```

- If you're using a test domain such as `gitlab.example.com`, without a certificate, you'll see the `unable to request certificate` error shown above. In that case, disable Let's Encrypt by setting `letsencrypt['enable'] = false` in `/etc/gitlab/gitlab.rb`.

- [Let's Encrypt enforces rate limits](https://letsencrypt.org/docs/rate-limits/),
  which is at the top-level domain. In case you're using your cloud provider's
  hostname as the `external_url`, for example `*.cloudapp.azure.com`, Let's
  Encrypt would enforce limits to `azure.com`, which could make the certificate
  creation incomplete.

  In that case, you can try renewing the Let's Encrypt certificates manually:

  ```shell
  sudo gitlab-ctl renew-le-certs
  ```

## Using an internal CA certificate with GitLab

After configuring a GitLab instance with an internal CA certificate, you might
not be able to access it by using various CLI tools. You may experience the
following issues:

- `curl` fails:

  ```shell
  curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: unable to get local issuer certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Testing by using the [rails console](https://docs.gitlab.com/ee/administration/operations/rails_console.html#starting-a-rails-console-session)
  also fails:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

- The error `SSL certificate problem: unable to get local issuer certificate`
  is displayed when setting up a [mirror](https://docs.gitlab.com/ee/user/project/repository/mirror/index.html)
  from this GitLab instance.
- `openssl` works when specifying the path to the certificate:

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

If you have the previously described issues, add your certificate to
`/etc/gitlab/trusted-certs`, and then run `sudo gitlab-ctl reconfigure`.

## X.509 key values mismatch error

After configuring your instance with a certificate bundle, NGINX may display
the following error message:

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

This error message means that the server certificate and key you have provided
don't match. You can confirm this by running the following command and then
comparing the output:

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

The following is an example of an md5 output between a matching key and
certificate. Note the matching md5 hashes:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

This is an opposing output with a non-matching key and certificate which shows
different md5 hashes:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

If the two outputs differ like the previous example, there's a mismatch between
the certificate and key. Contact the provider of the SSL certificate for
further support.

## Using GitLab Runner with a GitLab instance configured with internal CA certificate or self-signed certificate

Besides getting the errors mentioned in
[Using an internal CA certificate with GitLab](ssl_troubleshooting.md#using-an-internal-ca-certificate-with-gitlab),
your CI pipelines may get stuck in `Pending` status. In the runner logs you may
see the following error message:

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

Follow the details in [Self-signed certificates or custom Certification Authorities for GitLab Runner](https://docs.gitlab.com/runner/configuration/tls-self-signed.html).

## Mirroring a remote GitLab repository that uses a self-signed SSL certificate

When configuring a local GitLab instance to [mirror a repository](https://docs.gitlab.com/ee/user/project/repository/mirror/index.html)
from a remote GitLab instance that uses a self-signed certificate, you may see
the `SSL certificate problem: self signed certificate` error message in the
user interface.

The cause of the issue can be confirmed by checking if:

- `curl` fails:

  ```shell
  $ curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: self signed certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Testing by using the Rails console also fails:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

To fix this problem:

- Add the self-signed certificate from the remote GitLab instance to the
  `/etc/gitlab/trusted-certs` directory on the local GitLab instance, and then
  run `sudo gitlab-ctl reconfigure` as per the instructions for
  [installing custom public certificates](index.md#install-custom-public-certificates).
- If your local GitLab instance was installed using the Helm Charts, you can
  [add your self-signed certificate to your GitLab instance](https://docs.gitlab.com/runner/install/kubernetes.html#providing-a-custom-certificate-for-accessing-gitlab).

You may also get another error message when trying to mirror a repository from
a remote GitLab instance that uses a self-signed certificate:

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

In this case, the problem can be related to the certificate itself:

1. Validate that your self-signed certificate isn't missing a common name. If it
   is, regenerate a valid certificate
1. Add the certificate to `/etc/gitlab/trusted-certs`.
1. Run `sudo gitlab-ctl reconfigure`.

## Unable to perform Git operations due to an internal or self-signed certificate

If your GitLab instance is using a self-signed certificate, or if the
certificate is signed by an internal certificate authority (CA), you might
experience the following errors when attempting to perform Git operations:

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': SSL certificate problem: self signed certificate
```

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
```

To fix this problem:

- If possible, use SSH remotes for all Git operations. This is considered more
  secure and convenient to use.
- If you must use HTTPS remotes, you can try the following:
  - Copy the self-signed certificate or the internal root CA certificate to a
    local directory (for example, `~/.ssl`) and configure Git to trust your
    certificate:

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - Disable SSL verification in your Git client. This is intended as a
    temporary measure, as it could be considered a security risk.

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connect wrong version number

A misconfiguration may result in:

- `gitlab-rails/exceptions_json.log` entries containing:

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- `gitlab-workhorse/current` containing:

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- `gitlab-rails/sidekiq.log` or `sidekiq/current` containing:

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

Some of these errors come from the Excon Ruby gem, and could be generated in
circumstances where GitLab is configured to initiate an HTTPS session to a
remote server that is serving only HTTP.

One scenario is that you're using [object storage](https://docs.gitlab.com/ee/administration/object_storage.html), which
isn't served under HTTPS. GitLab is misconfigured and attempts a TLS handshake,
but the object storage responds with plain HTTP.

## `schannel: SEC_E_UNTRUSTED_ROOT`

If you're on Windows and get the following error:

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

You must specify that Git should use OpenSSL:

```shell
git config --system http.sslbackend openssl
```

Alternatively, you can ignore SSL verification by running:

WARNING:
Proceed with caution when [ignoring SSL](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslVerify)
due to the potential security issues associated with disabling this option at global level. Use this option _only_ when troubleshooting, and reinstate SSL verification immediately after.

```shell
git config --global http.sslVerify false
```
