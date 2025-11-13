---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DNS設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ドメインネームシステム（DNS）は、IPアドレスとドメイン名を対応付けるための命名システムです。

GitLabインスタンスをIPアドレスのみで実行することもできますが、ドメイン名を使用すると、次のようになります:

- 覚えやすく、使いやすい。
- HTTPSに必須。

  {{< alert type="note" >}}

  （自動SSL証明書）の[Let's Encryptインテグレーション](ssl/_index.md#enable-the-lets-encrypt-integration)を利用するには、インスタンスのドメイン名がパブリックインターネット上で解決可能である必要があります。

  {{< /alert >}}

## ドメイン名レジストラの利用 {#use-a-name-registrar}

ドメイン名をインスタンスのIPアドレスに関連付けるには、1つ以上のDNSレコードを指定する必要があります。ドメイン名のDNS設定にDNSレコードを追加することは、選択したプロバイダーに完全に依存し、このドキュメントのスコープ外です。

一般的に、プロセスは次のようになります:

1. DNSレジストラのコントロールパネルにアクセスし、DNSレコードを追加します。タイプは次のいずれかである必要があります:

   - `A`
   - `AAAA`
   - `CNAME`

   タイプは、インスタンスの基盤となるアーキテクチャによって異なります。最も一般的なものはAレコードです。

1. 構成が適用されたことを[テスト](#successful-dns-query)します。
1. SSHを使用して、GitLabがインストールされているサーバーに接続します。
1. 優先する[GitLabの設定](#gitlab-settings-that-use-dns)で、設定ファイル`(/etc/gitlab/gitlab.rb)`を編集します。

DNSレコードの詳細については、[DNSレコードの概要](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/dns_concepts/)を参照してください。

## 動的DNSサービスの利用 {#use-a-dynamic-dns-service}

本番環境以外での使用には、[nip.io](https://nip.io/)などの動的DNSサービスを使用できます。

これらは、多くの場合、本番環境または長期的なインスタンスにはおすすめできません:

- [脆弱](https://github.com/publicsuffix/list/issues/335#issuecomment-261825647)性があります。
- Let's Encryptによる[レート制限](https://letsencrypt.org/docs/rate-limits/)

## DNSを使用するGitLabの設定 {#gitlab-settings-that-use-dns}

次のGitLab設定は、DNSエントリに対応しています。

| GitLab設定            | 説明 | 設定 |
|---------------------------|-------------|---------------|
| `external_url`            | このURLは、メインのGitLabインスタンスとやり取りします。SSH/HTTP/HTTPS経由でクローンを作成したり、Web UIにアクセスしたりする場合に使用されます。GitLab Runnerは、このURLを使用してインスタンスと通信します。 | [`external_url`を設定する](configuration.md#configure-the-external-url-for-gitlab)。 |
| `registry_external_url`   | このURLは、[コンテナレジストリ](https://docs.gitlab.com/user/packages/container_registry/)との対話に使用されます。Let's Encryptインテグレーションで使用できます。このURLは、`external_url`と同じDNSエントリを使用できますが、ポートが異なります。 | [`registry_external_url`を設定する](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-domain-configuration)。 |
| `mattermost_external_url` | このURLは、[バンドルされたMattermost](https://docs.gitlab.com/integration/mattermost/)ソフトウェアに使用されます。Let's Encryptインテグレーションで使用できます。 | [`mattermost_external_url`を設定する](https://docs.gitlab.com/integration/mattermost/#getting-started)。 |
| `pages_external_url`      | デフォルトでは、[GitLab Pages](https://docs.gitlab.com/user/project/pages/)を使用するプロジェクトは、この値のサブドメイン名にデプロイされます。 | [`pages_external_url`を設定する](https://docs.gitlab.com/administration/pages/#configuration)。 |
| Auto DevOpsドメイン名        | Auto DevOpsを使用してプロジェクトをデプロイする場合、このドメイン名を使用してソフトウェアをデプロイできます。これは、インスタンスまたはクラスタリングレベルで定義できます。これはGitLab UIを使用して設定され、`/etc/gitlab/gitlab.rb`ではありません。 | [Auto DevOpsドメイン名を構成する](https://docs.gitlab.com/topics/autodevops/requirements/#auto-devops-base-domain)。 |

## トラブルシューティング {#troubleshooting}

特定のコンポーネントへのアクセスに問題がある場合、またはLet's Encryptインテグレーションが失敗している場合は、DNSの問題が発生している可能性があります。DNSが問題の原因であるかどうかを判断するには、[dig](https://en.wikipedia.org/wiki/Dig_(command))ツールを使用できます。

### DNSクエリの成功 {#successful-dns-query}

この例では、[パブリックCloudflare DNSリゾルバー](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)を使用して、クエリがグローバルに解決可能であることを確認します。ただし、[Google Public DNSリゾルバー](https://developers.google.com/speed/public-dns)などの他のパブリックリゾルバーも利用できます。

```shell
$ dig registry.gitlab.com @1.1.1.1

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> registry.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3934
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;registry.gitlab.com.  IN A

;; ANSWER SECTION:
registry.gitlab.com. 58 IN A 35.227.35.254

;; Query time: 8 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Wed Jan 31 11:16:51 CET 2024
;; MSG SIZE  rcvd: 64

```

ステータスが`NOERROR`であり、`ANSWER SECTION`に実際の結果が含まれていることを確認してください。

### DNSクエリの失敗 {#failed-dns-query}

```shell
$ dig fake.gitlab.com @1.1.1.1

; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> fake.gitlab.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 25693
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;fake.gitlab.com.  IN A

;; AUTHORITY SECTION:
gitlab.com.  1800 IN SOA diva.ns.cloudflare.com. dns.cloudflare.com. 2331688399 10000 2400 604800 1800

;; Query time: 12 msec
;; SERVER: 1.1.1.1#53(1.1.1.1) (UDP)
;; WHEN: Wed Jan 31 11:17:46 CET 2024
;; MSG SIZE  rcvd: 103

```

この例では、`status`は`NXDOMAIN`であり、`ANSWER SECTION`はありません。`SERVER`フィールドは、どのDNSサーバーが回答をクエリされたかを示します。この場合は、[パブリックCloudflare DNSリゾルバー](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)です。

### ワイルドカードDNSエントリの使用 {#use-a-wildcard-dns-entry}

[URL属性](#gitlab-settings-that-use-dns)にワイルドカードDNSを使用できますが、それぞれに完全なドメイン名を指定する必要があります。

Let's Encryptインテグレーションは、ワイルドカード証明書をフェッチしません。これは[独自で](https://certbot.eff.org/faq/#does-let-s-encrypt-issue-wildcard-certificates)行う必要があります。
