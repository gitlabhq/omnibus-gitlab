---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LinuxパッケージインストールでのSSLの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージは、SSL設定に関するいくつかの一般的なユースケースをサポートしています。

デフォルトでは、HTTPSは有効になっていません。HTTPSを有効にするには、次の手順を実行します:

- 無償の自動HTTPSのためにLet's Encryptを使用します。
- 独自の証明書を使用してHTTPSを手動で設定します。

{{< alert type="note" >}}

プロキシ、ロードバランサー、またはその他の外部デバイスを使用してGitLabホスト名のSSLを終了する場合は、[外部、プロキシ、およびロードバランサーのSSL終端](#configure-a-reverse-proxy-or-load-balancer-ssl-termination)を参照してください。

{{< /alert >}}

次の表に、各GitLabサービスがサポートするメソッドを示します。

| サービス                | 手動SSL                                                                                                                   | Let's Encryptのインテグレーション |
|------------------------|------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| GitLabインスタンスのドメイン | [はい](#configure-https-manually)                                                                                             | [はい](#enable-the-lets-encrypt-integration) |
| コンテナレジストリ     | [はい](https://docs.gitlab.com/administration/packages/container_registry/#configure-container-registry-under-its-own-domain) | [はい](#enable-the-lets-encrypt-integration) |
| Mattermost             | [はい](https://docs.gitlab.com/integration/mattermost/#running-gitlab-mattermost-with-https)                                  | [はい](#enable-the-lets-encrypt-integration) |
| GitLab Pages           | [はい](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)                                       | いいえ                        |

## OpenSSL 3のアップグレード {#openssl-3-upgrade}

[バージョン17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)以降、GitLabはOpenSSL 3を使用します。古いTLSプロトコルや暗号スイート、または外部インテグレーションに使用する脆弱なTLS証明書の一部は、OpenSSL 3のデフォルトと互換性がない場合があります。

GitLab 17.7にアップグレードする前に、[OpenSSL 3ガイド](openssl_3.md)を使用して、外部インテグレーションの互換性を特定して評価します。

GitLab 17.7にアップグレードした後、GitLabが次のコマンドでOpenSSL 3を使用していることを検証できます:

```shell
/opt/gitlab/embedded/bin/openssl version
```

## Let's Encryptのインテグレーションを有効にする {#enable-the-lets-encrypt-integration}

`external_url`がHTTPSプロトコルで設定され、他の証明書が設定されていない場合、[Let's Encrypt](https://letsencrypt.org)はデフォルトで有効になります。

前提要件: 

- ポート`80`と`443`は、検証チェックを実行するパブリックLet's Encryptサーバーからアクセスできる必要があります。検証は[非標準ポートでは機能しません](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3580)。環境がプライベートまたはエアギャップの場合、certbot（Let's Encryptで使用されるツール）は、Let's Encrypt証明書をインストールするための[手動メソッド](https://eff-certbot.readthedocs.io/en/stable/using.html#manual)を提供します。

Let's Encryptを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集し、次のエントリを追加または変更します:

   ```ruby
   ## GitLab instance
   external_url "https://gitlab.example.com"         # Must use https protocol
   letsencrypt['contact_emails'] = ['foo@email.com'] # Optional

   ## Container Registry (optional), must use https protocol
   registry_external_url "https://registry.example.com"
   #registry_nginx['ssl_certificate'] = "path/to/cert"      # Must be absent or commented out

   ## Mattermost (optional), must use https protocol
   mattermost_external_url "https://mattermost.example.com"
   ```

   - 証明書の有効期限は90日ごとに切れます。`contact_emails`に指定したメールアドレスは、有効期限日が近づくとアラートを受信します。
   - GitLabインスタンスは、証明書のプライマリドメイン名です。コンテナレジストリなどの追加サービスは、同じ証明書の代替ドメイン名として追加されます。上記の例では、プライマリドメインは`gitlab.example.com`で、コンテナレジストリのドメインは`registry.example.com`です。ワイルドカード証明書をセットアップする必要はありません。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Let's Encryptが証明書の発行に失敗した場合は、考えられる解決策について[トラブルシューティングセクション](ssl_troubleshooting.md#lets-encrypt-fails-on-reconfigure)を参照してください。

### 証明書を自動的に更新する {#renew-the-certificates-automatically}

デフォルトのインストールでは、毎月4日の午前0時以降に更新がスケジュールされます。分は、アップストリームLet's Encryptサーバーの負荷を分散するために、`external_url`の値によって決定されます。

更新時間を明示的に設定するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Renew every 7th day of the month at 12:30
   letsencrypt['auto_renew_hour'] = "12"
   letsencrypt['auto_renew_minute'] = "30"
   letsencrypt['auto_renew_day_of_month'] = "*/7"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

証明書は、有効期限が30日以内の場合にのみ更新されます。たとえば、毎月1日の00:00に更新するように設定し、証明書の有効期限が31日の場合、証明書は更新される前に有効期限が切れます。

{{< /alert >}}

自動更新は[go-crond](https://github.com/webdevops/go-crond)で管理されます。必要に応じて、`/etc/gitlab/gitlab.rb`を編集して、[CLI引数](https://github.com/webdevops/go-crond#usage)をgo-crondに渡すことができます:

```ruby
crond['flags'] = {
  'log.json' = true,
  'server.bind' = ':8040'
}
```

自動更新を無効にするには、次の手順を実行します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   letsencrypt['auto_renew'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 証明書を手動で更新する {#renew-the-certificates-manually}

次のいずれかのコマンドを使用して、Let's Encrypt証明書を手動で更新します:

```shell
sudo gitlab-ctl reconfigure
```

```shell
sudo gitlab-ctl renew-le-certs
```

上記のコマンドは、証明書の有効期限が近い場合にのみ更新を生成します。更新中にエラーが発生した場合は、[アップストリームレート制限を検討してください](https://letsencrypt.org/docs/rate-limits/)。

### Let's Encrypt以外のACMEサーバーを使用する {#use-an-acme-server-other-than-lets-encrypt}

Let's Encrypt以外のACMEサーバーを使用し、それを使用して証明書をフェッチするようにGitLabを設定できます。独自のACMEサーバーを提供するサービスには、次のようなものがあります:

- [ZeroSSL](https://zerossl.com/documentation/acme/)
- [Buypass](https://www.buypass.com/products/tls-ssl-certificates/go-ssl)
- [SSL.com](https://www.ssl.com/guide/ssl-tls-certificate-issuance-and-revocation-with-acme/)
- [`step-ca`](https://smallstep.com/docs/step-ca/index.html)

カスタムACMEサーバーを使用するようにGitLabを設定するには:

1. `/etc/gitlab/gitlab.rb`を編集し、ACMEエンドポイントを設定します:

   ```ruby
   external_url 'https://example.com'
   letsencrypt['acme_staging_endpoint'] = 'https://ca.internal/acme/acme/directory'
   letsencrypt['acme_production_endpoint'] = 'https://ca.internal/acme/acme/directory'
   ```

   カスタムACMEサーバーが提供する場合は、ステージングエンドポイントも使用します。ステージングエンドポイントを最初にチェックすると、ACME本番環境にリクエストを送信する前に、ACME設定が正しいことを確認できます。これにより、設定の作業中にACMEレート制限を回避できます。

   デフォルト値は次のとおりです:

   ```plaintext
   https://acme-staging-v02.api.letsencrypt.org/directory
   https://acme-v02.api.letsencrypt.org/directory
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 証明書に代替ドメインを追加する {#add-alternative-domains-to-the-certificate}

デフォルトでは、GitLabは、`external_url`で指定されたホスト名に証明書の共通名（CN）とサブジェクト代替名（SAN）を設定します。

追加の代替ドメイン（またはサブジェクト代替名）をLet's Encrypt証明書に追加できます。これは、[バンドルされたNGINX](../nginx.md)を[他のバックエンドアプリケーションのリバースプロキシ](../nginx.md#insert-custom-settings-into-the-nginx-configuration)として使用する場合に役立ちます。

代替ドメインのDNSレコードは、GitLabインスタンスを指している必要があります。`external_url`ホスト名は、サブジェクト代替名のリストに含まれている必要があります。

Let's Encrypt証明書に代替ドメインを追加するには:

1. `/etc/gitlab/gitlab.rb`を編集して、代替ドメインを追加します:

   ```ruby
   # Separate multiple domains with commas
   letsencrypt['alt_names'] = ['gitlab.example.com', 'another-application.example.com']
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

メインGitLabアプリケーション用に生成された結果のLet's Encrypt証明書には、指定された代替ドメインが含まれます。生成されたファイルは次の場所にあります:

- `/etc/gitlab/ssl/gitlab.example.com.key`キー。
- 証明書をフェッチするために`/etc/gitlab/ssl/gitlab.example.com.crt`。

## HTTPSを手動で設定する {#configure-https-manually}

{{< alert type="warning" >}}

NGINX設定は、[HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)を使用して、今後365日間、セキュアな接続でのみGitLabインスタンスと通信するようにブラウザとクライアントに指示します。その他の設定オプションについては、[HTTP Strict Transport Securityの設定](#configure-the-http-strict-transport-security-hsts)を参照してください。HTTPSを有効にする場合は、少なくとも今後24か月間はインスタンスへの安全な接続を提供する必要があります。

{{< /alert >}}

HTTPSを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 
   1. `external_url`を自分のドメインに設定します。URLの`https`に注意してください:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   1. Let's Encryptのインテグレーションを無効にします:

      ```ruby
      letsencrypt['enable'] = false
      ```

      GitLabは、再設定するたびにLet's Encrypt証明書を更新しようとします。手動で作成した独自の証明書を使用する場合は、Let's Encryptのインテグレーションを無効にする必要があります。そうしないと、自動更新により証明書が上書きされる可能性があります。

1. `/etc/gitlab/ssl`ディレクトリを作成し、キーと証明書をそこにコピーします:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp gitlab.example.com.key gitlab.example.com.crt /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/gitlab.example.com.crt
   sudo chmod 600 /etc/gitlab/ssl/gitlab.example.com.key
   ```

   この例では、ホスト名は`gitlab.example.com`であるため、Linuxパッケージインストールでは、それぞれ`/etc/gitlab/ssl/gitlab.example.com.key`および`/etc/gitlab/ssl/gitlab.example.com.crt`という秘密キーと公開証明書ファイルが検索されます。必要に応じて、[別の場所と証明書名を使用する](#change-the-default-ssl-certificate-location)ことができます。

   クライアントが接続するときにSSLエラーを防ぐには、完全な証明書チェーンを正しい順序で使用する必要があります。最初にサーバー証明書、次いで全ての中間証明書、最後にルート認証局です。

1. オプション。`certificate.key`ファイルがパスワードで保護されている場合、GitLabを再設定するときに、NGINXはパスワードを要求しません。その場合、Linuxパッケージインストールはエラーメッセージなしでひそかに失敗します。

   キーファイルのパスワードを指定するには、パスワードをテキストファイル（たとえば、`/etc/gitlab/ssl/key_file_password.txt`）に保存し、次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   nginx['ssl_password_file'] = '/etc/gitlab/ssl/key_file_password.txt'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。ファイアウォールを使用している場合は、受信HTTPSトラフィックを許可するためにポート443を開く必要がある場合があります:

   ```shell
   # UFW example (Debian, Ubuntu)
   sudo ufw allow https

   # lokkit example (RedHat, CentOS 6)
   sudo lokkit -s https

   # firewall-cmd (RedHat, Centos 7)
   sudo firewall-cmd --permanent --add-service=https
   sudo systemctl reload firewalld
   ```

既存の証明書を更新する場合は、[別のプロセス](#update-the-ssl-certificates)に従ってください。

### `HTTP`リクエストを`HTTPS`にリダイレクトする {#redirect-http-requests-to-https}

デフォルトでは、`external_url`が`https`で始まるexternal_urlを指定すると、NGINXはポート80で暗号化されていないHTTPトラフィックをリッスンしなくなります。すべてのHTTPトラフィックをHTTPSにリダイレクトするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['redirect_http_to_https'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

この動作は、[Let's Encryptのインテグレーション](#enable-the-lets-encrypt-integration)を使用すると、デフォルトで有効になります。

{{< /alert >}}

### デフォルトのHTTPSポートを変更する {#change-the-default-https-port}

デフォルト（443）以外のHTTPSポートを使用する必要がある場合は、`external_url`の一部として指定します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   external_url "https://gitlab.example.com:2443"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### デフォルトのSSL証明書の場所を変更する {#change-the-default-ssl-certificate-location}

ホスト名が`gitlab.example.com`の場合、Linuxパッケージインストールでは、デフォルトで`/etc/gitlab/ssl/gitlab.example.com.key`という秘密キーと`/etc/gitlab/ssl/gitlab.example.com.crt`という公開証明書が検索されます。

SSL証明書の別の場所を設定するには:

1. ディレクトリを作成し、適切な権限を付与し、`.crt`ファイルと`.key`ファイルをディレクトリに配置します:

   ```shell
   sudo mkdir -p /mnt/gitlab/ssl
   sudo chmod 755 /mnt/gitlab/ssl
   sudo cp gitlab.key gitlab.crt /mnt/gitlab/ssl/
   ```

   クライアントが接続するときにSSLエラーを防ぐには、完全な証明書チェーンを正しい順序で使用する必要があります。最初にサーバー証明書、次いで全ての中間証明書、最後にルート認証局です。

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['ssl_certificate'] = "/mnt/gitlab/ssl/gitlab.crt"
   nginx['ssl_certificate_key'] = "/mnt/gitlab/ssl/gitlab.key"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### SSL証明書を更新する {#update-the-ssl-certificates}

SSL証明書の内容が更新されたが、`/etc/gitlab/gitlab.rb`に設定の変更が加えられていない場合、GitLabを再設定してもNGINXには影響しません。代わりに、NGINXに[既存の設定と新しい証明書を正常に読み込む](http://nginx.org/en/docs/control.html)ように指示する必要があります:

```shell
sudo gitlab-ctl hup nginx
sudo gitlab-ctl hup registry
```

## リバースプロキシまたはロードバランサーSSL終端を設定する {#configure-a-reverse-proxy-or-load-balancer-ssl-termination}

デフォルトでは、Linuxパッケージインストールは、`external_url`に`https://`が含まれているかどうかを自動検出し、SSL終端用にNGINXを設定します。ただし、リバースプロキシまたは外部ロードバランサーの背後で実行するようにGitLabを設定する場合、一部の環境では、GitLabアプリケーションの外部でSSLを終了することが必要になる場合があります。

バンドルされたNGINXがSSL終端を処理しないようにするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['listen_port'] = 80
   nginx['listen_https'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

外部ロードバランサーは、`200`ステータスコードを返すGitLabエンドポイントへのアクセスが必要になる場合があります（ログインが必要なインストールの場合は、ルートページがログインページへの`302`リダイレクトを返します）。その場合は、[ヘルスチェックエンドポイント](https://docs.gitlab.com/administration/monitoring/health_check/)を利用することをお勧めします。

コンテナレジストリ、GitLab Pages、Mattermostなどの他のバンドルされたコンポーネントは、プロキシされたSSLに同様の戦略を使用します。特定のコンポーネントの`*_external_url`を`https://`で設定し、`nginx[...]`設定にコンポーネント名をプレフィックスとして付加します。たとえば、GitLabコンテナレジストリの設定には、`registry_`というプレフィックスが付きます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   registry_external_url 'https://registry.example.com'

   registry_nginx['listen_port'] = 80
   registry_nginx['listen_https'] = false
   ```

   同じ形式をGitLab Pages（`pages_`プレフィックス）およびMattermost（`mattermost_`プレフィックス）に使用できます。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。特定ヘッダー（たとえば、`Host`、`X-Forwarded-Ssl`、`X-Forwarded-For`、`X-Forwarded-Port`）をGitLab（およびMattermostを使用する場合はMattermost）に転送するように、リバースプロキシまたはロードバランサーを設定する必要がある場合があります。このステップを忘れると、「422 Unprocessable Entity」または「CSRFトークンの信頼性を確認できません」のような不適切なリダイレクトまたはエラーが表示される場合があります。

一部のクラウドプロバイダーサービス（AWS Certificate Manager（ACM）など）では、証明書のダウンロードが許可されていません。これにより、それらがGitLabインスタンスで終了されるのを防ぎます。そのようなクラウドプロバイダーサービスとGitLabの間にSSLが必要な場合は、別の証明書をGitLabインスタンスで使用する必要があります。

## カスタムSSL暗号を使用する {#use-custom-ssl-ciphers}

デフォルトでは、Linuxパッケージは、<https://gitlab.com>でのテストと、GitLabコミュニティが提供するさまざまなベストプラクティスの組み合わせである[SSL暗号を使用](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/0482fb343a4434ba3a2523a7fb576d2bbb2a3f5f/files/gitlab-cookbooks/gitlab/attributes/default.rb#L876)します。

SSL暗号を変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['ssl_ciphers'] = "CIPHER:CIPHER1"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`ssl_dhparam`ディレクティブを有効にするには:

1. `dhparams.pem`を生成します:

   ```shell
   openssl dhparam -out /etc/gitlab/ssl/dhparams.pem 2048
   ```

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparams.pem"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## HTTP/2プロトコルを設定する {#configure-the-http2-protocol}

デフォルトでは、GitLabインスタンスがHTTPS経由で到達可能であることを指定すると、[HTTP/2プロトコル](https://www.rfc-editor.org/rfc/rfc7540)も有効になります。

Linuxパッケージは、HTTP/2プロトコルと互換性のある必要なSSL暗号を設定します。

独自の[カスタムSSL暗号](#use-custom-ssl-ciphers)を指定し、暗号が[HTTP/2暗号ブラックリスト](https://www.rfc-editor.org/rfc/rfc7540#appendix-A)に含まれている場合、GitLabインスタンスに到達しようとすると、ブラウザに`INADEQUATE_SECURITY`エラーが表示されます。その場合は、問題のある暗号を暗号リストから削除することを検討してください。暗号の変更は、非常に具体的なカスタムセットアップがある場合にのみ必要です。

HTTP/2プロトコルを有効にする理由の詳細については、[NGINX HTTP/2ホワイトペーパー](https://assets.wp.nginx.com/wp-content/uploads/2015/09/NGINX_HTTP2_White_Paper_v4.pdf?_ga=1.127086286.212780517.1454411744)をご覧ください。

暗号の変更がオプションでない場合は、HTTP/2サポートを無効にできます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['http2_enabled'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

HTTP/2設定は、メインのGitLabアプリケーションでのみ機能し、GitLab Pages、コンテナレジストリ、Mattermostなどの他のサービスでは機能しません。

{{< /alert >}}

## 双方向SSLクライアント認証を有効にする {#enable-2-way-ssl-client-authentication}

信頼できる証明書でWebクライアントに認証を要求するには、双方向SSLを有効にします:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['ssl_verify_client'] = "on"
   nginx['ssl_client_certificate'] = "/etc/pki/tls/certs/root-certs.pem"
   ```

1. オプション。クライアントに有効な証明書がないと判断する前に、証明書チェーンでNGINXがどれだけ深く検証するかを設定できます（デフォルトは`1`です）。`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['ssl_verify_depth'] = "2"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## HTTP Strict Transport Security（HSTS）を設定する {#configure-the-http-strict-transport-security-hsts}

{{< alert type="note" >}}

HSTS設定は、メインのGitLabアプリケーションでのみ機能し、GitLab Pages、コンテナレジストリ、Mattermostなどの他のサービスでは機能しません。

{{< /alert >}}

HTTP Strict Transport Security（HSTS）はデフォルトで有効になっており、HTTPSを使用してのみWebサイトにアクセスする必要があることをブラウザに通知します。ブラウザがGitLabインスタンスに1回でもアクセスすると、ユーザーが明示的にプレーンHTTP URL（`http://`）を入力している場合でも、安全でない接続を試行しないことを記憶します。プレーンHTTP URLは、ブラウザによって自動的に`https://`バリアントにリダイレクトされます。

デフォルトでは、`max_age`は2年間設定されており、これはブラウザがHTTPS経由でのみ接続することを記憶する期間です。

最大有効期限値を変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['hsts_max_age'] = 63072000
   nginx['hsts_include_subdomains'] = false
   ```

   `max_age`を`0`に設定すると、HSTSが無効になります。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

HSTSとNGINXの詳細については、<https://blog.nginx.org/blog/http-strict-transport-security-hsts-and-nginx>を参照してください。

## カスタム公開証明書をインストールする {#install-custom-public-certificates}

一部の環境は、さまざまなタスクのために外部リソースに接続し、GitLabはこれらの接続がHTTPSを使用できるようにし、自己署名証明書との接続をサポートします。GitLabには独自の認証局証明書バンドルがあり、個々のカスタム証明書を`/etc/gitlab/trusted-certs`ディレクトリに配置することで、証明書を追加できます。その後、バンドルに追加されます。それらは`openssl rehash`コマンドを使用して追加されます。これは、[単一の証明書](#using-a-custom-certificate-chain)でのみ機能します。

Linuxパッケージには、証明書の信頼性を確認するために使用される、信頼できるルート認証局の公式[Mozilla](https://wiki.mozilla.org/CA/Included_Certificates)コレクションが付属しています。

{{< alert type="note" >}}

自己署名証明書を使用するインストールの場合は、Linuxパッケージはこれらの証明書を管理する方法を提供します。この仕組みの技術的な詳細については、このページの下部にある[詳細](#details-on-how-gitlab-and-ssl-work)を参照してください。

{{< /alert >}}

カスタム公開証明書をインストールするには:

1. プライベートキー証明書から、**PEM**または**DER**でエンコードされた公開証明書を生成します。
1. 公開証明書ファイルのみを`/etc/gitlab/trusted-certs`ディレクトリにコピーします。マルチノード構成の場合は、すべてのノードに証明書をコピーしてください。
   - カスタム公開証明書を使用するようにGitLabを設定する場合、デフォルトでは、GitLabではGitLabのドメイン名に基づいた生で、拡張子が`.crt`の証明書が存在することを想定しています。たとえば、サーバーアドレスが`https://gitlab.example.com`の場合、証明書の名前は`gitlab.example.com.crt`にする必要があります。
   - GitLabがカスタム公開証明書を使用する外部リソースに接続する必要がある場合は、証明書を`/etc/gitlab/trusted-certs`ディレクトリに`.crt`拡張子で保存します。関連する外部リソースのドメイン名に基づいてファイルに名前を付ける必要はありませんが、一貫性のある命名規則を使用すると役立ちます。

   別のパスとファイル名を指定するには、[デフォルトのSSL証明書の場所を変更](#change-the-default-ssl-certificate-location)します。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### カスタム証明書チェーンの使用 {#using-a-custom-certificate-chain}

[既知の問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1425)により、カスタム証明書チェーンを使用している場合、サーバー、中間証明書、およびルート証明書は、`/etc/gitlab/trusted-certs`ディレクトリ内の個別のファイルに配置する**必要があります**。

これは、GitLab自体、またはGitLabが接続する必要がある外部リソースが、カスタム証明書チェーンを使用している場合の両方に適用されます。

たとえば、GitLab自体の場合、以下を使用できます:

- `/etc/gitlab/trusted-certs/example.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/example.gitlab.com_root.crt`

GitLabが接続する必要がある外部リソースの場合、以下を使用できます:

- `/etc/gitlab/trusted-certs/external-service.gitlab.com.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_intermediate.crt`
- `/etc/gitlab/trusted-certs/external-service.gitlab.com_root.crt`

## GitLabとSSLの連携に関する詳細 {#details-on-how-gitlab-and-ssl-work}

Linuxパッケージには、OpenSSL独自のライブラリが含まれており、コンパイルされたすべてのプログラム（Ruby、PostgreSQLなど）をこのライブラリにリンクします。このライブラリは、`/opt/gitlab/embedded/ssl/certs`の証明書を検索するようにコンパイルされています。

Linuxパッケージは、[openssl rehash](https://docs.openssl.org/3.1/man1/openssl-rehash/)ツールを使用して、`/etc/gitlab/trusted-certs/`に追加された証明書を`/opt/gitlab/embedded/ssl/certs`にシンボリックリンクすることにより、カスタム証明書を管理します。たとえば、`customcacert.pem`を`/etc/gitlab/trusted-certs/`に追加するとします:

```shell
$ sudo ls -al /opt/gitlab/embedded/ssl/certs

total 272
drwxr-xr-x 2 root root   4096 Jul 12 04:19 .
drwxr-xr-x 4 root root   4096 Jul  6 04:00 ..
lrwxrwxrwx 1 root root     42 Jul 12 04:19 7f279c95.0 -> /etc/gitlab/trusted-certs/customcacert.pem
-rw-r--r-- 1 root root 263781 Jul  5 17:52 cacert.pem
-rw-r--r-- 1 root root    147 Feb  6 20:48 README
```

ここでは、証明書のフィンガープリントが`7f279c95`であることがわかります。これは、カスタム証明書にリンクしています。

HTTPSリクエストを行うとどうなりますか？簡単なRubyプログラムを見てみましょう:

```ruby
#!/opt/gitlab/embedded/bin/ruby
require 'openssl'
require 'net/http'

Net::HTTP.get(URI('https://www.google.com'))
```

これが舞台裏で起こることです:

1. `require 'openssl'`行により、インタープリターは`/opt/gitlab/embedded/lib/ruby/2.3.0/x86_64-linux/openssl.so`を読み込みます。
1. 次に、`Net::HTTP`呼び出しは、`/opt/gitlab/embedded/ssl/certs/cacert.pem`のデフォルトの証明書バンドルを読み込もうとします。
1. SSLネゴシエーションが発生します。
1. サーバーはSSL証明書を送信します。
1. 送信された証明書がバンドルでカバーされている場合、SSLは正常に終了します。
1. そうでない場合、OpenSSLは、定義済みの証明書ディレクトリ内でフィンガープリントに一致するファイルを検索することにより、他の証明書を検証する場合があります。たとえば、証明書のフィンガープリントが`7f279c95`の場合、OpenSSLは`/opt/gitlab/embedded/ssl/certs/7f279c95.0`の読み取りを試みます。

OpenSSLライブラリは、`SSL_CERT_FILE`および`SSL_CERT_DIR`環境変数の定義をサポートしています。前者は読み込むデフォルトの証明書バンドルを定義し、後者はより多くの証明書を検索するディレクトリを定義します。`trusted-certs`ディレクトリに証明書を追加した場合、これらの変数は必要ありません。ただし、何らかの理由でそれらをセットする必要がある場合は、[環境変数として定義](../environment-variables.md)できます。例: 

```ruby
gitlab_rails['env'] = {"SSL_CERT_FILE" => "/usr/lib/ssl/private/customcacert.pem"}
```

## トラブルシューティング {#troubleshooting}

[SSLのトラブルシューティングガイド](ssl_troubleshooting.md)を参照してください。
