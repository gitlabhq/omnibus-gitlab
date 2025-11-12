---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenSSL 3にアップグレードする
---

[バージョン17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)以降、GitLabはOpenSSL 3を使用します。このバージョンのOpenSSLは、主要なリリースであり、注目すべき非推奨事項とOpenSSLのデフォルトの動作の変更があります（詳細については、[OpenSSL 3移行ガイド](https://docs.openssl.org/3.0/man7/migration_guide/)を参照してください）。

外部インテグレーション用のTLSと暗号スイートの古いバージョンの一部は、これらの変更と互換性がない可能性があります。したがって、OpenSSL 3を使用するGitLabのバージョンにアップグレードする前に、外部インテグレーションの互換性を評価することが重要です。

OpenSSL 3へのアップグレードにより、以下が必要になります:

- すべての受信および発信TLS接続には、TLS 1.2以上が必要です。
- TLS証明書には、少なくとも112ビットのセキュリティが必要です。2048ビット未満のRSA、DSA、DHキー、および224ビット未満のECCキーは禁止されています。

## オペレーティングシステムのアップグレードは不要 {#no-operating-system-upgrades-needed}

GitLabがOpenSSL 3をサポートするために、オペレーティングシステムのアップグレードは必要ありません。Helm Chartの場合、GitLab CEとEEには独自のバージョンのOpenSSLが付属しており、オペレーティングシステムのOpenSSLバージョンは使用されません。ただし、[FIPSビルド](https://docs.gitlab.com/ee/development/fips_compliance.html)では、そのライブラリがFIPS認定されることが期待されるため、オペレーティングシステムのOpenSSLが使用されます。

## 外部インテグレーションの特定 {#identifying-external-integrations}

外部インテグレーションは、`gitlab.rb`またはプロジェクト、グループ、管理者の**設定**にあるGitLab Webインターフェースから設定できます。

使用できるインテグレーションの予備リストを次に示します:

- 認証と認可
  - [LDAPサーバー](https://docs.gitlab.com/administration/auth/ldap/)
  - [OmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/)、特にSAMLまたはShibbolethなどの一般的でないプロバイダー。
  - [承認済みのアプリケーション](https://docs.gitlab.com/integration/oauth_provider/#view-all-authorized-applications)
- メール
  - [受信メール](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)
  - [サービスデスク](https://docs.gitlab.com/user/project/service_desk/configure/)
  - [SMTPサーバー](../smtp.md)
- [プロジェクトインテグレーション](https://docs.gitlab.com/user/project/integrations/)
- [外部イシュートラッカー](https://docs.gitlab.com/integration/external-issue-tracker/)
- [Webhook](https://docs.gitlab.com/user/project/integrations/webhooks/)
- [外部PostgreSQL](https://docs.gitlab.com/administration/postgresql/external/)
- [外部Redis](https://docs.gitlab.com/administration/redis/replication_and_failover_external/)
- [オブジェクトストレージ](https://docs.gitlab.com/administration/object_storage/)
- [ClickHouse](https://docs.gitlab.com/integration/clickhouse/)
- モニタリング
  - [外部Prometheusサーバー](https://docs.gitlab.com/administration/monitoring/prometheus/#using-an-external-prometheus-server)
  - [Grafana](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/)
  - [リモートPrometheus](../prometheus.md#remote-readwrite)

Linuxパッケージに同梱されているすべてのコンポーネントは、OpenSSL 3と互換性があります。したがって、GitLabパッケージに含まれていない、「外部」のサービスとの連携のみを確認する必要があります。

## OpenSSL 3との互換性の評価 {#assessing-compatibility-with-openssl-3}

外部インテグレーションエンドポイントの互換性を確認するために、さまざまなツールを使用できます。使用しているツールに関係なく、サポートされているTLSバージョンと暗号スイートを確認する必要があります。

### `openssl`コマンドラインツール {#openssl-command-line-tool}

TLS対応サーバーに接続するには、[`openssl s_client`](https://docs.openssl.org/3.0/man1/openssl-s_client/)コマンドラインツールを使用できます。特定のTLSバージョンまたは暗号を適用するために使用できる幅広いオプションがあります。

1. システムの`openssl`クライアントを使用して、バージョンを確認してOpenSSL 3コマンドラインツールを使用していることを確認してください:

   ```shell
   openssl version
   ```

   [GitLabに付属しているOpenSSLのバージョン](_index.md#details-on-how-gitlab-and-ssl-work)がバージョン3にアップグレードされたときに互換性を確保するために、システムOpenSSLクライアントでこのチェックを実行します。

1. サーバーが暗号とTLSバージョンをサポートしているかどうかを確認する、次のシェルスクリプトの例を使用します:

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

SMTPサーバーに接続する場合など、場合によっては、TLS接続を確立するために`-starttls`オプションを指定する必要があります。詳細については、[OpenSSLドキュメント](https://docs.openssl.org/master/man1/openssl-s_client/#options)を参照してください。例: 

```shell
openssl s_client -connect YOUR_DATABASE_SERVER:5432 -tls1_2 -starttls postgres
```

### Nmap `ssl-enum-ciphers`スクリプト {#nmap-ssl-enum-ciphers-script}

Nmapの[`ssl-enum-ciphers`スクリプト](https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html)は、サポートされているTLSバージョンと暗号を識別し、詳細な出力を提供します。

1. [`nmap`をインストール](https://nmap.org/book/install.html)。
1. 使用しているバージョンがOpenSSL 3と互換性があることを確認します:

   ```shell
   nmap --version
   ```

   出力には、Nampが「コンパイルに使用」しているOpenSSLバージョンの詳細が表示されます。

1. テストしているサイトに対して`nmap`を実行します:

   ```shell
   nmap -sV --script ssl-enum-ciphers -p PORT HOST
   ```

   次のような出力が得られるはずです:

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
