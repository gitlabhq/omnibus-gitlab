---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SSLのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabの使用中に発生する可能性のある、一般的なSSL関連のエラーとシナリオの一覧を示します。これは、SSLに関する主なドキュメントの追加として役立ちます:

- [Linuxパッケージ](_index.md)インストールのSSLを設定します。
- [GitLab Runnerの自己署名証明書またはカスタム認証局](https://docs.gitlab.com/runner/configuration/tls-self-signed.html)を参照してください。
- [HTTPSを手動で設定](_index.md#configure-https-manually)します。

## OpenSSLのデバッグに役立つコマンド {#useful-openssl-debugging-commands}

ソースで直接表示することで、SSL証明書チェーンの全体像を把握できると役立つ場合があります。これらのコマンドは、診断とデバッグを行うための標準のOpenSSLライブラリツールの一部です。

{{< alert type="note" >}}

GitLabには、すべてのGitLabライブラリがリンクされている独自の[カスタムコンパイルバージョンのOpenSSL](_index.md#details-on-how-gitlab-and-ssl-work)が含まれています。このOpenSSLバージョンを使用して、次のコマンドを実行することが重要です。

{{< /alert >}}

- HTTPS経由でホストへのテスト接続を実行します。`HOSTNAME`をGitLabのURL（HTTPSを除く）に置き換え、`port`をHTTPS接続を提供するポート（通常は443）に置き換えます:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port
  ```

  `echo`コマンドは、サーバーにヌルリクエストを送信し、追加の入力を待機するのではなく、接続を閉じさせます。同じコマンドを使用して、リモートホスト（たとえば、外部リポジトリをホストするサーバー）をテストできます。`HOSTNAME:port`をリモートホストのドメインとポート番号に置き換えます。

  このコマンドの出力は、証明書チェーン、サーバーが提示するパブリック証明書、および発生した場合の検証または接続エラーを示します。これにより、SSL設定に関する直接的な問題をすばやく確認できます。

- `x509`を使用して、証明書の詳細をテキスト形式で表示します。必ず`/path/to/certificate.crt`を証明書のパスに置き換えてください:

  ```shell
  /opt/gitlab/embedded/bin/openssl x509 -in /path/to/certificate.crt -text -noout
  ```

  たとえば、GitLabはLet's Encryptから取得した証明書を自動的に`/etc/gitlab/ssl/hostname.crt`に配置します。そのパスで`x509`コマンドを使用すると、証明書の情報を（たとえば、ホスト名、発行者、有効期限などを）すばやく表示できます。

  証明書に問題がある場合は、[エラーが発生](#custom-certificates-missing-or-skipped)します。

- サーバーから証明書をフェッチし、デコードします。これにより、上記のコマンドの両方が組み合わされて、サーバーのSSL証明書をフェッチし、テキストにデコードされます:

  ```shell
  echo | /opt/gitlab/embedded/bin/openssl s_client -connect HOSTNAME:port | /opt/gitlab/embedded/bin/openssl x509 -text -noout
  ```

## 一般的なSSLエラー {#common-ssl-errors}

1. `SSL certificate problem: unable to get local issuer certificate`

   このエラーは、クライアントがルート認証局を取得できないことを示します。この問題を解決するには、クライアントで接続しようとしているサーバーの[ルート認証局を信頼する](_index.md#install-custom-public-certificates)か、[証明書を修正](_index.md#configure-https-manually)して、接続しようとしているサーバーで完全なチェーン証明書を提示します。

   {{< alert type="note" >}}

   クライアントが接続するときにSSLエラーを防ぐために、完全な証明書チェーンを使用することをお勧めします。完全な証明書チェーンの順序は、最初にサーバー証明書、次いで全ての中間証明書、最後にルート認証局で構成される必要があります。

   {{< /alert >}}

1. `unable to verify the first certificate`

   このエラーは、不完全な証明書チェーンがサーバーによって提示されていることを示します。このエラーを解決するには、[サーバーの証明書を、完全なチェーン証明書に置き換える](_index.md#configure-https-manually)必要があります。完全な証明書チェーンの順序は、最初にサーバー証明書、次いで全ての中間証明書、最後にルート認証局で構成される必要があります。

   {{< alert type="note" >}}

   `/opt/gitlab/embedded/bin/openssl`ユーティリティの代わりにシステムのOpenSSLユーティリティを実行中にこのエラーが発生した場合は、OSレベルでCA証明書を更新して修正してください。

   {{< /alert >}}

1. `certificate signed by unknown authority`

   このエラーは、クライアントが証明書または認証局を信頼していないことを示します。このエラーを解決するには、サーバーに接続するクライアントは、[証明書または認証局を信頼する](_index.md#install-custom-public-certificates)必要があります。

1. `SSL certificate problem: self signed certificate in certificate chain`

   このエラーは、クライアントが証明書または認証局を信頼していないことを示します。このエラーを解決するには、サーバーに接続するクライアントは、[証明書または認証局を信頼する](_index.md#install-custom-public-certificates)必要があります。

1. `x509: certificate relies on legacy Common Name field, use SANs instead`

   このエラーは、[SAN](http://wiki.cacert.org/FAQ/subjectAltName)（subjectAltName）が証明書で構成されている必要があることを示します。詳細については、[このイシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28841)を参照してください。

## 証明書が原因で再構成に失敗する {#reconfigure-fails-due-to-certificates}

```shell
ERROR: Not a certificate: /opt/gitlab/embedded/ssl/certs/FILE. Move it from /opt/gitlab/embedded/ssl/certs to a different location and reconfigure again.
```

`/opt/gitlab/embedded/ssl/certs`を確認し、有効なX.509証明書ではない`README.md`以外のファイルをすべて削除します。

{{< alert type="note" >}}

`gitlab-ctl reconfigure`を実行すると、カスタムパブリック証明書のサブジェクトハッシュから名前が付けられたシンボリックリンクが構築され、`/opt/gitlab/embedded/ssl/certs/`に配置されます。`/opt/gitlab/embedded/ssl/certs/`の壊れたシンボリックリンクは自動的に削除されます。`cacert.pem`および`README.md`以外のファイルで、`/opt/gitlab/embedded/ssl/certs/`に保存されているファイルは、`/etc/gitlab/trusted-certs/`に移動されます。

{{< /alert >}}

## カスタム証明書が見つからないかスキップされました {#custom-certificates-missing-or-skipped}

`/opt/gitlab/embedded/ssl/certs/`にシンボリックリンクが作成されず、`gitlab-ctl reconfigure`の実行後に「`cert.pem`をスキップしています」というメッセージが表示される場合は、4つの問題のいずれかが存在している可能性があります:

1. `/etc/gitlab/trusted-certs/`内のファイルはシンボリックリンクです
1. ファイルが有効なPEMまたはDERエンコード証明書ではありません
1. 証明書に文字列`TRUSTED`が含まれています

次のコマンドを使用して、証明書の有効性をテストします:

```shell
/opt/gitlab/embedded/bin/openssl x509 -in /etc/gitlab/trusted-certs/example.pem -text -noout
/opt/gitlab/embedded/bin/openssl x509 -inform DER -in /etc/gitlab/trusted-certs/example.der -text -noout
```

無効な証明書ファイルは、次の出力を生成します:

- ```shell
  unable to load certificate
  140663131141784:error:0906D06C:PEM routines:PEM_read_bio:no start line:pem_lib.c:701:Expecting: TRUSTED CERTIFICATE
  ```

- ```shell
  cannot load certificate
  PEM_read_bio_X509_AUX() failed (SSL: error:0909006C:PEM routines:get_name:no start line:Expecting: TRUSTED CERTIFICATE)
  ```

これらのいずれの場合も、証明書が次のもの以外で開始および終了する場合は:

```shell
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
```

それらはGitLabと互換性がありません。それらを証明書のコンポーネント（サーバー、中間、ルート）に分離し、互換性のあるPEM形式に変換する必要があります。

証明書自体を検査する場合は、文字列`TRUSTED`を探します:

```plaintext
-----BEGIN TRUSTED CERTIFICATE-----
...
-----END TRUSTED CERTIFICATE-----
```

上記の例のようにそれがある場合は、文字列`TRUSTED`を削除して、`gitlab-ctl reconfigure`を再度実行してみてください。

## カスタム証明書が検出されない {#custom-certificates-not-detected}

`gitlab-ctl reconfigure`を実行した後:

1. `/opt/gitlab/embedded/ssl/certs/`にシンボリックリンクが作成されていません。
1. `/etc/gitlab/trusted-certs/`にカスタム証明書を配置しました。そして
1. スキップされたカスタム証明書メッセージまたはシンボリックリンクされたカスタム証明書メッセージは表示されません

Linuxパッケージのインストールで、カスタム証明書が既に追加されていると認識される問題が発生している可能性があります。

解決するには、信頼できる証明書ディレクトリのハッシュを削除します:

```shell
rm /var/opt/gitlab/trusted-certs-directory-hash
```

次に、`gitlab-ctl reconfigure`を再度実行します。再構成でカスタム証明書が検出され、シンボリックリンクされるはずです。

## Let's Encrypt証明書が不明な認証局によって署名されました {#lets-encrypt-certificate-signed-by-unknown-authority}

Let's Encryptインテグレーションの最初の実装では、完全な証明書チェーンではなく、証明書のみが使用されていました。

バージョン10.5.4以降では、完全な証明書チェーンが使用されます。証明書を既に使用しているインストールの場合、切り替えは、更新ロジックが証明書の有効期限が近いことを示すまで行われません。すぐに強制するには、以下を実行します

```shell
rm /etc/gitlab/ssl/HOSTNAME*
gitlab-ctl reconfigure
```

HOSTNAMEは証明書のホスト名です。

## Let's Encryptが再構成に失敗しました {#lets-encrypt-fails-on-reconfigure}

{{< alert type="note" >}}

[Let's Debug](https://letsdebug.net/)診断ツールを使用してドメインをテストできます。これにより、Let's Encrypt証明書を発行できない理由を把握できます。

{{< /alert >}}

再構成すると、Let's Encryptが失敗する可能性がある一般的なシナリオがあります:

- サーバーがLet's Encrypt検証サーバーに到達できない場合、またはその逆の場合、Let's Encryptが失敗する可能性があります:

  ```shell
  letsencrypt_certificate[gitlab.domain.com] (letsencrypt::http_authorization line 3) had an error: RuntimeError: acme_certificate[staging]  (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 20) had an error: RuntimeError: [gitlab.domain.com] Validation failed for domain gitlab.domain.com
  ```

  Let's Encryptが原因でGitLabの再構成で問題が発生した場合は、[必ずポート80および443が開いていてアクセスできることを確認してください](_index.md#enable-the-lets-encrypt-integration)。

- ドメインの認証局認可（CAA）レコードでは、Let's Encryptがドメインの証明書を発行することを許可していません。再構成出力で次のエラーを探します:

  ```shell
  letsencrypt_certificate[gitlab.domain.net] (letsencrypt::http_authorization line 5) had an error: RuntimeError: acme_certificate[staging]   (/opt/gitlab/embedded/cookbooks/cache/cookbooks/letsencrypt/resources/certificate.rb line 25) had an error: RuntimeError: ruby_block[create certificate for gitlab.domain.net] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/acme/resources/certificate.rb line 108) had an error: RuntimeError: [gitlab.domain.com] Validation failed, unable to request certificate
  ```

- `gitlab.example.com`などのテストドメインを証明書なしで使用している場合は、上記の`unable to request certificate`エラーが表示されます。その場合は、`/etc/gitlab/gitlab.rb`で`letsencrypt['enable'] = false`を設定して、Let's Encryptを除外します。

- [Let's Encryptのレート制限](https://letsencrypt.org/docs/rate-limits/)が適用され、最上位ドメインにあります。たとえば、クラウドプロバイダーのホスト名を`external_url`として使用している場合（たとえば、`*.cloudapp.azure.com`）、Let's Encryptは`azure.com`に制限を適用するため、証明書の作成が不完全になる可能性があります。

  その場合は、Let's Encrypt証明書の手動更新を試すことができます:

  ```shell
  sudo gitlab-ctl renew-le-certs
  ```

## GitLabで内部認証局証明書を使用する {#using-an-internal-ca-certificate-with-gitlab}

内部認証局証明書を使用してGitLabインスタンスを構成した後、さまざまなCLIツールを使用してアクセスできない場合があります。次の問題が発生する可能性があります:

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

- このGitLabインスタンスからの[ミラー](https://docs.gitlab.com/user/project/repository/mirror/)を設定すると、エラー`SSL certificate problem: unable to get local issuer certificate`が表示されます。
- 証明書のパスを指定すると、`openssl`が機能します:

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

以前に説明した問題が発生した場合は、証明書を`/etc/gitlab/trusted-certs`に追加し、`sudo gitlab-ctl reconfigure`を実行します。

## X.509キー値が一致しないエラー {#x509-key-values-mismatch-error}

証明書バンドルを使用してインスタンスを構成すると、NGINXに次のエラーメッセージが表示される場合があります:

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

このエラーメッセージは、指定したサーバー証明書とキーが一致しないことを意味します。これを確認するには、次のコマンドを実行して出力を比較します:

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

次は、一致するキーと証明書の間にあるmd5出力の例です。一致するmd5ハッシュに注意してください:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

これは、一致しないキーと証明書を使用した反対の出力で、異なるmd5ハッシュを示しています:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

2つの出力が前の例のように異なる場合、証明書とキーの間に不一致があります。詳細については、SSL証明書のプロバイダーにお問い合わせください。

## エラー: `certificate signed by unknown authority` {#error-certificate-signed-by-unknown-authority}

[GitLabで内部認証局証明書を使用する](ssl_troubleshooting.md#using-an-internal-ca-certificate-with-gitlab)で言及されているエラーが発生するだけでなく、CIパイプラインが`Pending`ステータスで停止する可能性があります。Runnerログに次のエラーメッセージが表示される場合があります:

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

[GitLab Runnerの自己署名証明書またはカスタム認証局](https://docs.gitlab.com/runner/configuration/tls-self-signed.html)の詳細に従ってください。

## 自己署名SSL証明書を使用するリモートGitLabリポジトリをミラーリングする {#mirroring-a-remote-gitlab-repository-that-uses-a-self-signed-ssl-certificate}

自己署名証明書を使用するリモートGitLabインスタンスから[リポジトリをミラーリング](https://docs.gitlab.com/user/project/repository/mirror/)するようにローカルのGitLabインスタンスを構成すると、ユーザーインターフェースに`SSL certificate problem: self signed certificate`エラーメッセージが表示される場合があります。

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

この問題を修正するには、以下を実行します:

- リモートのGitLabインスタンスからの自己署名証明書をローカルのGitLabインスタンスの`/etc/gitlab/trusted-certs`ディレクトリに追加し、[カスタムパブリック証明書のインストール](_index.md#install-custom-public-certificates)の手順に従って`sudo gitlab-ctl reconfigure`を実行します。
- Helmチャートを使用してローカルのGitLabインスタンスをインストールした場合は、[自己署名証明書をGitLabインスタンスに追加できます](https://docs.gitlab.com/runner/install/kubernetes.html#providing-a-custom-certificate-for-accessing-gitlab)。

自己署名証明書を使用するリモートGitLabインスタンスからリポジトリをミラーリングしようとすると、別のエラーメッセージが表示されることもあります:

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

この場合、問題は証明書自体に関連している可能性があります:

1. 自己署名証明書に共通名が欠落していないことを検証します。そうである場合は、有効な証明書を再生成します
1. 証明書を`/etc/gitlab/trusted-certs`に追加します。
1. `sudo gitlab-ctl reconfigure`を実行します。

## 内部証明書または自己署名証明書が原因でGit操作を実行できない {#unable-to-perform-git-operations-due-to-an-internal-or-self-signed-certificate}

GitLabインスタンスが自己署名証明書を使用している場合、または証明書が内部認証局（CA）によって署名されている場合は、Git操作を実行しようとすると、次のエラーが発生する可能性があります:

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

この問題を修正するには、以下を実行します:

- 可能であれば、すべてのGit操作にSSHリモートを使用します。これは、より安全で使いやすいと考えられています。
- HTTPSリモートを使用する必要がある場合は、以下を試すことができます:
  - 自己署名証明書または内部ルートCA証明書をローカルディレクトリ（たとえば、`~/.ssl`）にコピーし、証明書を信頼するようにGitを構成します:

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - GitクライアントでSSL検証を無効にします。これは、セキュリティリスクと見なされる可能性があるため、一時的な手段として意図されています。

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connectの間違ったバージョン番号 {#ssl_connect-wrong-version-number}

設定ミスにより、次の結果になる可能性があります:

- 次の内容を含む`gitlab-rails/exceptions_json.log`エントリ:

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- 次の内容を含む`gitlab-workhorse/current`:

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- 次の内容を含む`gitlab-rails/sidekiq.log`または`sidekiq/current`:

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

これらのエラーの一部はExcon Ruby gemから発生しており、GitLabがHTTPのみをサービスしているリモートサーバーへのHTTPSセッションを開始するように構成されている状況で生成される可能性があります。

1つのシナリオは、HTTPSで提供されていない[オブジェクトストレージ](https://docs.gitlab.com/administration/object_storage/)を使用していることです。GitLabは設定ミスされており、TLSハンドシェイクを試みますが、オブジェクトストレージはプレーンHTTPで応答します。

## `schannel: SEC_E_UNTRUSTED_ROOT` {#schannel-sec_e_untrusted_root}

Windowsを使用している場合に、次のエラーが発生した場合:

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

GitがOpenSSLを使用するように指定する必要があります:

```shell
git config --system http.sslbackend openssl
```

または、次を実行してSSL検証を無視できます:

{{< alert type="warning" >}}

グローバルレベルでこのオプションを無効にすることに関連する潜在的なセキュリティ上の問題があるため、[SSLの無視](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslVerify)には注意して進めてください。このオプションは、_トラブルシューティング_を行う場合にのみ使用し、すぐにSSL検証を復元してください。

{{< /alert >}}

```shell
git config --global http.sslVerify false
```

## OpenSSL 3へのアップグレード {#upgrade-to-openssl-3}

[バージョン17.7](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1770)以降、GitLabはOpenSSL 3を使用します。古いTLSプロトコルや暗号スイート、または外部インテグレーションに使用する脆弱なTLS証明書の一部は、OpenSSL 3のデフォルトと互換性がない場合があります。

OpenSSL 3へのアップグレードにより、以下が必要になります:

- すべての受信および発信TLS接続には、TLS 1.2以上が必要です。
- TLS証明書には、少なくとも112ビットのセキュリティが必要です。2048ビット未満のRSA、DSA、DHキー、および224ビット未満のECCキーは禁止されています。

次のいずれかのエラーメッセージが発生する可能性があります:

- TLS接続でTLS 1.2より前のプロトコルを使用すると、`no protocols available`が表示されます。
- TLS証明書のセキュリティが112ビット未満の場合、`certificate key too weak`が表示されます。
- レガシー暗号がリクエストされると、`unsupported cipher algorithm`が表示されます。

外部インテグレーションの互換性を特定して評価するには、[OpenSSL 3ガイド](openssl_3.md)を使用してください。
