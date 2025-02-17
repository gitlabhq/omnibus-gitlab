---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrading to OpenSSL 3
---

Starting from [version 17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770),
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
  - [LDAP servers](https://docs.gitlab.com/administration/auth/ldap/)
  - [OmniAuth providers](https://docs.gitlab.com/integration/omniauth/),
     especially uncommon providers, for example for SAML or Shibboleth.
  - [Authorized applications](https://docs.gitlab.com/integration/oauth_provider/#view-all-authorized-applications)
- Email
  - [Incoming email](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)
  - [Service Desk](https://docs.gitlab.com/user/project/service_desk/configure/)
  - [SMTP servers](../smtp.md)
- [Project integrations](https://docs.gitlab.com/user/project/integrations/)
- [External issue trackers](https://docs.gitlab.com/integration/external-issue-tracker/)
- [Webhooks](https://docs.gitlab.com/user/project/integrations/webhooks/)
- [External PostgreSQL](https://docs.gitlab.com/administration/postgresql/external/)
- [External Redis](https://docs.gitlab.com/administration/redis/replication_and_failover_external/)
- [Object storage](https://docs.gitlab.com/administration/object_storage/)
- [ClickHouse](https://docs.gitlab.com/integration/clickhouse/)
- Monitoring
  - [External Prometheus server](https://docs.gitlab.com/administration/monitoring/prometheus/#using-an-external-prometheus-server)
  - [Grafana](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/)
  - [Remote Prometheus](../prometheus.md#remote-readwrite)

All components that are shipped with the Linux package are compatible with
OpenSSL 3. Therefore, you only need to verify the services that are not part of
the GitLab package and are "external".

## Assessing compatibility with OpenSSL 3

You can use different tools to verify compatibility of the external integration
endpoints. Regardless of the tool that you're using, you need to check the
supported TLS version and cipher suites.

### `openssl` command-line tool

You can use the [`openssl s_client`](https://docs.openssl.org/3.0/man1/openssl-s_client/)
command-line tool to connect to a TLS-enabled server. It has a wide range of
options that you can use to enforce specific TLS versions or ciphers.

1. With the system `openssl` client, make sure that you are using the OpenSSL 3 command-line tool by checking the version:

   ```shell
   openssl version
   ```

   You perform this check with the system OpenSSL client to ensure compatibility when
   [the version of OpenSSL provided with GitLab](_index.md#details-on-how-gitlab-and-ssl-work) has been upgraded to
   version 3.

1. Use the following example shell script that checks if a server supports the ciphers
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
         printf "\t%s\n" "${cipher}"
       fi
     done
   done
   ```

In some cases, like when connecting to a PostgreSQL database or to an SMTP server, you must supply the `-starttls` option to establish a TLS connection. Refer to the [OpenSSL documentation](https://docs.openssl.org/master/man1/openssl-s_client/#options) for more details. For example:

```shell
openssl s_client -connect YOUR_DATABASE_SERVER:5432 -tls1_2 -starttls postgres
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
