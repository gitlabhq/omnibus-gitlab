---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NGINX設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabインスタンス向けにNGINXを設定する管理者およびDevOpsエンジニア向けに、設定情報を提供します。これには、バンドルされたNGINX（Linuxパッケージ）、Helmチャート、またはカスタム設定に固有のパフォーマンスとセキュリティを最適化するための重要な手順が含まれています。

## サービス固有のNGINX設定 {#service-specific-nginx-settings}

異なるサービス向けにNGINX設定を設定するには、`gitlab.rb`ファイルを編集します。

> [!warning]
> 不正確または互換性のない設定によって、サービスが利用できなくなる可能性があります。

GitLab Railsアプリケーションを設定するには、`nginx['<setting>']`キーを使用します。GitLabは、`pages_nginx`、`mattermost_nginx`、`registry_nginx`のような他のサービスにも同様のキーを提供しています。`nginx`の設定は、これらの`<service_nginx>`設定にも利用でき、GitLab NGINXとデフォルトで同じ値を共有します。

Mattermostのような独立したサービスでNGINXを操作するには、`nginx['enable'] = false`の代わりに`gitlab_rails['enable'] = false`を使用します。詳細については、[Running GitLab Mattermost on its own server](https://docs.gitlab.com/integration/mattermost/#running-gitlab-mattermost-on-its-own-server)を参照してください。

`gitlab.rb`ファイルを変更する際は、各サービス向けにNGINX設定を個別に設定します。`nginx['foo']`を使用して指定された設定は、サービス固有のNGINX設定（`registry_nginx['foo']`や`mattermost_nginx['foo']`など）にはレプリケートされません。例えば、GitLab、Mattermost、およびレジストリ向けのHTTPからHTTPSへのリダイレクトを設定するには、以下の設定を`gitlab.rb`に追加します:

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
mattermost_nginx['redirect_http_to_https'] = true
```

## HTTPSを有効にする {#enable-https}

デフォルトでは、LinuxパッケージのインストールはHTTPSを使用しません。`gitlab.example.com`のHTTPSを有効にするには:

- [Freeの自動HTTPSにLet's Encryptを使用する](ssl/_index.md#enable-the-lets-encrypt-integration)。
- [独自の証明書を使用してHTTPSを手動で設定する](ssl/_index.md#configure-https-manually)。

プロキシ、ロードバランサー、またはその他の外部デバイスを使用してGitLabホスト名向けのSSLを終端する場合は、[External, proxy, andロードバランサーSSL termination](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)を参照してください。

## デフォルトのプロキシヘッダーを変更する {#change-the-default-proxy-headers}

デフォルトでは、`external_url`を指定すると、Linuxパッケージのインストールによって、ほとんどの環境に適したNGINXプロキシヘッダーが設定されます。

例えば、`external_url`で`https`スキーマを指定した場合、Linuxパッケージのインストールは以下を設定します:

```plaintext
"X-Forwarded-Proto" => "https",
"X-Forwarded-Ssl" => "on"
```

GitLab インスタンスがリバースプロキシの背後にあるなど、より複雑なセットアップになっている場合は、次のようなエラーを回避するためにプロキシヘッダーを調整する必要があるかもしれません:

- `The change you wanted was rejected`
- `Can't verify CSRF token authenticity Completed 422 Unprocessable`

デフォルトのヘッダーをオーバーライドするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['proxy_set_headers'] = {
     "X-Forwarded-Proto" => "http",
     "CUSTOM_HEADER" => "VALUE"
   }
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

NGINXがサポートする任意のヘッダーを指定できます。

## GitLabの信頼済みプロキシとNGINX `real_ip`モジュールを設定する {#configure-gitlab-trusted-proxies-and-nginx-real_ip-module}

デフォルトでは、NGINXとGitLabは接続されたクライアントのIPアドレスをログに記録します。

GitLabがリバースプロキシの背後にある場合、プロキシのIPアドレスがクライアントアドレスとして表示されないようにしたい場合があります。

NGINXが異なるアドレスを使用するように設定するには、リバースプロキシを`real_ip_trusted_addresses`リストに追加します:

```ruby
# Each address is added to the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# Other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

これらのオプションについては、[NGINX `realip`モジュールドキュメント](http://nginx.org/en/docs/http/ngx_http_realip_module.html)を参照してください。

デフォルトでは、Linuxパッケージのインストールは`real_ip_trusted_addresses`内のIPアドレスをGitLabの信頼済みプロキシとして使用します。信頼済みプロキシの設定により、ユーザーがそれらのIPアドレスからサインインしたとしてリストされるのを防ぎます。

ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

## PROXYプロトコルを設定する {#configure-the-proxy-protocol}

GitLabの前にHAProxyのようなプロキシを[PROXYプロトコル](https://www.haproxy.org/download/3.1/doc/proxy-protocol.txt)とともに使用するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

この設定を有効にすると、NGINXはこれらのリスナーでPROXYプロトコルトラフィックのみを受け入れます。モニタリングチェックなど、他の環境も調整してください。

## 非バンドル型Webサーバーを使用する {#use-a-non-bundled-web-server}

> [!note]
> GitLabは、非バンドル型Webサーバーのセットアップに関する情報のみを提供します。非バンドル型コンポーネントのトラブルシューティングは、[サポートのスコープ外](https://about.gitlab.com/support/statement-of-support/#out-of-scope-for-all-self-managed-and-saas-users)と見なされます。非バンドル型Webサーバーの使用に関してご質問や問題がある場合は、非バンドル型Webサーバーのドキュメントを参照してください。

デフォルトでは、LinuxパッケージはバンドルされたNGINXとともにGitLabをインストールします。Linuxパッケージのインストールは、`gitlab-www`ユーザー（同名のグループに属する）を介したWebサーバーアクセスを許可します。外部WebサーバーがGitLabにアクセスできるようにするには、外部Webサーバーユーザーを`gitlab-www`グループに追加します。

Apacheまたは既存のNGINXインストールなどの別のWebサーバーを使用するには:

1. バンドルされたNGINXを無効にする:

   `/etc/gitlab/gitlab.rb`で次を設定します:

   ```ruby
   nginx['enable'] = false
   ```

1. 非バンドル型Webサーバーユーザー名を設定します:

   Linuxパッケージのインストールには、外部Webサーバーユーザーのデフォルト設定がありません。設定でそれを指定する必要があります。例: 

   - Debian/Ubuntu: ApacheとNGINXの両方でデフォルトユーザーは`www-data`です。
   - RHEL/CentOS: NGINXユーザーは`nginx`です。

   Webサーバーユーザーが作成されるように、続行する前にApacheまたはNGINXをインストールしてください。そうしないと、再設定中にLinuxパッケージのインストールが失敗します。

   Webサーバーユーザーが`www-data`の場合、`/etc/gitlab/gitlab.rb`で次を設定します:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   この設定は配列なので、`gitlab-www`グループに追加する複数のユーザーを指定できます。

   変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

   SELinuxを使用しており、Webサーバーが制限されたSELinuxプロファイルで実行されている場合は、[SELinux権限を設定する](https://gitlab.com/gitlab-org/gitlab-recipes/-/blob/master/web-server/apache/README.md#selinux-modifications)必要があるかもしれません。

   外部Webサーバーが使用するすべてのディレクトリに対して、Webサーバーユーザーが正しい権限を持っていることを確認してください。そうしないと、`failed (XX: Permission denied) while reading upstream`エラーが発生する可能性があります。

1. 非バンドル型Webサーバーを信頼済みプロキシのリストに追加します:

   Linuxパッケージのインストールは通常、信頼済みプロキシのリストを、バンドルされたNGINX向けの`real_ip`モジュール内の設定にデフォルトで設定します。

   非バンドル型Webサーバーの場合、リストを直接設定します。WebサーバーがGitLabと同じマシン上にない場合は、そのWebサーバーのIPアドレスを含めます。そうしないと、ユーザーはWebサーバーのIPアドレスからサインインしたように見えます。

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. オプション。Apacheを使用する場合は、GitLab Workhorseの設定を設定します:

   ApacheはUNIXソケットに接続できず、TCPポートに接続する必要があります。GitLab WorkhorseがTCP（デフォルトポート8181）でリッスンできるようにするには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

1. 正しいWebサーバー設定をダウンロードします:

   [GitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/support/nginx)に移動し、必要な設定をダウンロードします。GitLabをSSLの有無にかかわらず提供するための正しい設定ファイルを選択します。変更する必要があるかもしれません:

   - `YOUR_SERVER_FQDN`の値をFQDNに変更します。
   - SSLを使用する場合は、SSLキーの場所。
   - ログファイルの場所。

## NGINX設定オプション {#nginx-configuration-options}

GitLabは、特定のニーズに合わせてNGINXの動作をカスタマイズするためのさまざまな設定オプションを提供します。これらの参照項目を使用して、NGINXのセットアップを微調整し、GitLabのパフォーマンスとセキュリティを最適化します。

### NGINXのリスナーアドレスを設定する {#set-the-nginx-listen-addresses}

デフォルトでは、NGINXはすべてのローカルIPv4アドレスで受信接続を受け入れます。

アドレスのリストを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Listen on all IPv4 and IPv6 addresses
   nginx['listen_addresses'] = ["0.0.0.0", "[::]"]
   registry_nginx['listen_addresses'] = ['*', '[::]']
   mattermost_nginx['listen_addresses'] = ['*', '[::]']
   pages_nginx['listen_addresses'] = ['*', '[::]']
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

### NGINXのリスナーポートを設定する {#set-the-nginx-listen-port}

デフォルトでは、NGINXは`external_url`で指定されたポートでリッスンするか、標準ポート（HTTPの場合は80、HTTPSの場合は443）を使用します。GitLabをリバースプロキシの背後で実行している場合、リッスンポートをオーバーライドしたい場合があります。

リッスンポートを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します。例えば、ポート8081を使用するには:

   ```ruby
   nginx['listen_port'] = 8081
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

### NGINXのログレベルを変更する {#change-the-verbosity-level-of-nginx-logs}

デフォルトでは、NGINXは`error`の冗長レベルでログを記録します。

ログレベルを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['error_log_level'] = "debug"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

有効なログレベルの値については、['error_log' directive](https://nginx.org/en/docs/ngx_core_module.html#error_log)を参照してください。

### Referrer-Policyヘッダーを設定する {#set-the-referrer-policy-header}

デフォルトでは、GitLabはすべてのレスポンスで`Referrer-Policy`ヘッダーを`strict-origin-when-cross-origin`に設定します。この設定により、クライアントは以下を実行します:

- 同一オリジンのリクエストに対して、完全なURLをリファラーとして送信します。
- クロスオリジンのリクエストに対しては、オリジンのみを送信します。

このヘッダーを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['referrer_policy'] = 'same-origin'
   ```

   このヘッダーを無効にして、クライアントのデフォルト設定を使用するには:

   ```ruby
   nginx['referrer_policy'] = false
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

> [!warning]
> これを`origin`または`no-referrer`に設定すると、完全なリファラーURLを必要とするGitLab機能が破損します。

詳細については、[Referrer Policy仕様](https://www.w3.org/TR/referrer-policy/)を参照してください。

### Gzip圧縮を無効にする {#disable-gzip-compression}

デフォルトでは、GitLabは10240バイトを超えるテキストデータに対してGzip圧縮を有効にします。Gzip圧縮を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['gzip_enabled'] = false
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

> [!note]
> `gzip`設定は、主要なGitLabアプリケーションにのみ適用され、他のサービスには適用されません。

### プロキシリクエストのバッファリングを無効にする {#disable-proxy-request-buffering}

特定の場所に対するリクエストのバッファリングを無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。
1. NGINX設定を正常にリロードします:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

`hup`コマンドの詳細については、[NGINXドキュメント](https://nginx.org/en/docs/control.html)を参照してください。

### `robots.txt`を設定する {#configure-robotstxt}

独自のインスタンス向けカスタム[`robots.txt`](https://www.robotstxt.org/robotstxt.html)ファイルを設定するには:

1. カスタム`robots.txt`ファイルを作成し、そのパスをメモします。
1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

   `/path/to/custom/robots.txt`をカスタム`robots.txt`ファイルへの実際のパスに置き換えます。

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

この設定により、カスタム`robots.txt`ファイルを提供するための[カスタムNGINX設定](#insert-custom-nginx-settings-into-the-gitlab-server-block)が追加されます。

### GitLabサーバーブロックにカスタムNGINX設定を挿入する {#insert-custom-nginx-settings-into-the-gitlab-server-block}

GitLab向けのNGINX `server`ブロックにカスタム設定を追加するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Example: block raw file downloads from a specific repository
   nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

これにより、定義された文字列が`/var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf`内の`server`ブロックの末尾に挿入されます。

> [!warning]
> カスタム設定は、`gitlab.rb`ファイル内の他の場所で定義されている設定と競合する可能性があります。

#### デフォルトサーバーを無効にする {#disable-the-default-server}

デフォルトでは、バンドルされたNGINXはGitLabサーバーブロックの`listen`ディレクティブに`default_server`を含めます。この設定により、NGINXは、他のサーバーブロックと一致しないすべてのリクエストに対して、このサーバーブロックをデフォルトとして使用します。

独自のカスタムサーバーブロックを`default_server`（例えば、`nginx['custom_gitlab_server_config']`を使用する場合）で追加する必要がある場合は、GitLab設定でデフォルトサーバーを無効にする必要があります:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['default_server_enabled'] = false
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

このアプローチにより、`listen`ディレクティブから`default_server`が削除され、独自のデフォルトサーバーブロックを定義できるようになります。

#### 注 {#notes}

- 新しいロケーションを追加する場合は、以下を含める必要があるかもしれません:

  ```conf
  proxy_cache off;
  proxy_http_version 1.1;
  proxy_pass http://gitlab-workhorse;
  ```

  これらがないと、サブロケーションは404エラーを返す可能性があります。

- ルート`/`ロケーションまたは`/assets`ロケーションは、すでに`gitlab-rails.conf`に存在するため、追加できません。

### カスタム設定をNGINX設定に挿入する {#insert-custom-settings-into-the-nginx-configuration}

カスタム設定をNGINX設定に追加するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Example: include a directory to scan for additional config files
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/sites-enabled/*.conf;"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

これにより、定義された文字列が`/var/opt/gitlab/nginx/conf/nginx.conf`内の`http`ブロックの末尾に挿入されます。

例えば、カスタムサーバーブロックを作成して有効にするには:

1. `/etc/gitlab/nginx/sites-available`ディレクトリにカスタムサーバーブロックを作成します。
1. `/etc/gitlab/nginx/sites-enabled`ディレクトリが存在しない場合は作成します。
1. カスタムサーバーブロックを有効にするには、シンボリックリンクを作成します:

   ```shell
   sudo ln -s /etc/gitlab/nginx/sites-available/example.conf /etc/gitlab/nginx/sites-enabled/example.conf
   ```

1. NGINX設定をリロードします:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

   または、NGINXを再起動できます:

   ```shell
   sudo gitlab-ctl restart nginx
   ```

生成されたLet's Encrypt SSL証明書に、サーバーブロックのドメインを[代替名として](ssl/_index.md#add-alternative-domains-to-the-certificate)追加できます。

`/etc/gitlab/`ディレクトリ内のカスタムNGINX設定は、アップグレード中および`sudo gitlab-ctl backup-etc`が手動で実行されたときに`/etc/gitlab/config_backup/`にバックアップされます。

### カスタムエラーページを設定する {#configure-custom-error-pages}

デフォルトのGitLabエラーページのテキストを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['custom_error_pages'] = {
    '404' => {
      'title' => 'Example title',
      'header' => 'Example header',
      'message' => 'Example message'
    }
   }
   ```

   この例では、デフォルトの404エラーページを変更します。この形式は、404または502などの有効なHTTPエラーコードすべてに使用できます。

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

404エラーページの結果は次のようになります:

![custom 404 error page](img/error_page_example.png)

### 既存のPassengerとNGINXのインストールを使用する {#use-an-existing-passenger-and-nginx-installation}

既存のPassengerとNGINXのインストールでGitLabをホストしながら、更新とインストールにLinuxパッケージを使用できます。

NGINXを無効にすると、Linuxパッケージのインストールに含まれるMattermostなどの他のサービスには、`nginx.conf`に手動で追加しない限りアクセスできません。

#### 設定 {#configuration}

既存のPassengerとNGINXのインストールでGitLabをセットアップするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Define the external url
   external_url 'http://git.example.com'

   # Disable the built-in NGINX
   nginx['enable'] = false

   # Disable the built-in Puma
   puma['enable'] = false

   # Set the internal API URL
   gitlab_rails['internal_api_url'] = 'http://git.example.com'

   # Define the web server process user (ubuntu/nginx)
   web_server['external_users'] = ['www-data']
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

#### 仮想ホスト（サーバーブロック）を設定する {#configure-the-virtual-host-server-block}

カスタムのPassenger/NGINXインストールで:

1. 以下の内容で新しいサイト設定ファイルを作成します:

   ```plaintext
   upstream gitlab-workhorse {
    server unix://var/opt/gitlab/gitlab-workhorse/sockets/socket fail_timeout=0;
   }

   server {
    listen *:80;
    server_name git.example.com;
    server_tokens off;
    root /opt/gitlab/embedded/service/gitlab-rails/public;

    client_max_body_size 250m;

    access_log  /var/log/gitlab/nginx/gitlab_access.log;
    error_log   /var/log/gitlab/nginx/gitlab_error.log;

    # Ensure Passenger uses the bundled Ruby version
    passenger_ruby /opt/gitlab/embedded/bin/ruby;

    # Correct the $PATH variable to included packaged executables
    passenger_env_var PATH "/opt/gitlab/bin:/opt/gitlab/embedded/bin:/usr/local/bin:/usr/bin:/bin";

    # Make sure Passenger runs as the correct user and group to
    # prevent permission issues
    passenger_user git;
    passenger_group git;

    # Enable Passenger & keep at least one instance running at all times
    passenger_enabled on;
    passenger_min_instances 1;

    location ~ ^/[\w\.-]+/[\w\.-]+/(info/refs|git-upload-pack|git-receive-pack)$ {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/[\w\.-]+/[\w\.-]+/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    location ~ ^/api/v3/projects/.*/repository/archive {
      # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
      error_page 418 = @gitlab-workhorse;
      return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ ^/[\w\.-]+/[\w\.-]+/builds/download {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /ci/api/v1/builds/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }

    # Build artifacts should be submitted to this location
    location ~ /api/v4/jobs/[0-9]+/artifacts {
        client_max_body_size 0;
        # 'Error' 418 is a hack to re-use the @gitlab-workhorse block
        error_page 418 = @gitlab-workhorse;
        return 418;
    }


    # For protocol upgrades from HTTP/1.0 to HTTP/1.1 we need to provide Host header if its missing
    if ($http_host = "") {
    # use one of values defined in server_name
      set $http_host_with_default "git.example.com";
    }

    if ($http_host != "") {
      set $http_host_with_default $http_host;
    }

    location @gitlab-workhorse {

      ## https://github.com/gitlabhq/gitlabhq/issues/694
      ## Some requests take more than 30 seconds.
      proxy_read_timeout      3600;
      proxy_connect_timeout   300;
      proxy_redirect          off;

      # Do not buffer Git HTTP responses
      proxy_buffering off;

      proxy_set_header    Host                $http_host_with_default;
      proxy_set_header    X-Real-IP           $remote_addr;
      proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto   $scheme;

      proxy_http_version 1.1;
      proxy_pass http://gitlab-workhorse;

      ## The following settings only work with NGINX 1.7.11 or newer
      #
      ## Pass chunked request bodies to gitlab-workhorse as-is
      # proxy_request_buffering off;
      # proxy_http_version 1.1;
    }

    ## Enable gzip compression as per rails guide:
    ## http://guides.rubyonrails.org/asset_pipeline.html#gzip-compression
    ## WARNING: If you are using relative urls remove the block below
    ## See config/application.rb under "Relative url support" for the list of
    ## other files that need to be changed for relative url support
    location ~ ^/(assets)/ {
      root /opt/gitlab/embedded/service/gitlab-rails/public;
      gzip_static on; # to serve pre-gzipped version
      expires max;
      add_header Cache-Control public;
    }

    error_page 502 /502.html;
   }
   ```

   `git.example.com`をサーバーURLに置き換えます。

403 Forbiddenエラーが発生した場合は、`/etc/nginx/nginx.conf`でPassengerが有効になっていることを確認してください:

1. この行のコメントを解除します:

   ```plaintext
   # include /etc/nginx/passenger.conf;
   ```

1. NGINX設定をリロードします:

   ```shell
   sudo service nginx reload
   ```

### NGINXステータスモニタリングを設定する {#configure-nginx-status-monitoring}

デフォルトでは、GitLabはNGINXサーバーのステータスをモニタリングするために、`127.0.0.1:8060/nginx_status`にNGINXヘルスチェックエンドポイントを設定します。仮想ホストトラフィックステータス（VTS）モジュールが有効になっている場合（デフォルト）、このポートは`127.0.0.1:8060/metrics`でPrometheusメトリクスも提供します。

このエンドポイントには以下の情報が表示されます:

```plaintext
Active connections: 1
server accepts handled requests
18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- アクティブな接続: 合計のオープン接続。
- 3つの数値は以下を示します:
  - すべての受け入れられた接続。
  - すべての処理された接続。
  - 処理されたリクエストの総数。
- 読み取り: NGINXはリクエストヘッダーを読み取ります。
- 書き込み: NGINXはリクエストボディを読み取り、リクエストを処理し、またはクライアントに応答を書き込みます。
- 待機: キープアライブ接続。この数値は`keepalive_timeout`ディレクティブに依存します。

#### NGINXステータスオプションを設定する {#configure-nginx-status-options}

NGINXステータスオプションを設定するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   nginx['status'] = {
    "listen_addresses" => ["127.0.0.1"],
    "fqdn" => "dev.example.com",
    "options" => {
      "access_log" => "off", # Disable logs for stats
      "allow" => "127.0.0.1", # Only allow access from localhost
      "deny" => "all" # Deny access to anyone else
    }
   }
   ```

> [!note]
> VTSが有効になっている場合、オプションに`"stub_status" => "on"`を含めないでください。この設定はすべてのエンドポイントに適用され、`/metrics`がPrometheusメトリクスの代わりに基本的な`nginx_status`出力を返す原因となります。

   VTSを無効にし、基本的な`nginx_status`メトリクスのみを使用するには:

   ```ruby
   nginx['status']['vts_enable'] = false
   ```

   NGINXステータスエンドポイントを無効にするには:

   ```ruby
   nginx['status'] = {
    'enable' => false
   }
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)します。

#### VTSモジュールで高度なメトリクスを設定する {#configure-advanced-metrics-with-vts-module}

GitLabには、追加のパフォーマンスメトリクス（レイテンシーパーセンタイルを含む）を提供するNGINX VTS（仮想ホストトラフィックステータス）モジュールが含まれています。

ヒストグラムバケットでVTSモジュールを有効にする前に、以下の影響を考慮してください:

- メトリクスデータを格納するために、メモリ使用量が増加します。影響は仮想ホストの数とトラフィック量に応じてスケールします。
- 各リクエストでヒストグラムメトリクスを計算すると、少量のCPUが消費されます。
- これらのメトリクスをPrometheusで収集する場合、追加のストレージが必要です。

高トラフィックのインストールの場合、パフォーマンスが許容範囲内に収まることを確認するために、これらのメトリクスをモニタリングしてください。

高度なレイテンシーメトリクスを有効にするには:

1. 以下の設定を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   nginx['custom_gitlab_server_config'] = "vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;"
   ```

   または、カスタムNGINX設定ファイルを作成します:

   ```shell
   sudo mkdir -p /etc/gitlab/nginx/conf.d/
   sudo vim /etc/gitlab/nginx/conf.d/vts-custom.conf
   ```

1. ヒストグラムバケットとフィルタリングを有効にするには、これらの設定を追加します:

   ```nginx
   vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;
   vhost_traffic_status_filter_by_host on;
   vhost_traffic_status_filter on;
   vhost_traffic_status_filter_by_set_key $server_name server::*;
   ```

1. GitLabがカスタム設定を含むように設定するには、以下を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/conf.d/vts-custom.conf;"
   ```

1. NGINXを再設定して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart nginx
   ```

これらの設定を有効にした後、Prometheusクエリを使用してさまざまなレイテンシーメトリクスをモニタリングできます:

```plaintext
# Average response time
rate(nginx_vts_server_request_seconds_total[5m]) / rate(nginx_vts_server_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 latency
histogram_quantile(0.90, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(nginx_vts_server_request_duration_seconds_bucket[5m]))

# Average upstream response time
rate(nginx_vts_upstream_response_seconds_total[5m]) / rate(nginx_vts_upstream_requests_total{code=~"2xx|3xx|4xx|5xx"}[5m])

# P90 upstream latency
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))

# P99 upstream latency
histogram_quantile(0.99, rate(nginx_vts_upstream_response_duration_seconds_bucket[5m]))
```

GitLab Workhorse固有のメトリクスには、以下を使用できます:

```plaintext
# 90th percentile upstream latency for GitLab Workhorse
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket{upstream="gitlab-workhorse"}[5m]))

# Average upstream response time for GitLab Workhorse
rate(nginx_vts_upstream_response_seconds_total{upstream="gitlab-workhorse"}[5m]) /
rate(nginx_vts_upstream_requests_total{upstream="gitlab-workhorse",code=~"2xx|3xx|4xx|5xx"}[5m])
```

#### アップロードのユーザー権限を設定する {#configure-user-permissions-for-uploads}

ユーザーのアップロードにアクセスできるようにするには、NGINXユーザー（通常は`www-data`）を`gitlab-www`グループに追加します:

```shell
sudo usermod -aG gitlab-www www-data
```

### テンプレート {#templates}

設定ファイルは、[バンドルされたGitLab NGINX設定](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-rails.conf.erb)に似ていますが、以下の違いがあります:

- Pumaの代わりにPassenger設定が使用されます。
- HTTPSはデフォルトでは有効になっていませんが、有効にできます。

NGINX設定を変更した後:

- Debianベースのシステムの場合、NGINXを再起動します:

  ```shell
  sudo service nginx restart
  ```

- その他のシステムについては、NGINXを再起動するための正しいコマンドについて、オペレーティングシステムのドキュメントを参照してください。
