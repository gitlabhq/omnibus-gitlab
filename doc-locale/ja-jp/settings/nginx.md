---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NGINX設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabインストール用にNGINXを構成する管理者とDevOpsエンジニア向けの設定情報を提供します。バンドルされたNGINX（Linuxパッケージ）、Helm Chart、またはカスタム設定に固有のパフォーマンスとセキュリティを最適化するための重要な手順が含まれています。

## サービス固有のNGINX設定 {#service-specific-nginx-settings}

さまざまなサービスのNGINX設定を構成するには、`gitlab.rb`ファイルを編集します。

{{< alert type="warning" >}}

構成が正しくない場合、または互換性がない場合は、サービスが利用できなくなる可能性があります。

{{< /alert >}}

GitLab Railsアプリケーションの設定を構成するには、`nginx['<setting>']`キーを使用します。GitLabは、`pages_nginx`、`mattermost_nginx`、`registry_nginx`などの他のサービスに対して同様のキーを提供します。`nginx`の設定は、これらの`<service_nginx>`設定でも利用でき、GitLab NGINXと同じデフォルト値を共有します。

Mattermostのような分離されたサービスに対してNGINXを操作するには、`gitlab_rails['enable'] = false`の代わりに`nginx['enable'] = false`を使用します。詳細については、[GitLab Mattermostを独自のサーバーで実行する](https://docs.gitlab.com/integration/mattermost/#running-gitlab-mattermost-on-its-own-server)を参照してください。

`gitlab.rb`ファイルを変更する場合は、各サービスに対してNGINX設定を個別に構成します。`nginx['foo']`を使用して指定された設定は、サービス固有のNGINX構成（`registry_nginx['foo']`や`mattermost_nginx['foo']`など）にはレプリケートされません。たとえば、GitLab、Mattermost、レジストリのHTTPからHTTPSへのリダイレクトを構成するには、次の設定を`gitlab.rb`に追加します:

```ruby
nginx['redirect_http_to_https'] = true
registry_nginx['redirect_http_to_https'] = true
mattermost_nginx['redirect_http_to_https'] = true
```

## HTTPSを有効にする {#enable-https}

Linuxパッケージインストールでは、デフォルトではHTTPSは使用されません。`gitlab.example.com`のHTTPSを有効にするには:

- [Let's Encryptを使用して、Freeで自動化されたHTTPSを使用します](ssl/_index.md#enable-the-lets-encrypt-integration)。
- [独自の証明書を使用してHTTPSを手動で構成します](ssl/_index.md#configure-https-manually)。

GitLabホスト名のSSLを終了するためにプロキシ、ロードバランサー、またはその他の外部デバイスを使用する場合は、[外部、プロキシ、ロードバランサーのSSL終端](ssl/_index.md#configure-a-reverse-proxy-or-load-balancer-ssl-termination)を参照してください。

## デフォルトのプロキシヘッダーを変更する {#change-the-default-proxy-headers}

デフォルトでは、`external_url`を指定すると、Linuxパッケージインストールにより、ほとんどの環境に適したNGINXプロキシヘッダーが設定されます。

たとえば、`external_url`で`https`スキーマを指定すると、Linuxパッケージインストールでは次のようになります:

```plaintext
"X-Forwarded-Proto" => "https",
"X-Forwarded-Ssl" => "on"
```

GitLabインスタンスが、リバースプロキシの背後にあるなど、より複雑な設定になっている場合は、プロキシヘッダーを調整して、次のようなエラーを回避する必要がある場合があります:

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

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

NGINXでサポートされている任意のヘッダーを指定できます。

## GitLabの信頼できるプロキシとNGINX `real_ip`モジュールを構成する {#configure-gitlab-trusted-proxies-and-nginx-real_ip-module}

デフォルトでは、NGINXとGitLabは接続されたクライアントのIPアドレスを記録します。

GitLabがリバースプロキシの背後にある場合は、プロキシのIPアドレスをクライアントアドレスとして表示したくない場合があります。

異なるアドレスを使用するようにNGINXを構成するには、リバースプロキシを`real_ip_trusted_addresses`リストに追加します:

```ruby
# Each address is added to the NGINX config as 'set_real_ip_from <address>;'
nginx['real_ip_trusted_addresses'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
# Other real_ip config options
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
```

これらのオプションの説明については、[NGINX `realip`モジュールのドキュメント](http://nginx.org/en/docs/http/ngx_http_realip_module.html)を参照してください。

デフォルトでは、Linuxパッケージインストールは、`real_ip_trusted_addresses`のIPアドレスをGitLabの信頼できるプロキシとして使用します。信頼できるプロキシ設定により、ユーザーがそれらのIPアドレスからサインインしたと表示されなくなります。

ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

## PROXYプロトコルを構成する {#configure-the-proxy-protocol}

[PROXYプロトコル](https://www.haproxy.org/download/3.1/doc/proxy-protocol.txt)を使用して、GitLabの前にHAProxyのようなプロキシを使用するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Enable termination of ProxyProtocol by NGINX
   nginx['proxy_protocol'] = true
   # Configure trusted upstream proxies. Required if `proxy_protocol` is enabled.
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

この設定を有効にすると、NGINXはこれらのリスナー上のPROXYプロトコルトラフィックのみを受け入れます。モニタリングチェックなど、他の環境を調整します。

## バンドルされていないWebサーバーを使用する {#use-a-non-bundled-web-server}

{{< alert type="note" >}}

GitLabは、ガイダンスのみを目的として、バンドルされていないWebサーバーをセットアップする方法に関する情報を提供します。バンドルされていないコンポーネントのトラブルシューティングは、[サポートスコープ外](https://about.gitlab.com/support/statement-of-support/#out-of-scope-for-all-self-managed-and-saas-users)と見なされます。バンドルされていないWebサーバーを使用する際に質問や問題がある場合は、バンドルされていないWebサーバーのドキュメントを参照してください。

{{< /alert >}}

デフォルトでは、LinuxパッケージはバンドルされたNGINXとともにGitLabをインストールします。Linuxパッケージインストールでは、`gitlab-www`ユーザーを介してWebサーバーへのアクセスが許可されます。これは、同じ名前のグループに存在します。外部WebサーバーがGitLabにアクセスできるようにするには、外部Webサーバーユーザーを`gitlab-www`グループに追加します。

Apacheや既存のNGINXインストールのような別のWebサーバーを使用するには:

1. バンドルされたNGINXを無効にする:

   `/etc/gitlab/gitlab.rb`で次のように設定します:

   ```ruby
   nginx['enable'] = false
   ```

1. バンドルされていないWebサーバーユーザーのユーザー名を設定します:

   Linuxパッケージインストールには、外部Webサーバーユーザーのデフォルト設定はありません。設定で指定する必要があります。例: 

   - Debian / Ubuntu: デフォルトのユーザーは、ApacheとNGINXの両方で`www-data`です。
   - RHEL/CentOS: NGINXユーザーは`nginx`です。

   続行する前にApacheまたはNGINXをインストールして、Webサーバーユーザーが作成されるようにします。そうしないと、Linuxパッケージインストールは再構成中に失敗します。

   Webサーバーユーザーが`www-data`の場合は、`/etc/gitlab/gitlab.rb`で次のように設定します:

   ```ruby
   web_server['external_users'] = ['www-data']
   ```

   この設定は配列であるため、`gitlab-www`グループに追加する複数のユーザーを指定できます。

   変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

   SELinuxを使用しており、Webサーバーが制限されたSELinuxプロファイルで実行されている場合は、[Webサーバーの制限を緩める](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache#selinux-modifications)必要がある場合があります。

   Webサーバーユーザーが、外部Webサーバーで使用されるすべてのディレクトリに対する正しいユーザー権限を持っていることを確認します。そうしないと、`failed (XX: Permission denied) while reading upstream`エラーが発生する可能性があります。

1. 信頼できるプロキシのリストに、バンドルされていないWebサーバーを追加します:

   Linuxパッケージインストールは通常、信頼できるプロキシのリストを、バンドルされたNGINXの`real_ip`モジュールの設定にデフォルト設定します。

   バンドルされていないWebサーバーの場合は、リストを直接構成します。WebサーバーがGitLabと同じマシン上にない場合は、WebサーバーのIPアドレスを含めます。そうしないと、ユーザーはWebサーバーのIPアドレスからサインインしているように見えます。

   ```ruby
   gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
   ```

1. オプション。Apacheを使用する場合は、GitLab Workhorse設定を設定します:

   ApacheはUNIXソケットに接続できず、TCPポートに接続する必要があります。GitLab WorkhorseがTCP（デフォルトポート8181）でリッスンできるようにするには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_workhorse['listen_network'] = "tcp"
   gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
   ```

   変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

1. 正しいWebサーバー設定ファイルをダウンロードします:

   [GitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/support/nginx)に移動し、必要な設定をダウンロードします。SSLの有無にかかわらず、GitLabを提供するための正しい設定ファイルを選択してください。変更する必要がある場合があります:

   - `YOUR_SERVER_FQDN`の値をFQDNにします。
   - SSLを使用する場合は、SSLキーの場所。
   - ログファイルの場所。

## NGINXの設定オプション {#nginx-configuration-options}

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

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

### NGINXのリスナーポートを設定する {#set-the-nginx-listen-port}

デフォルトでは、NGINXは`external_url`で指定されたポートでリッスンするか、標準ポート（HTTPの場合は80、HTTPSの場合は443）を使用します。リバースプロキシの背後でGitLabを実行する場合は、リスナーポートをオーバーライドする必要がある場合があります。

リスナーポートを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します。たとえば、ポート8081を使用するには:

   ```ruby
   nginx['listen_port'] = 8081
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

### NGINXログの冗長度レベルを変更する {#change-the-verbosity-level-of-nginx-logs}

デフォルトでは、NGINXは`error`冗長度レベルでログを記録します。

ログレベルを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['error_log_level'] = "debug"
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

有効なログレベル値については、[NGINXドキュメント](https://nginx.org/en/docs/ngx_core_module.html#error_log)を参照してください。

### Referrer-Policyヘッダーを設定する {#set-the-referrer-policy-header}

デフォルトでは、GitLabはすべてのレスポンスで`Referrer-Policy`ヘッダーを`strict-origin-when-cross-origin`に設定します。この設定により、クライアントは次のようになります:

- 同じoriginからのリクエストのリファラーとして完全なURLを送信します。
- クロスoriginリクエストに対しては、originのみを送信します。

このヘッダーを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['referrer_policy'] = 'same-origin'
   ```

   このヘッダーを無効にして、クライアントのデフォルト設定を使用するには:

   ```ruby
   nginx['referrer_policy'] = false
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

{{< alert type="warning" >}}

これを`origin`または`no-referrer`に設定すると、完全なリファラーURLを必要とするGitLab機能がブロックされます。

{{< /alert >}}

詳細については、[Referrer Policyの仕様](https://www.w3.org/TR/referrer-policy/)を参照してください。

### Gzip圧縮を無効にする {#disable-gzip-compression}

デフォルトでは、GitLabは10240バイトを超えるテキストデータに対してGzip圧縮を有効にします。Gzip圧縮を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['gzip_enabled'] = false
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

{{< alert type="note" >}}

`gzip`設定は、メインのGitLabアプリケーションにのみ適用され、他のサービスには適用されません。

{{< /alert >}}

### プロキシリクエストバッファリングを無効にする {#disable-proxy-request-buffering}

特定の場所に対するリクエストバッファリングを無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。
1. NGINX設定を正常にリロードします:

   ```shell
   sudo gitlab-ctl hup nginx
   ```

`hup`コマンドの詳細については、[NGINXドキュメント](https://nginx.org/en/docs/control.html)を参照してください。

### `robots.txt`の設定 {#configure-robotstxt}

インスタンスのカスタム[`robots.txt`](https://www.robotstxt.org/robotstxt.html)ファイルを構成するには:

1. カスタム`robots.txt`ファイルを作成し、そのパスをメモします。

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   nginx['custom_gitlab_server_config'] = "\nlocation =/robots.txt { alias /path/to/custom/robots.txt; }\n"
   ```

   `/path/to/custom/robots.txt`をカスタム`robots.txt`ファイルへの実際のパスに置き換えます。

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

この設定は、カスタム`robots.txt`ファイルを提供するために、[カスタムNGINX設定](#insert-custom-nginx-settings-into-the-gitlab-server-block)を追加します。

### カスタムNGINX設定をGitLabサーバーブロックに挿入する {#insert-custom-nginx-settings-into-the-gitlab-server-block}

GitLabのNGINX `server`ブロックにカスタム設定を追加するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Example: block raw file downloads from a specific repository
   nginx['custom_gitlab_server_config'] = "location ^~ /foo-namespace/bar-project/raw/ {\n deny all;\n}\n"
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

これにより、定義された文字列が`/var/opt/gitlab/nginx/conf/service_conf/gitlab-rails.conf`の`server`ブロックの最後に追加されます。

{{< alert type="warning" >}}

カスタム設定は、`gitlab.rb`ファイル内の他の場所で定義されている設定と競合する可能性があります。

{{< /alert >}}

#### 注記 {#notes}

- 新しい場所を追加する場合は、以下を含める必要がある場合があります:

  ```conf
  proxy_cache off;
  proxy_http_version 1.1;
  proxy_pass http://gitlab-workhorse;
  ```

  これらがないと、サブロケーションは404エラーを返す可能性があります。

- `/`ルートの場所または`/assets`の場所を追加することはできません。これらはすでに`gitlab-rails.conf`に存在するためです。

### カスタム設定をNGINX設定に挿入する {#insert-custom-settings-into-the-nginx-configuration}

NGINX設定にカスタム設定を追加するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Example: include a directory to scan for additional config files
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/sites-enabled/*.conf;"
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

これにより、定義された文字列が`/var/opt/gitlab/nginx/conf/nginx.conf`の`http`ブロックの最後に追加されます。

たとえば、カスタムサーバーブロックを作成して有効にするには:

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

生成されたLet's Encrypt SSL証明書に[代替名として](ssl/_index.md#add-alternative-domains-to-the-certificate)サーバーブロックのドメインを追加できます。

`/etc/gitlab/`ディレクトリ内のカスタムNGINX設定は、アップグレード中および`sudo gitlab-ctl backup-etc`が手動で実行されたときに`/etc/gitlab/config_backup/`にバックアップされます。

### カスタムエラーページを構成する {#configure-custom-error-pages}

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

   この例では、デフォルトの404エラーページを変更します。404や502など、有効なHTTPエラーコードにはこの形式を使用できます。

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

404エラーページの結果は次のようになります:

![カスタム404エラーページ](img/error_page_example.png)

### 既存のPassengerおよびNGINXインストールを使用する {#use-an-existing-passenger-and-nginx-installation}

既存のPassengerおよびNGINXインストールでGitLabをホストし、アップデートとインストールのためにLinuxパッケージを使用できます。

NGINXを無効にすると、`nginx.conf`に手動で追加しない限り、Mattermostなど、Linuxパッケージインストールに含まれている他のサービスにアクセスできなくなります。

#### 設定 {#configuration}

既存のPassengerおよびNGINXインストールでGitLabをセットアップするには:

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

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

#### 仮想ホスト（サーバーブロック）を構成する {#configure-the-virtual-host-server-block}

カスタムPassenger/NGINXインストールでは:

1. 次のコンテンツを含む新しいサイト設定ファイルを作成します:

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

403 Forbiddenエラーが表示された場合は、Passengerが`/etc/nginx/nginx.conf`で有効になっていることを確認してください:

1. この行のコメントを解除します:

   ```plaintext
   # include /etc/nginx/passenger.conf;
   ```

1. NGINX設定をリロードします:

   ```shell
   sudo service nginx reload
   ```

### NGINXステータスモニタリングを構成する {#configure-nginx-status-monitoring}

デフォルトでは、GitLabは`127.0.0.1:8060/nginx_status`にNGINXヘルスチェックエンドポイントを構成して、NGINXサーバーのステータスをモニタリングします。仮想ホストトラフィックステータス（VTS）モジュールが有効になっている場合（デフォルト）、このポートは`127.0.0.1:8060/metrics`でPrometheusメトリクスも提供します。

エンドポイントには次の情報が表示されます:

```plaintext
Active connections: 1
server accepts handled requests
18 18 36
Reading: 0 Writing: 1 Waiting: 0
```

- アクティブな接続: 合計でオープン接続。
- 3つの図を表示:
  - 受け入れられたすべての接続。
  - 処理されたすべての接続。
  - 処理されたリクエストの合計数。
- 読み取り: NGINXはリクエストヘッダーを読み取ります。
- 書き込み: NGINXはリクエスト本文を読み取り、リクエストを処理するか、クライアントに応答を書き込みます。
- 待機中: Keep-Alive接続。この数は、`keepalive_timeout`ディレクティブによって異なります。

#### NGINXステータスオプションを構成する {#configure-nginx-status-options}

NGINXステータスオプションを構成するには:

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

{{< alert type="note" >}}

VTSが有効になっている場合は、オプションに`"stub_status" => "on"`を含めないでください。この設定はすべてのエンドポイントに適用され、Prometheusメトリクスの代わりに基本的な`/metrics``nginx_status`出力を返します。

{{< /alert >}}

   VTSを無効にして、基本的な`nginx_status`メトリクスのみを使用するには:

   ```ruby
   nginx['status']['vts_enable'] = false
   ```

   NGINXステータスエンドポイントを無効にするには:

   ```ruby
   nginx['status'] = {
    'enable' => false
   }
   ```

1. ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#linux-package-installations)し、変更を有効にします。

#### VTSモジュールで高度なメトリクスを構成する {#configure-advanced-metrics-with-vts-module}

GitLabには、レイテンシーパーセンタイルを含む追加のパフォーマンスメトリクスを提供するためのNGINX VTS（Virtual hostトラフィックStatus）モジュールが含まれています。

ヒストグラムバケットでVTSモジュールを有効にする前に、次の影響を考慮してください:

- メトリクスデータを保存するためにメモリ使用量が増加します。影響は、仮想ホストとトラフィックのボリュームの数によってスケールします。
- 各リクエストでヒストグラムメトリクスを計算すると、少量のCPUが消費されます。
- これらのメトリクスをPrometheusで収集する場合は、追加のストレージが必要です。

トラフィックの多いインストールの場合、これらのメトリクスを有効にした後、システムリソースを監視して、パフォーマンスが許容範囲内にとどまるようにしてください。

高度なレイテンシーメトリクスを有効にするには:

1. 次の設定を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   nginx['custom_gitlab_server_config'] = "vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;"
   ```

   または、カスタムNGINX設定ファイルを作成します:

   ```shell
   sudo mkdir -p /etc/gitlab/nginx/conf.d/
   sudo vim /etc/gitlab/nginx/conf.d/vts-custom.conf
   ```

1. これらの設定を追加して、ヒストグラムバケットとフィルタリングを有効にします:

   ```nginx
   vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.25 0.5 1 2.5 5 10;
   vhost_traffic_status_filter_by_host on;
   vhost_traffic_status_filter on;
   vhost_traffic_status_filter_by_set_key $server_name server::*;
   ```

1. カスタム設定を含めるようにGitLabを構成するには、以下を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   nginx['custom_nginx_config'] = "include /etc/gitlab/nginx/conf.d/vts-custom.conf;"
   ```

1. NGINXを再構成して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart nginx
   ```

これらの設定を有効にした後、Prometheusクエリを使用して、さまざまなレイテンシーメトリクスを監視できます:

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

GitLab Workhorse固有のメトリクスの場合は、以下を使用できます:

```plaintext
# 90th percentile upstream latency for GitLab Workhorse
histogram_quantile(0.90, rate(nginx_vts_upstream_response_duration_seconds_bucket{upstream="gitlab-workhorse"}[5m]))

# Average upstream response time for GitLab Workhorse
rate(nginx_vts_upstream_response_seconds_total{upstream="gitlab-workhorse"}[5m]) /
rate(nginx_vts_upstream_requests_total{upstream="gitlab-workhorse",code=~"2xx|3xx|4xx|5xx"}[5m])
```

#### アップロードのユーザー権限を構成する {#configure-user-permissions-for-uploads}

ユーザーのアップロードにアクセスできるようにするには、NGINXユーザー（通常は`www-data`）を`gitlab-www`グループに追加します:

```shell
sudo usermod -aG gitlab-www www-data
```

### テンプレート {#templates}

この設定ファイルは、[バンドルされたGitLab NGINX設定](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/templates/default/nginx-gitlab-rails.conf.erb)に似ていますが、次の点が異なります:

- Pumaの代わりにPassenger設定が使用されます。
- HTTPSはデフォルトでは有効になっていませんが、有効にすることができます。

NGINX設定を変更した後:

- Debianベースのシステムの場合は、NGINXを再起動します:

  ```shell
  sudo service nginx restart
  ```

- その他のシステムについては、オペレーティングシステムのドキュメントを参照して、NGINXを再起動するための正しいコマンドを確認してください。
