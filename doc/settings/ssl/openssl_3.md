# Upgrading to OpenSSL 3

Starting from [version 17.5](https://docs.gitlab.com/ee/update/versions/gitlab_17_changes.html#1750),
GitLab uses OpenSSL 3. This version of OpenSSL is a major release with notable
deprecations and changes to the default behavior of OpenSSL (for more details
see the [OpenSSL 3 migration guide](https://docs.openssl.org/3.0/man7/migration_guide/)).

Some of the older versions of TLS and cipher suites for external integrations
may not be compatible with these changes. Therefore, it is crucial that you
assess the compatibility of your external integrations before upgrading to a
GitLab version that uses OpenSSL 3.

With the upgrade to OpenSSL 3:

- TLS 1.2 or higher is required for all incoming and outgoing TLS connections.
- TLS certificates must have at least 112 bits of security. RSA, DSA, and DH
  keys shorter than 2048 bits, and ECC keys shorter than 224 bits are
  prohibited.

## Identifying external integrations

External integrations can be configured either with `gitlab.rb` or through the
GitLab web interface under the project, group, or admin **Settings**.

Here is a preliminary list of integrations that you can use:

- Authentication and authorization
  - [LDAP servers](https://docs.gitlab.com/ee/administration/auth/ldap/)
  - [OmniAuth providers](https://docs.gitlab.com/ee/integration/omniauth.html),
     esp. uncommon providers, for example for SAML or Shibboleth.
  - [Authorized applications](https://docs.gitlab.com/ee/integration/oauth_provider.html#view-all-authorized-applications)
- Email
  - [Incoming email](https://docs.gitlab.com/ee/administration/incoming_email.html#configuration-examples)
  - [Service Desk](https://docs.gitlab.com/ee/user/project/service_desk/configure.html)
  - [SMTP servers](../smtp.md)
- [Project integrations](https://docs.gitlab.com/ee/user/project/integrations/index.html)
- [External issue trackers](https://docs.gitlab.com/ee/integration/external-issue-tracker.html)
- [Webhooks](https://docs.gitlab.com/ee/user/project/integrations/webhooks.html)
- [External PostgreSQL](https://docs.gitlab.com/ee/administration/postgresql/external.html)
- [External Redis](https://docs.gitlab.com/ee/administration/redis/replication_and_failover_external.html)
- [Object storage](https://docs.gitlab.com/ee/administration/object_storage.html)
- [ClickHouse](https://docs.gitlab.com/ee/integration/clickhouse.html)
- Monitoring
  - [External Prometheus server](https://docs.gitlab.com/ee/administration/monitoring/prometheus/#using-an-external-prometheus-server)
  - [Grafana](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html)
  - [Remote Prometheus](../prometheus.md#remote-readwrite)

All components that are shipped with the Linux package are compatible with
OpenSSL 3. Therefore, you only need to verify the services that are not part of
the GitLab package and are "external".

## Assessing compatibility with OpenSSL 3

You can use different tools to verify compatibility of the external integration
endpoints. Regardless of the tool that your're using, you need to check the
supported TLS version and cipher suites.

### `openssl` command-line tool

You can use [`openssl s_client`](https://docs.openssl.org/3.0/man1/openssl-s_client/)
command-line tool to connect to TLS-enabled server. It has a wide range of
options that you can use to enforce specific TLS version or ciphers:

1. Make sure that you are using the OpenSSL 3 command-line tool by checking
   the version:

   ```shell
   openssl version
   ```

1. Use the following example script that checks if a server supports the ciphers
   and TLS versions:

   ```shell
   # Host and port of the server
   SERVER='HOST:PORT'

   # Check supported ciphers for TLS1.2 and TLS1.3
   # See `openssl s_client` manual for other available options.
   for tls_version in tls1_2 tls1_3; do
     echo "Supported ciphers for ${tls_version}:"
     for cipher in $(openssl ciphers -${tls_version} | sed -e 's/:/ /g'); do
       # NOTE: The cipher will be combined with any TLSv1.3 cipher suites that
       # have been configured.
       if openssl s_client -${tls_version} -cipher "${cipher}" -connect ${SERVER} </dev/null >/dev/null 2>&1; then
         echo "\t${cipher}"
       fi
     done
   done
   ```

### Nmap `ssl-enum-ciphers` script

Nmap's [`ssl-enum-ciphers` script](https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html)
identifies supported TLS versions and ciphers and provides a detailed output.

1. [Install `nmap`](https://nmap.org/book/install.html).
1. Check that the version you're using is compatible with OpenSSL 3:

   ```shell
   nmap --version
   ```

   The output should show version details including the OpenSSL version that
   Namp is "compiled with".

1. Run `nmap` against the site you're testing:

   ```shell
   nmap -sV --script ssl-enum-ciphers -p PORT HOST
   ```

   You should see an output similar to the following:

   ```plaintext
   PORT    STATE SERVICE  VERSION
   443/tcp open  ssl/http Cloudflare http proxy
   | ssl-enum-ciphers:
   |   TLSv1.2:
   |     ciphers:
   |       TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256-draft (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_128_GCM_SHA256 (rsa 2048) - A
   |       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_256_GCM_SHA384 (rsa 2048) - A
   |       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_128_CBC_SHA256 (rsa 2048) - A
   |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 (ecdh_x25519) - A
   |       TLS_RSA_WITH_AES_256_CBC_SHA256 (rsa 2048) - A
   |     compressors:
   |       NULL
   |     cipher preference: server
   |   TLSv1.3:
   |     ciphers:
   |       TLS_AKE_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
   |       TLS_AKE_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
   |       TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 (ecdh_x25519) - A
   |     cipher preference: client
   |_  least strength: A
   |_http-server-header: cloudflare
   ```
