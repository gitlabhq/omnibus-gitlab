---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SSLトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページには、GitLabの作業中に発生する可能性のある一般的なSSL関連のエラーとシナリオのリストが含まれています。これは、主要なSSLドキュメントへの追加として役立つはずです:

- [Linuxパッケージインストール用のSSLを設定](_index.md)。
- [GitLab Runnerの自己署名証明書またはカスタム認証局](https://docs.gitlab.com/runner/configuration/tls-self-signed/)。
- [手動でHTTPSを設定](_index.md#configure-https-manually)。

## 役立つOpenSSLデバッグコマンド {#useful-openssl-debugging-commands}

場合によっては、SSL証明書チェーンをソースで直接表示することで、より良い全体像を把握するのに役立ちます。これらのコマンドは、診断およびデバッグのための標準OpenSSLツールライブラリの一部です。

> [!note]
> GitLabには、すべてのGitLabライブラリがリンクされている独自の[カスタムコンパイル版OpenSSL](_index.md#details-on-how-gitlab-and-ssl-work)が含まれています。このOpenSSLバージョンを使用して以下のコマンドを実行することが重要です。

- HTTPS経由でホストへのテスト接続を実行します。`HOSTNAME`をGitLab URL (HTTPSを除く) に置き換え、`port`をHTTPS接続を提供するポート (通常443) に置き換えてください:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port
  ```

  `echo`コマンドはサーバーにnullリクエストを送信し、追加の入力を待つのではなく、接続を閉じさせます。同じコマンドを使用して、`HOSTNAME:port`をリモートホストのドメインとポート番号に置き換えることで、リモートホスト（例えば、外部リポジトリをホストしているサーバー）をテストできます。

  このコマンドの出力は、証明書チェーン、サーバーが提示する公開証明書、および発生した場合は検証または接続エラーを示します。これにより、SSL設定に関する即時的な問題をすばやく確認できます。

- `x509`を使用して証明書の詳細をテキスト形式で表示します。`/path/to/certificate.crt`を証明書のパスに置き換えてください:

  ```shell
  /opt/gitlab/embedded/bin/openssl x509 -in /path/to/certificate.crt -text -noout
  ```

  例えば、GitLabはLet's Encryptから取得した証明書を自動的に`/etc/gitlab/ssl/hostname.crt`にフェッチして配置します。そのパスと`x509`コマンドを使用して、証明書の情報（例：ホスト名、発行者、有効期間など）をすばやく表示できます。

  証明書に問題がある場合は、[エラーが発生します](#custom-certificates-missing-or-skipped)。

- サーバーから証明書をフェッチしてデコードします。これは、上記の2つのコマンドを組み合わせて、サーバーのSSL証明書をフェッチし、テキストにデコードします:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port | /opt/gitlab/embedded/bin/openssl x509 -text -noout
  ```

## 一般的なSSLエラー {#common-ssl-errors}

1. `SSL certificate problem: unable to get local issuer certificate`

   このエラーは、クライアントがルートCAを取得できないことを示します。これを修正するには、クライアント上で接続しようとしているサーバーの[ルートCAを信頼](_index.md#install-custom-public-certificates)するか、接続しようとしているサーバー上で完全なチェーン証明書を提示するように[証明書を変更](_index.md#configure-https-manually)するかのいずれかの方法があります。

   > [!note]
   > クライアントが接続する際のSSLエラーを防ぐために、完全な証明書チェーンを使用することをお勧めします。完全な証明書チェーンの順序は、サーバー証明書を最初とし、すべての中間証明書が続き、ルートCAが最後であるべきです。

1. `unable to verify the first certificate`

   このエラーは、サーバーによって不完全な証明書チェーンが提示されていることを示します。このエラーを修正するには、[サーバーの証明書を完全なチェーン証明書に置き換える](_index.md#configure-https-manually)必要があります。完全な証明書チェーンの順序は、サーバー証明書を最初とし、すべての中間証明書が続き、ルートCAが最後であるべきです。

   > [!note]
   > `/opt/gitlab/embedded/bin/openssl`ユーティリティの代わりにシステムOpenSSLユーティリティを実行中にこのエラーが発生した場合は、CA証明書をOSレベルで更新して修正してください。

1. `certificate signed by unknown authority`

   このエラーは、クライアントが証明書またはCAを信頼していないことを示します。このエラーを修正するには、サーバーに接続するクライアントが[証明書またはCAを信頼](_index.md#install-custom-public-certificates)する必要があります。

1. `SSL certificate problem: self signed certificate in certificate chain`

   このエラーは、クライアントが証明書またはCAを信頼していないことを示します。このエラーを修正するには、サーバーに接続するクライアントが[証明書またはCAを信頼](_index.md#install-custom-public-certificates)する必要があります。

1. `x509: certificate relies on legacy Common Name field, use SANs instead`

   このエラーは、証明書に[SAN](http://wiki.cacert.org/FAQ/subjectAltName) (subjectAltName) を設定する必要があることを示します。詳細については、[こちらのイシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28841)を参照してください。

## 証明書が原因で再設定が失敗する {#reconfigure-fails-due-to-certificates}

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

`/opt/gitlab/embedded/ssl/certs`を確認し、有効なX.509証明書ではない`README.md`以外のファイルをすべて削除してください。

> [!note]
> `gitlab-ctl reconfigure`を実行すると、カスタム公開証明書のサブジェクトハッシュから名前が付けられたシンボリックリンクが作成され、`/opt/gitlab/embedded/ssl/certs/`に配置されます。`/opt/gitlab/embedded/ssl/certs/`内の壊れたシンボリックリンクは自動的に削除されます。`/opt/gitlab/embedded/ssl/certs/`に保存されている`cacert.pem`および`README.md`以外のファイルは、`/etc/gitlab/trusted-certs/`に移動されます。

## カスタム証明書が見つからないかスキップされた {#custom-certificates-missing-or-skipped}

`/opt/gitlab/embedded/ssl/certs/`にシンボリックリンクが作成されず、`gitlab-ctl reconfigure`実行後に「Skipping `cert.pem`」というメッセージが表示される場合、以下の4つの問題のいずれかである可能性があります:

1. `/etc/gitlab/trusted-certs/`のファイルがシンボリックリンクである
1. ファイルが有効なPEMまたはDERエンコードされた証明書ではない
1. 証明書に文字列`TRUSTED`が含まれている

以下のコマンドを使用して証明書の有効性をテストします:

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

無効な証明書ファイルは以下の出力を生成します:

- ```shell
  unable to load certificate
  140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
  ```

- ```shell
  cannot load certificate
  PEM_read_bio_X509_AUX() failed (SSL: error:0909006C:PEM routines:get_name:no start line:Expecting: TRUSTED CERTIFICATE)
  ```

どちらの場合でも、証明書が以下のもの以外で開始および終了している場合:

```shell
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

その場合、それらはGitLabと互換性がありません。それらを証明書コンポーネント（サーバー、中間、ルート）に分離し、互換性のあるPEM形式に変換する必要があります。

証明書自体を調べるときは、文字列`TRUSTED`を探してください:

```plaintext
-----BEGIN TRUSTED CERTIFICATE-----
...
-----END TRUSTED CERTIFICATE-----
```

上記の例のように存在する場合は、文字列`TRUSTED`を削除し、`gitlab-ctl reconfigure`を再度実行してみてください。

## カスタム証明書が検出されない {#custom-certificates-not-detected}

`gitlab-ctl reconfigure`を実行した後で:

1. `/opt/gitlab/embedded/ssl/certs/`にシンボリックリンクが作成されない;
1. カスタム証明書を`/etc/gitlab/trusted-certs/`に配置している; かつ
1. スキップされたカスタム証明書やシンボリックリンクされたカスタム証明書のメッセージが表示されない

これは、Linuxパッケージインストールがカスタム証明書がすでに追加されていると認識している問題に遭遇している可能性があります。

解決するには、信頼された証明書ディレクトリハッシュを削除します:

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

その後、`gitlab-ctl reconfigure`を再度実行します。再設定により、カスタム証明書が検出され、シンボリックリンクが作成されるはずです。

## 不明な認証局によって署名されたLet's Encrypt証明書 {#lets-encrypt-certificate-signed-by-unknown-authority}

Let's Encryptインテグレーションの初期実装では、証明書のみが使用され、完全な証明書チェーンは使用されませんでした。

10.5.4バージョン以降では、完全な証明書チェーンが使用されます。すでに証明書を使用しているインストールの場合、証明書が有効期限切れに近づいていることを更新ロジックが示すまで、切り替えは行われません。それを早めるには、以下を実行します

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

ここでHOSTNAMEは証明書のホスト名です。

## 再設定時にLet's Encryptが失敗する {#lets-encrypt-fails-on-reconfigure}

> [!note]
> [Let's Debug](https://letsdebug.net/)診断ツールを使用してドメインをテストできます。Let's Encrypt証明書を発行できない理由を特定するのに役立ちます。

再設定時に、Let's Encryptが失敗する一般的なシナリオがいくつかあります:

- サーバーがLet's Encrypt検証サーバーに到達できない場合、またはその逆の場合、Let's Encryptは失敗する可能性があります:

  ```shell
  letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
  ```

  Let's Encryptが原因でGitLabの再設定に問題が発生した場合は、[ポート80と443が開いてアクセス可能であることを確認](_index.md#enable-the-lets-encrypt-integration)してください。

- ドメインの認証局認可(CAA) レコードは、Let's Encryptがドメインの証明書を発行することを許可していません。再設定出力で次のエラーを探してください:

  ```shell
  letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
  ```

- `gitlab.example.com`のようなテストドメインを証明書なしで使用している場合、上記の`unable to request certificate`エラーが表示されます。その場合は、`/etc/gitlab/gitlab.rb`で`letsencrypt['enable'] = false`を設定してLet's Encryptを無効にしてください。
- [Let's Encryptはレート制限を適用](https://letsencrypt.org/docs/rate-limits/)しますが、これはトップレベルドメインで行われます。クラウドプロバイダーのホスト名を`external_url`として使用している場合（例: `*.cloudapp.azure.com`）、Let's Encryptは`azure.com`に制限を適用し、証明書の作成が不完全になる可能性があります。

  その場合は、Let's Encrypt証明書を手動で更新してみてください:

  ```shell
  sudo gitlab-ctl renew-le-certs
  ```

## 内部CA証明書をGitLabで使用する {#using-an-internal-ca-certificate-with-gitlab}

内部CA証明書を使用してGitLabインスタンスを設定した後、さまざまなCLIツールを使用してそれにアクセスできない場合があります。次の問題が発生する可能性があります:

- `curl`が失敗します:

  ```shell
  curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: unable to get local issuer certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- [Railsコンソール](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)を使用したテストも失敗します:

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

- このGitLabインスタンスから[ミラー](https://docs.gitlab.com/user/project/repository/mirror/)を設定する際に、エラー`SSL certificate problem: unable to get local issuer certificate`が表示されます。
- 証明書のパスを指定すると`openssl`が機能します:

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

以前に説明した問題が発生した場合は、証明書を`/etc/gitlab/trusted-certs`に追加し、`sudo gitlab-ctl reconfigure`を実行してください。

## X.509キー値不一致エラー {#x509-key-values-mismatch-error}

証明書バンドルでインスタンスを設定した後、NGINXは以下のエラーメッセージを表示する場合があります:

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

このエラーメッセージは、提供されたサーバー証明書とキーが一致しないことを意味します。以下のコマンドを実行し、出力を比較することでこれを確認できます:

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

以下は、一致するキーと証明書間のmd5出力の例です。一致するmd5ハッシュに注意してください:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

これは、異なるmd5ハッシュを示す、一致しないキーと証明書との対立する出力です:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

前の例のように両方の出力が異なる場合、証明書とキーの間に不一致があります。さらなるサポートについては、SSL証明書の提供元にお問い合わせください。

## エラー: `certificate signed by unknown authority` {#error-certificate-signed-by-unknown-authority}

[内部CA証明書をGitLabで使用する](ssl_troubleshooting.md#using-an-internal-ca-certificate-with-gitlab)で言及されているエラーが発生する以外に、CIパイプラインが`Pending`ステータスで停止する可能性があります。Runnerログに次のエラーメッセージが表示される場合があります:

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

[GitLab Runnerの自己署名証明書またはカスタム認証局](https://docs.gitlab.com/runner/configuration/tls-self-signed/)の詳細に従ってください。

## 自己署名SSL証明書を使用するリモートGitLabリポジトリのミラーリング {#mirroring-a-remote-gitlab-repository-that-uses-a-self-signed-ssl-certificate}

自己署名証明書を使用するリモートGitLabインスタンスから、ローカルGitLabインスタンスに[リポジトリをミラーリング](https://docs.gitlab.com/user/project/repository/mirror/)するように設定すると、ユーザーインターフェースに`SSL certificate problem: self signed certificate`エラーメッセージが表示される場合があります。

問題の原因は、以下を確認することで確認できます:

- `curl`が失敗します:

  ```shell
  $ curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: self signed certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Railsコンソールを使用したテストも失敗します:

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

この問題を修正するには、以下を実行します。

- リモートGitLabインスタンスからの自己署名証明書をローカルGitLabインスタンス上の`/etc/gitlab/trusted-certs`ディレクトリに追加し、[カスタム公開証明書をインストール](_index.md#install-custom-public-certificates)する手順に従って`sudo gitlab-ctl reconfigure`を実行してください。
- ローカルGitLabインスタンスがHelm Chartを使用してインストールされている場合は、[自己署名証明書をGitLabインスタンスに追加](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate)できます。

また、自己署名証明書を使用するリモートGitLabインスタンスからリポジトリをミラーしようとすると、別のエラーメッセージが表示される場合があります:

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

この場合、問題は証明書自体に関連している可能性があります:

1. 自己署名証明書にコモンネームが欠落していないことを検証します。もしそうであれば、有効な証明書を再生成します
1. 証明書を`/etc/gitlab/trusted-certs`に追加します。
1. `sudo gitlab-ctl reconfigure`を実行します。

## 内部または自己署名証明書が原因でGit操作を実行できない {#unable-to-perform-git-operations-due-to-an-internal-or-self-signed-certificate}

GitLabインスタンスが自己署名証明書を使用している場合、または証明書が内部認証局（CA）によって署名されている場合、Git操作を実行しようとすると次のエラーが発生する可能性があります:

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

この問題を修正するには、以下を実行します。

- 可能であれば、すべてのGit操作にSSHリモートを使用してください。これは、より安全で便利であると考えられています。
- HTTPSリモートを使用する必要がある場合は、以下を試すことができます:
  - 自己署名証明書または内部ルートCA証明書をローカルディレクトリ（例: `~/.ssl`）にコピーし、Gitが証明書を信頼するように設定します:

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - GitクライアントでSSL検証を無効にします。これは一時的な措置であり、セキュリティリスクと見なされる可能性があるためです。

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connectバージョン番号が間違っています {#ssl_connect-wrong-version-number}

設定ミスにより、次のような結果になる場合があります:

- `gitlab-rails/exceptions_json.log`のエントリに含まれるもの:

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- `gitlab-workhorse/current`に含まれるもの:

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- `gitlab-rails/sidekiq.log`または`sidekiq/current`に含まれるもの:

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

これらのエラーの一部はExcon Ruby gemに由来し、GitLabがHTTPのみを提供するリモートサーバーへのHTTPSセッションを開始するように設定されている状況で発生する可能性があります。

1つのシナリオは、HTTPSで提供されていない[オブジェクトストレージ](https://docs.gitlab.com/administration/object_storage/)を使用している場合です。GitLabが設定ミスを起こし、TLSハンドシェイクを試行しますが、オブジェクトストレージはプレーンなHTTPで応答します。

## `schannel: SEC_E_UNTRUSTED_ROOT` {#schannel-sec_e_untrusted_root}

Windowsで以下のエラーが発生した場合:

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

GitがOpenSSLを使用するように指定する必要があります:

```shell
git config --system http.sslbackend openssl
```

あるいは、SSL検証を無視して実行することもできます:

> [!warning]
> このオプションをグローバルレベルで無効にすることに関連する潜在的なセキュリティ問題のため、[SSLを無視](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslVerify)する際は注意してください。このオプションはトラブルシューティング時に_のみ_使用し、直後にSSL検証を再開してください。

```shell
git config --global http.sslVerify false
```

## OpenSSL 3へのアップグレード {#upgrade-to-openssl-3}

[バージョン17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)以降、GitLabはOpenSSL 3を使用します。一部の古いTLSプロトコルと暗号スイート、または外部インテグレーション用のより脆弱なTLS証明書は、OpenSSL 3のデフォルト設定と互換性がない可能性があります。

OpenSSL 3へのアップグレードにより、以下が必要になります。

- すべての受信および送信TLS接続には、TLS 1.2以上が必要です。
- TLS証明書は、最低112ビットのセキュリティを備えている必要があります。2048ビット未満のRSA、DSA、DHキー、および224ビット未満のECCキーは禁止されています。

次のいずれかのエラーメッセージが表示される場合があります:

- TLS接続がTLS 1.2より古いプロトコルを使用している場合、`no protocols available`。
- TLS証明書のセキュリティが112ビット未満の場合、`certificate key too weak`。
- レガシー暗号がリクエストされた場合、`unsupported cipher algorithm`。

[OpenSSL 3ガイド](openssl_3.md)を使用して、外部インテグレーションの互換性を特定し、評価してください。
