---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DNS設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

「ドメインネームシステム」（DNS）は、IPアドレスとドメイン名を対応させるために使用される命名システムです。

IPアドレスのみを使用してGitLabインスタンスを実行することもできますが、ドメイン名を使用する方が次の点で優れています:

- 記憶しやすく、使いやすい。
- HTTPSには必須です。

  > [!note]
  > [Let's Encryptインテグレーション](ssl/_index.md#enable-the-lets-encrypt-integration)（自動SSL証明書）を利用するには、お使いのインスタンスのドメイン名がパブリックインターネット上で解決できる必要があります。

## ネームレジストラを使用する {#use-a-name-registrar}

ドメイン名をインスタンスのIPアドレスに関連付けるには、1つ以上のDNSレコードを指定する必要があります。ドメインのDNS設定にDNSレコードを追加することは、選択したプロバイダーによって完全に異なり、このドキュメントのスコープ外です。

一般的に、そのプロセスは以下のようになります:

1. DNSレジストラのコントロールパネルにアクセスし、DNSレコードを追加します。タイプは次のいずれかである必要があります:

   - `A`
   - `AAAA`
   - `CNAME`

   タイプはインスタンスの基盤となるアーキテクチャによって異なります。最も一般的なものはAレコードです。

1. 設定が適用されたことを[テスト](#successful-dns-query)します。
1. SSHを使用して、GitLabがインストールされているサーバーに接続します。
1. お好みの[GitLab設定](#gitlab-settings-that-use-dns)で設定ファイル`(/etc/gitlab/gitlab.rb)`を編集します。

DNSレコードの詳細については、[DNS records overview](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/dns_concepts/)を参照してください。

## 動的DNSサービスを使用する {#use-a-dynamic-dns-service}

非本番環境での使用には、[nip.io](https://nip.io/)などの動的DNSサービスを使用できます。

これらは本番環境や長期間稼働するインスタンスには推奨されません。その理由は以下の通りです:

- [セキュリティ上の問題があります](https://github.com/publicsuffix/list/issues/335#issuecomment-261825647)
- Let's Encryptによって[Rate-limited](https://letsencrypt.org/docs/rate-limits/)されます。

## GitLabの設定でDNSを使用するもの {#gitlab-settings-that-use-dns}

以下のGitLab設定は、DNSエントリに対応しています。

| GitLab設定            | 説明 | 設定 |
|---------------------------|-------------|---------------|
| `external_url`            | このURLは、メインのGitLabインスタンスとやり取りします。SSH/HTTP/HTTPS経由でクローンする場合や、ウェブUIにアクセスする場合に使用されます。GitLab Runnerは、このURLを使用してインスタンスと通信します。 | [`external_url`を設定](configuration.md#configure-the-external-url-for-gitlab)します。 |
| `registry_external_url`   | このURLは、[コンテナレジストリ](https://docs.gitlab.com/user/packages/container_registry/)とやり取りするために使用されます。Let's Encryptインテグレーションで使用できます。このURLは、`external_url`と同じDNSエントリを使用できますが、異なるポートを使用します。 | [`registry_external_url`を設定](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-domain-configuration)します。 |
| `pages_external_url`      | デフォルトでは、[GitLab Pages](https://docs.gitlab.com/user/project/pages/)を使用するプロジェクトは、この値のサブドメインにデプロイされます。 | [`pages_external_url`を設定](https://docs.gitlab.com/administration/pages/#configuration)します。 |
| Auto DevOpsドメイン        | Auto DevOpsを使用してプロジェクトをデプロイする場合、このドメインを使用してソフトウェアをデプロイできます。インスタンスまたはクラスターレベルで定義できます。これはGitLabUIを使用して設定され、`/etc/gitlab/gitlab.rb`では設定されません。 | [Auto DevOpsドメインを設定](https://docs.gitlab.com/topics/autodevops/requirements/#auto-devops-base-domain)します。 |

## トラブルシューティング {#troubleshooting}

特定のコンポーネントへのアクセスで問題がある場合、またはLet's Encryptインテグレーションが失敗している場合、DNSに問題がある可能性があります。[dig](https://en.wikipedia.org/wiki/Dig_(command))ツールを使用して、DNSが問題の原因であるかどうかを判断できます。

### 成功したDNSクエリ {#successful-dns-query}

この例では、[Public Cloudflare DNS resolver](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)を使用して、クエリがグローバルに解決できることを確認しています。ただし、[Google Public DNS resolver](https://developers.google.com/speed/public-dns)のような他のパブリックリゾルバーも利用できます。

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

ステータスが`NOERROR`であり、`ANSWER SECTION`に実際の結果があることを確認してください。

### 失敗したDNSクエリ {#failed-dns-query}

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

この例では、`status`は`NXDOMAIN`であり、`ANSWER SECTION`はありません。`SERVER`フィールドは、どのDNSサーバーに回答がクエリされたかを示しています。この場合は[Public Cloudflare DNS resolver](https://www.cloudflare.com/en-gb/learning/dns/what-is-1.1.1.1/)です。

### ワイルドカードDNSエントリを使用する {#use-a-wildcard-dns-entry}

[URL属性](#gitlab-settings-that-use-dns)にワイルドカードDNSを使用することも可能ですが、それぞれの完全なドメイン名を提供する必要があります。

Let's Encryptインテグレーションは、ワイルドカード証明書をフェッチしません。これは[ご自身で](https://certbot.eff.org/faq/#does-let-s-encrypt-issue-wildcard-certificates)行う必要があります。
