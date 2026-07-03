---
stage: GitLab Delivery
group: Build, Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージのインストールに関するトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、Linuxパッケージのインストール時にユーザーが遭遇する可能性のある一般的な問題について説明します。

## パッケージのダウンロード時にハッシュサムの不一致が発生する {#hash-sum-mismatch-when-downloading-packages}

`apt-get install`が次のエラーメッセージを出力している場合:

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

この問題を修正するには、以下を実行します:

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

別の回避策として、[CEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ce/)または[EEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ee/)リポジトリから正しいパッケージを手動で選択してダウンロードします:

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## openSUSEおよびSLESプラットフォームへのインストール時に不明なキー署名に関する警告が表示される {#installation-on-opensuse-and-sles-platforms-warns-about-unknown-key-signature}

Linuxパッケージは、パッケージリポジトリが署名付きメタデータを提供するだけでなく、[GPGキーで署名](update/package_signatures.md)されています。これにより、ユーザーに配布されるパッケージの信頼性と整合性が保証されます。ただし、openSUSEおよびSLESオペレーティングシステムで使用されているパッケージマネージャーでは、これらの署名に対して次のような誤った警告が表示される場合があります:

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

これは、zypperがリポジトリ設定ファイルの`gpgkey`キーワードを無視するという、zypperの既知のバグによるものです。ユーザーは、プロンプトが表示されたときにパッケージのインストールを手動で承認する必要があります。

したがって、openSUSEまたはSLESシステムでは、このような警告が表示された場合でも、インストールを続行しても安全です。

## apt/yumがGPG署名に関するエラーを返す {#aptyum-complains-about-gpg-signatures}

すでにGitLabリポジトリが設定されていて、`apt-get update`、`apt-get install`、または`yum install`を実行した際に、次のようなエラーが表示されることがあります:

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

または

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

このエラーは通常、キーストアにリポジトリのメタデータに署名するために現在使用されている公開キーがないことを意味します。GitLabは、aptおよびyumリポジトリのメタデータに署名するために使用されるGPGキーを定期的にローテーションします。現在および以前のキーの詳細については、[パッケージ署名](update/package_signatures.md)を参照してください。このエラーを修正するには、[新しいキーを取得する手順](update/package_signatures.md#fetch-the-latest-repository-signing-key)に従ってください。

## 再設定でエラーが表示される: `NoMethodError - undefined method '[]=' for nil:NilClass` {#reconfigure-shows-an-error-nomethoderror---undefined-method--for-nilnilclass}

`sudo gitlab-ctl reconfigure`を実行した際、またはパッケージのアップグレードに伴って再設定がトリガーされ、次のようなエラーが発生することがあります:

```plaintext
 ================================================================================
 Recipe Compile Error in /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb
 ================================================================================

NoMethodError
-------------
undefined method '[]=' for nil:NilClass

Cookbook Trace:
---------------
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/config.rb:21:in 'from_file'
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb:26:in 'from_file'

Relevant File Content:
```

このエラーは、`/etc/gitlab/gitlab.rb`設定ファイルに無効またはサポートされていない設定が含まれている場合にスローされます。タイプミスがないか、または設定ファイルに廃止された設定が含まれていないかを再確認してください。

利用可能な最新の設定を確認するには、`sudo gitlab-ctl diff-config`を使用するか、最新の[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を参照してください。

## ブラウザでGitLabにアクセスできない {#gitlab-is-unreachable-in-my-browser}

`/etc/gitlab/gitlab.rb`で`external_url`を[指定](settings/configuration.md#configure-the-external-url-for-gitlab)してみてください。また、ファイアウォールの設定も確認してください。GitLabサーバーでポート80（HTTP）または443（HTTPS）が閉じられている可能性があります。

GitLabまたはその他のレジストリなどのバンドルされたサービスの`external_url`を指定しても、`gitlab.rb`の他の部分が従う`key=value`形式には従いません。次の形式で設定されていることを確認してください:

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
```

> [!note]
> `external_url`と値の間に等号 (`=`) を追加しないでください。

## メールが配信されない {#emails-are-not-being-delivered}

メールの配信をテストするには、そのGitLabインスタンスでまだ使用されていないメールアドレスで新しいGitLabアカウントを作成します。

必要に応じて、`/etc/gitlab/gitlab.rb`の次の設定を使用して、GitLabから送信されるメールの「From」フィールドを変更できます:

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

## GitLabサービスのTCPポートがすでに使用されている {#tcp-ports-for-gitlab-services-are-already-taken}

デフォルトでは、PumaはTCPアドレス127.0.0.1:8080でリッスンします。NGINXは、すべてのインターフェースでポート80（HTTP）および443（HTTPS）をリッスンします。

Redis、PostgreSQL、およびPumaのポートは、`/etc/gitlab/gitlab.rb`で次のようにオーバーライドできます:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

NGINXのポート変更については、[NGINXのリッスンポートを設定する](settings/nginx.md#set-the-nginx-listen-port)を参照してください。

## GitユーザーにSSHアクセス権がない {#git-user-does-not-have-ssh-access}

### SELinuxが有効なシステム {#selinux-enabled-systems}

SELinuxが有効なシステムでは、Gitユーザーの`.ssh`ディレクトリまたはその内容のセキュリティコンテキストで不整合が生じることがあります。これは`sudo
gitlab-ctl reconfigure`を実行すると修正できます。これにより、`/var/opt/gitlab/.ssh`に`gitlab_shell_t`セキュリティコンテキストが設定されます。

この動作を改善するために、`semanage`を使用してコンテキストを永続的に設定しています。RHELベースのオペレーティングシステムのRPMパッケージには、`semanage`コマンドを利用できるように、ランタイム依存関係の`policycoreutils-python`が追加されています。

#### SELinuxの問題を診断して解決する {#diagnose-and-resolve-selinux-issues}

Linuxパッケージは、`/etc/gitlab/gitlab.rb`におけるデフォルトパスの変更を検出し、正しいファイルコンテキストを適用するはずです。

> [!note]
> GitLab 16.10以降では、管理者は`gitlab-ctl apply-sepolicy`を試してSELinuxイシューを自動的に修正できます。ランタイムのオプションについては、`gitlab-ctl apply-sepolicy --help`を参照してください。

カスタムデータパス設定を使用するインストールの場合、管理者はSELinuxの問題を手動で解決する必要がある場合があります。

データパスは`gitlab.rb`を介して変更できますが、一般的なシナリオでは`symlink`パスの使用を余儀なくされる場合があります。`symlink`パスは、[Gitalyデータパス](settings/configuration.md#store-git-data-in-an-alternative-directory)などのすべてのシナリオでサポートされているわけではないため、管理者は注意する必要があります。

たとえば、`/data/gitlab`の代わりに`/var/opt/gitlab`をベースデータディレクトリとして使用する場合、次のようにセキュリティコンテキストを修正します:

```shell
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/authorized_keys
sudo restorecon -Rv /data/gitlab/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-shell/config.yml
sudo restorecon -Rv /data/gitlab/gitlab-shell/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-rails/etc/gitlab_shell_secret
sudo restorecon -Rv /data/gitlab/gitlab-rails/
sudo semanage fcontext --list | grep /data/gitlab/
```

ポリシーを適用した後、ウェルカムメッセージを取得することでSSHアクセスが機能していることを確認できます:

```shell
ssh -T git@gitlab-hostname
```

### すべてのシステム {#all-systems}

Gitユーザーはデフォルトで、/etc/shadowにおいて`'!'`で示されるロックされたパスワードで作成されます。「UsePam yes」が有効でない限り、OpenSSHデーモンは、SSHキーを使用した場合でもGitユーザーの認証を拒否します。別の安全な解決策は、`/etc/shadow`で`'!'`を`'*'`に置き換えて、パスワードのロックを解除することです。Gitユーザーは制限付きShellで実行されており、スーパーユーザー以外の`passwd`コマンドでは新しいパスワードの前に現在のパスワードを入力する必要があるため、依然としてパスワードを変更できません。ユーザーは`'*'`に一致するパスワードを入力できないため、このアカウントは引き続きパスワードを持たない状態が維持されます。

Gitユーザーはシステムにアクセスできる必要があるため、`/etc/security/access.conf`のセキュリティ設定を確認し、Gitユーザーがブロックされていないことを確認してください。

## エラー: `FATAL: could not create shared memory segment: Cannot allocate memory` {#error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory}

パッケージ版PostgreSQLインスタンスは、総メモリの25％を共有メモリとして割り当てようとします。一部のLinux（仮想）サーバーでは、利用可能な共有メモリがこれよりも少ないため、PostgreSQLが起動できないことがあります。`/var/log/gitlab/postgresql/current`の設定:

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

`/etc/gitlab/gitlab.rb`で、PostgreSQLが割り当てようとする共有メモリの量を手動で減らすことができます:

```ruby
postgresql['shared_buffers'] = "100MB"
```

変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied` {#error-fatal-could-not-open-shared-memory-segment-postgresqlxxxxxxxxxx-permission-denied}

デフォルトでは、PostgreSQLは使用する共有メモリの種類を検出します。共有メモリが有効になっていない場合、`/var/log/gitlab/postgresql/current`にこのエラーが表示されることがあります。これを修正するには、PostgreSQLの共有メモリ検出を無効にします。`/etc/gitlab/gitlab.rb`に次の値を設定します:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: remaining connection slots are reserved for non-replication superuser connections` {#error-fatal-remaining-connection-slots-are-reserved-for-non-replication-superuser-connections}

PostgreSQLには、データベースサーバーへの同時接続の最大数に関する設定があります。デフォルトの制限は400です。このエラーが表示された場合、GitLabインスタンスがこの同時接続数の制限を超えようとしていることを意味します。

最大接続数と利用可能な接続数を確認するには:

1. PostgreSQLデータベースコンソールを開きます:

   ```shell
   sudo gitlab-psql
   ```

1. データベースコンソールで次のクエリを実行します:

   ```sql
   SELECT
     (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
     COUNT(*) AS current_connections,
     COUNT(*) FILTER (WHERE state = 'active') AS active_connections,
     ((SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - COUNT(*)) AS remaining_connections
   FROM pg_stat_activity;
   ```

この問題を修正する方法は2つあります:

- 1つは、最大接続数の値を増やす方法です:

  1. `/etc/gitlab/gitlab.rb`を編集します:

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. GitLabを再起動します:

     ```shell
     sudo gitlab-ctl restart
     ```

- または、PostgreSQLのコネクションプーラーである[PgBouncerの使用](https://docs.gitlab.com/administration/postgresql/pgbouncer/)を検討してください。

## 再設定でGLIBCバージョンに関するエラーが表示される {#reconfigure-complains-about-the-glibc-version}

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

これは、インストールしたLinuxパッケージが、サーバー上のOSリリースとは異なるリリース向けにビルドされている場合に発生することがあります。お使いのオペレーティングシステムに適したLinuxパッケージをダウンロードしてインストールしたことを再確認してください。

## 再設定でGitユーザーの作成に失敗する {#reconfigure-fails-to-create-the-git-user}

これは、Gitユーザーとして`sudo gitlab-ctl reconfigure`を実行した場合に発生することがあります。別のユーザーに切り替えてください。

さらに重要な点として、GitユーザーやLinuxパッケージで使用されるその他のユーザーにsudo権限を付与しないでください。システムユーザーに不必要な権限を付与すると、システムのセキュリティが低下します。

## sysctlでカーネルパラメータを変更できない {#failed-to-modify-kernel-parameters-with-sysctl}

sysctlでカーネルパラメータを変更できない場合は、次のスタックトレースを伴うエラーが表示されることがあります:

```plaintext
 * execute[sysctl] action run
================================================================================
Error executing action `run` on resource 'execute[sysctl]'
================================================================================


Mixlib::ShellOut::ShellCommandFailed
------------------------------------
Expected process to exit with [0], but received '255'
---- Begin output of /sbin/sysctl -p /etc/sysctl.conf ----
```

これは非仮想マシンでは発生しにくいですが、openVZのような仮想化技術を使用したVPSでは、コンテナに必要なモジュールが有効になっていないか、コンテナがカーネルパラメータにアクセスできない可能性があります。

sysctlでエラーが報告された対象の[モジュールを有効](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error)にしてみてください。

[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361)で、失敗を無視するスイッチを指定してGitLab内部のレシピを編集する回避策が報告されています。失敗を無視すると、GitLabサーバーのパフォーマンスに予期しない副次効果が生じる可能性があるため、この方法はおすすめしません。

このエラーの別のパターンとして、ファイルシステムが読み取り専用であることを示し、次のスタックトレースが表示される場合があります:

```plaintext
 * execute[load sysctl conf] action run
    [execute] sysctl: setting key "kernel.shmall": Read-only file system
              sysctl: setting key "kernel.shmmax": Read-only file system

    ================================================================================
    Error executing action `run` on resource 'execute[load sysctl conf]'
    ================================================================================

    Mixlib::ShellOut::ShellCommandFailed
    ------------------------------------
    Expected process to exit with [0], but received '255'
    ---- Begin output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    STDOUT:
    STDERR: sysctl: setting key "kernel.shmall": Read-only file system
    sysctl: setting key "kernel.shmmax": Read-only file system
    ---- End output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    Ran cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - returned 255
```

このエラーも仮想マシンでのみ発生すると報告されており、推奨される回避策はホストで値を設定することです。GitLabに必要な値は、仮想マシンの`/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf`ファイルで確認できます。ホストOSの`/etc/sysctl.conf`ファイルにこれらの値を設定した後、ホストで`cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -`を実行します。次に、仮想マシン内で`gitlab-ctl reconfigure`を実行してみてください。これにより、カーネルが必要な設定ですでに動作していることが検出され、エラーは発生しないはずです。

他の行についてもこのプロセスを繰り返す必要がある場合があります。たとえば、`/etc/sysctl.conf`に次のような設定を追加した後、再設定が3回失敗する場合などです:

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

ファイルを探すよりも、Chef出力の行を確認した方が簡単かもしれません（エラーごとにファイルが異なるため）。次のスニペットの最後の行を参照してください。

```plaintext
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf 2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj 2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

## ルートアクセスなしではGitLabをインストールできない {#i-am-unable-to-install-gitlab-without-root-access}

ルートアクセスなしでGitLabをインストールできるか、という質問を受けることがあります。これにはいくつかの理由で問題があります。

### `.deb`または`.rpm`のインストール {#installing-the-deb-or-rpm}

当社の知る限り、権限のないユーザーとしてDebianまたはRPMパッケージをクリーンにインストールする方法はありません。また、ビルドプロセスでソースRPMが作成されないため、LinuxパッケージのRPMをインストールできません。

### ポート`80`および`443`での手間のかからないホスティング {#hassle-free-hosting-on-port-80-and-443}

GitLabをデプロイする最も一般的な方法は、Webサーバー（NGINX/Apache）をGitLabと同じサーバー上で実行し、Webサーバーが特権TCPポート（1024未満）でリッスンする構成にすることです。Linuxパッケージでは、自動的に設定されたNGINXサービスをバンドルすることで、この利便性を実現しています。このサービスは、ポート`80`および`443`を開くために、ルートとしてマスタープロセスを実行する必要があります。

これが問題となる場合、GitLabをインストールする管理者はバンドルされたNGINXサービスを無効にすることができます。ただしその場合、アプリケーションの更新中もNGINXの設定をGitLabと適合した状態に保つという責任が管理者に生じます。

### サービス間の分離 {#isolation-between-services}

Linuxパッケージ内のバンドルされたサービス（GitLab自体、NGINX、PostgreSQL、Redis）は、Unixユーザーアカウントを使用して相互に分離されています。これらのユーザーアカウントの作成と管理には、ルートアクセスが必要です。デフォルトでは、Linuxパッケージは`gitlab-ctl reconfigure`の実行中に必要なUnixアカウントを作成しますが、その動作は[無効に](settings/configuration.md#disable-user-and-group-account-management)できます。

### パフォーマンス向上のためにオペレーティングシステムを微調整する {#tweaking-the-operating-system-for-better-performance}

`gitlab-ctl reconfigure`の実行中に、PostgreSQLのパフォーマンスを向上させ、接続制限を引き上げるために、いくつかのsysctl微調整を設定してインストールします。これは、ルートアクセスでのみ実行できます。

## `gitlab-rake assets:precompile`が`Permission denied`で失敗する {#gitlab-rake-assetsprecompile-fails-with-permission-denied}

`gitlab-rake assets:precompile`を実行してもLinuxパッケージでは動作しないという報告があります。これに対する簡潔な答えは次のとおりです。そのコマンドは実行しないでください。これはソースからインストールしたGitLabのみを対象としています。

GitLab WebインターフェースはCSSファイルとJavaScriptファイルを使用しており、Ruby on Railsではこれらを「アセット」と呼びます。[アップストリームGitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets)では、これらのファイルはデベロッパーにとって扱いやすい形式、つまり読みやすく編集しやすい形式で保存されています。ただし、通常のGitLabユーザーにとっては、このデベロッパーにとって扱いやすい形式のままではGitLabの速度が低下するため、望ましくありません。そのため、GitLabのセットアッププロセスの一環として、アセットをデベロッパーにとって扱いやすい形式から、エンドユーザーにとって扱いやすい（コンパクトで高速な）形式に変換します。それが`rake assets:precompile`スクリプトの目的です。

GitLabをソースからインストールする場合（Linuxパッケージが登場する前はこれが唯一の方法でした）、GitLabを更新するたびにGitLabサーバー上のアセットを変換する必要があります。以前はこの手順を見落とす人が多く、今でもインターネット上には、ユーザー同士が`rake assets:precompile`（現在は`gitlab:assets:compile`に名前が変更されました）を実行することを推奨し合う投稿、コメント、メールが残っています。Linuxパッケージでは事情が異なります。パッケージをビルドする際に、[当社がアセットをコンパイルしている](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74)からです。LinuxパッケージでGitLabをインストールすると、変換済みのアセットはすでに存在しています。そのため、パッケージからGitLabをインストールする際に`rake assets:precompile`を実行する必要はありません。

`gitlab-rake assets:precompile`が権限エラーで失敗するのは、セキュリティの観点から見て正当な理由があります。アセットが簡単に書き換えられないことで、攻撃者がユーザーのGitLabサーバーを使用して、そのGitLabサーバーの訪問者に悪意のあるJavaScriptコードを配信することが難しくなるからです。

カスタムJavaScriptまたはCSSコードを使用してGitLabを実行する場合は、ソースからGitLabを実行するか、独自のパッケージをビルドする方が適しています。

自分が何をしているかを本当に理解している場合は、次のように`gitlab-rake gitlab:assets:compile`を実行できます:

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## エラー: `Short read or OOM loading DB` {#error-short-read-or-oom-loading-db}

[古いRedisセッションをクリーンアップ](https://docs.gitlab.com/administration/operations/)してみてください。

## エラー: `The requested URL returned error: 403` {#error-the-requested-url-returned-error-403}

aptリポジトリを使用してGitLabをインストールしようとした際に、次のようなエラーが発生した場合:

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

`apt-cacher-ng`などのリポジトリキャッシャーがサーバーの前段にないかを確認します。

次の行をapt-cacher-ngの設定に追加します（例: `/etc/apt-cacher-ng/acng.conf`）:

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

このパススルールールが必要な理由と設定方法の詳細については、HTTPS/TLSリポジトリの`apt-cacher-ng`ドキュメントを参照してください。

## apt-mirrorを使用して複数のディストリビューション向けにパッケージをミラーリングすると失敗する {#mirroring-packages-for-multiple-distributions-using-apt-mirror-fails}

GitLab CEとGitLab EEのdebパッケージは、ディストリビューション間で同じバージョン文字列を共有していますが、内容は異なります。Debianリポジトリ形式では、これらは[重複パッケージ](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages)として扱われます。そのため、1つのdebリポジトリで複数のディストリビューションを安全に配信することはできません。その理由は、あるディストリビューションのパッケージメタデータが別のディストリビューションのものを上書きする可能性があるからです。

各ディストリビューションは専用のパスで公開しています。ただし、`https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>` URLへのリクエストは、ホストが使用しているディストリビューションに応じて正しいディストリビューションURLである`https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>/<distribution>`にリダイレクトするよう設定されています。このため、ユーザーは異なるディストリビューションでも同じURLを使い続けることができます。

しかし、この方法は、`apt-mirror`のようなミラーリングツールを使用して同じホストから複数のディストリビューションをミラーリングする場合には機能しません。そのため、誤ったディストリビューションのメタデータやパッケージをフェッチする可能性があります。

URLパスにディストリビューションを追加して、明示的に指定してください。たとえば、Jammyの場合は次のようになります:

```plaintext
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-ee/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-fips/ubuntu/jammy jammy main
```

この形式では、主な場所は次のとおりです:

- `InRelease`は`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/InRelease`にあります。
- `Packages.gz`は`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/main/binary-amd64/Packages.gz`にあります。
- パッケージファイルは`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/pool/main/g/gitlab-ce/gitlab-ce_18.5.0-ce.0_amd64.deb`にあります。

### `gitlab-runner` {#gitlab-runner}

`gitlab-runner`パッケージの設定は、同じパッケージが複数のディストリビューションで使用されるため、異なります。URLは`https://packages.gitlab.com/runner/gitlab-runner`のままでかまいません。

## 自己署名証明書またはカスタム認証局を使用する {#using-self-signed-certificate-or-custom-certificate-authorities}

カスタム認証局を使用した隔離ネットワーク内でGitLabをインストールする場合、または自己署名証明書を使用する場合は、その証明書にGitLabから到達できることを確認してください。そうしないと、次のようなエラーが発生します:

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

これは、GitLabがGitLab Shellのような内部サービスに接続しようとしたときに発生します。

これらのエラーを修正するには、[カスタム公開証明書をインストールする](settings/ssl/_index.md#install-custom-public-certificates)セクションを参照してください。

## エラー: `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"` {#error-proxyroundtripper-xxx-failed-with-nethttp-timeout-awaiting-response-headers}

GitLab Workhorseが1分以内（デフォルト）にGitLabから応答を受信しない場合、502ページを返します。

このリクエストがタイムアウトになる理由はいくつか考えられます。たとえば、ユーザーが非常に大きな差分を読み込んでいた可能性があります。

デフォルトのタイムアウト値を大きくするには、`/etc/gitlab/gitlab.rb`で値を設定します:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

ファイルを保存し、変更を反映するために[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。

## The change you wanted was rejected {#the-change-you-wanted-was-rejected}

ほとんどの場合、GitLabの前段にプロキシがあり、パッケージでデフォルトで設定されているプロキシヘッダーがその環境に適していません。

デフォルトヘッダーをオーバーライドする方法の詳細については、[NGINXドキュメントのデフォルトプロキシヘッダーを変更するセクション](settings/nginx.md#change-the-default-proxy-headers)を参照してください。

## Can't verify CSRF token authenticity Completed 422 Unprocessable {#cant-verify-csrf-token-authenticity-completed-422-unprocessable}

ほとんどの場合、GitLabの前段にプロキシがあり、パッケージでデフォルトで設定されているプロキシヘッダーがその環境に適していません。

デフォルトヘッダーをオーバーライドする方法の詳細については、[NGINXドキュメントのデフォルトプロキシヘッダーを変更するセクション](settings/nginx.md#change-the-default-proxy-headers)を参照してください。

## `pg_trgm`拡張機能がない {#extension-missing-pg_trgm}

GitLabにはPostgreSQL拡張機能`pg_trgm`が[必要](https://docs.gitlab.com/install/postgresql_extensions/)です。バンドルされたデータベースを含むLinuxパッケージを使用している場合、アップグレード時にこの拡張機能が自動的に有効になります。

ただし、外部（パッケージ版ではない）データベースを使用している場合は、この拡張機能を手動で有効にする必要があります。その理由は、外部データベースを使用するLinuxパッケージインスタンスには、その拡張機能が存在するかを確認する方法がなく、また拡張機能を有効にする手段もないためです。

この問題を修正するには、まず`pg_trgm`拡張機能をインストールする必要があります。この拡張機能は`postgresql-contrib`パッケージに含まれています。Debianの場合は次のとおりです:

```shell
sudo apt-get install postgresql-contrib
```

拡張機能をインストールしたら、スーパーユーザーとして`psql`にアクセスして拡張機能を有効にします。

1. スーパーユーザーとして`psql`にアクセスします:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. 拡張機能を有効にします:

   ```plaintext
   CREATE EXTENSION pg_trgm;
   \q
   ```

1. 次に、移行を再度実行します:

   ```shell
   sudo gitlab-rake db:migrate
   ```

---

Dockerを使用している場合は、まずコンテナにアクセスし、次に上記のコマンドを実行して、最後にコンテナを再起動する必要があります。

1. コンテナにアクセスします:

   ```shell
   docker exec -it gitlab bash
   ```

1. 上記のコマンドを実行します。
1. コンテナを再起動します。

   ```shell
   docker restart gitlab
   ```

## エラー: `Errno::ENOMEM: Cannot allocate memory during backup or upgrade` {#error-errnoenomem-cannot-allocate-memory-during-backup-or-upgrade}

エラーを発生させることなく実行するために[GitLabに必要](https://docs.gitlab.com/install/requirements/#memory)なメモリ量は2 GBです。2 GBのメモリが搭載されていても、サーバー上の他のプロセスのリソース使用状況によっては十分でない可能性があります。アップグレードやバックアップの実行時以外ではGitLabが正常に動作している場合、スワップを増やせば問題は解決するはずです。通常使用時にもサーバーがスワップを使用している場合は、RAMを増設するとパフォーマンスを向上させることができます。

## NGINXエラー: `could not build server_names_hash, you should increase server_names_hash_bucket_size` {#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size}

GitLabの外部URLがデフォルトのバケットサイズ（64バイト）よりも長い場合、NGINXが動作を停止し、ログにこのエラーを表示することがあります。より長いサーバー名を許可するには、`/etc/gitlab/gitlab.rb`のバケットサイズを2倍にします:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

変更を反映するため、`sudo gitlab-ctl reconfigure`を実行します。

## NFS root_squashにより`'root' cannot chown`で再設定に失敗する {#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash}

```shell
$ gitlab-ctl reconfigure

================================================================================
Error executing action `run` on resource 'ruby_block[directory resource: /gitlab-data/git-data]'
================================================================================

Errno::EPERM
------------
'root' cannot chown /gitlab-data/git-data. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.
Operation not permitted @ chown_internal - /gitlab-data/git-data
```

これは、NFSを使用してディレクトリをマウントし、`root_squash`モードで設定した場合に発生する可能性があります。再設定では、ディレクトリの所有権を適切に設定できません。NFSサーバーのNFSエクスポートで`no_root_squash`を使用するように切り替えるか、[ストレージディレクトリの管理を無効](settings/configuration.md#disable-storage-directories-management)にして自分で権限を管理する必要があります。

## `gitlab-runsvdir`が起動しない {#gitlab-runsvdir-not-starting}

これは、systemdを使用するオペレーティングシステム（例: Ubuntu 18.04以降、CentOSなど）に適用されます。

`gitlab-runsvdir`は、`basic.target`ではなく`multi-user.target`の間に起動します。GitLabのアップグレード後、このサービスの起動で問題が発生した場合は、次のコマンドを使用して、システムが`multi-user.target`に必要なすべてのサービスを正常に起動したかを確認する必要がある場合があります:

```shell
systemctl -t target
```

すべてが正常に動作している場合、出力は次のようになります:

```plaintext
UNIT                   LOAD   ACTIVE SUB    DESCRIPTION
basic.target           loaded active active Basic System
cloud-config.target    loaded active active Cloud-config availability
cloud-init.target      loaded active active Cloud-init target
cryptsetup.target      loaded active active Encrypted Volumes
getty.target           loaded active active Login Prompts
graphical.target       loaded active active Graphical Interface
local-fs-pre.target    loaded active active Local File Systems (Pre)
local-fs.target        loaded active active Local File Systems
multi-user.target      loaded active active Multi-User System
network-online.target  loaded active active Network is Online
network-pre.target     loaded active active Network (Pre)
network.target         loaded active active Network
nss-user-lookup.target loaded active active User and Group Name Lookups
paths.target           loaded active active Paths
remote-fs-pre.target   loaded active active Remote File Systems (Pre)
remote-fs.target       loaded active active Remote File Systems
slices.target          loaded active active Slices
sockets.target         loaded active active Sockets
swap.target            loaded active active Swap
sysinit.target         loaded active active System Initialization
time-sync.target       loaded active active System Time Synchronized
timers.target          loaded active active Timers

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

22 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
```

すべての行に`loaded active active`と表示されるはずです。以下の行のように`inactive dead`と表示される場合は、何らかの問題が発生している可能性があります:

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

systemdによってどのジョブがキューに入れられているかを調べるには、次を実行します:

```shell
systemctl list-jobs
```

`running`ジョブが表示された場合、あるサービスがスタックしており、GitLabの起動を妨げている可能性があります。たとえば、一部のユーザーはPlymouthが起動しないという問題を経験しています。

```plaintext
  1 graphical.target                     start waiting
107 plymouth-quit-wait.service           start running
  2 multi-user.target                    start waiting
169 ureadahead-stop.timer                start waiting
121 gitlab-runsvdir.service              start waiting
151 system-getty.slice                   start waiting
 31 setvtrgb.service                     start waiting
122 systemd-update-utmp-runlevel.service start waiting
```

この場合、Plymouthのアンインストールを検討してください。

## 非DockerコンテナでのInitデーモンの検出 {#init-daemon-detection-in-non-docker-container}

Dockerコンテナでは、GitLabパッケージは`/.dockerenv`ファイルの存在を検出し、initシステムの自動検出をスキップします。ただし、非Dockerコンテナ（containerd、cri-oなど）ではそのファイルが存在せず、パッケージはsysvinitにフォールバックするため、インストールで問題が発生する可能性があります。これを回避するには、`gitlab.rb`ファイルに次の設定を追加して、initデーモンの検出を明示的に無効にします:

```ruby
package['detect_init'] = false
```

この設定を使用する場合、`gitlab-ctl reconfigure`を実行する前に、`runsvdir-start`コマンドを使用してrunitサービスを開始しておく必要があります:

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## AWS Cloudformationの使用中に`gitlab-ctl reconfigure`がハングする {#gitlab-ctl-reconfigure-hangs-while-using-aws-cloudformation}

GitLab systemdユニットファイルは、デフォルトで`After`フィールドと`WantedBy`フィールドの両方に`multi-user.target`を使用します。これは、サービスが`remote-fs`ターゲットおよび`network`ターゲットの後に実行されることを保証するためです。その結果、GitLabが適切に機能します。

ただし、これは、AWS CloudFormationで使用される[cloud-init](https://docs.cloud-init.io/en/latest/)独自のユニット順序とうまくかみ合いません。

これを修正するには、`gitlab.rb`の`package['systemd_wanted_by']`設定と`package['systemd_after']`設定を利用して、適切な順序付けに必要な値を指定し、`sudo gitlab-ctl reconfigure`を実行できます。再設定が完了したら、変更を反映するために`gitlab-runsvdir`サービスを再起動します。

```shell
sudo systemctl restart gitlab-runsvdir
```

## エラー: `Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)` {#error-errnoeafnosupport-address-family-not-supported-by-protocol---socket2}

GitLabの起動時に、次のようなエラーが見られる場合:

```ruby
FATAL: Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)
```

使用中のホスト名が解決可能であり、**IPv4**アドレスが返されるかどうかを確認します:

```shell
getent hosts gitlab.example.com
# Example IPv4 output: 192.168.1.1 gitlab.example.com
# Example IPv6 output: 2002:c0a8:0101::c0a8:0101 gitlab.example.com

getent hosts localhost
# Example IPv4 output: 127.0.0.1 localhost
# Example IPv6 output: ::1 localhost
```

**IPv6**アドレス形式が返された場合は、さらにネットワークインターフェースで**IPv6**プロトコルのサポート（キーワード`ipv6`）が有効になっているかを確認します:

```shell
ip addr # or 'ifconfig' on older operating systems
```

**IPv6**ネットワークプロトコルのサポートがないか無効になっているが、DNS設定がホスト名を**IPv6**アドレスとして解決する場合、GitLabサービスはネットワーク接続を確立できません。

この問題は、DNS設定（または`/etc/hosts`）を修正し、ホストを**IPv6**アドレスではなく**IPv4**アドレスに解決するように設定することで解決できます。

## エラー: `external_url`にアンダースコアが含まれている場合の`... bad component(expected host component: my_url.tld)` {#error--bad-componentexpected-host-component-my_urltld-when-external_url-contains-underscores}

`external_url`にアンダースコア（たとえば、`https://my_company.example.com`）を設定した場合、CI/CDで次のような問題が発生することがあります:

- プロジェクトの**設定 > CI/CD**ページを開くことができなくなる。
- Runnerがジョブを選択せず、エラー500で失敗する。

この場合は、[`production.log`](https://docs.gitlab.com/administration/logs/#productionlog)に次のエラーが含まれます:

```plaintext
Completed 500 Internal Server Error in 50ms (ActiveRecord: 4.9ms | Elasticsearch: 0.0ms | Allocations: 17672)

URI::InvalidComponentError (bad component(expected host component): my_url.tld):

lib/api/helpers/related_resources_helpers.rb:29:in `expose_url'
ee/app/controllers/ee/projects/settings/ci_cd_controller.rb:19:in `show'
ee/lib/gitlab/ip_address_state.rb:10:in `with'
ee/app/controllers/ee/application_controller.rb:44:in `set_current_ip_address'
app/controllers/application_controller.rb:486:in `set_current_admin'
lib/gitlab/session.rb:11:in `with_session'
app/controllers/application_controller.rb:477:in `set_session_storage'
lib/gitlab/i18n.rb:73:in `with_locale'
lib/gitlab/i18n.rb:79:in `with_user_locale'
```

回避策として、`external_url`ではアンダースコアの使用を避けてください。これに関連する未解決のイシューがあります: [Setting `external_url` with underscore results in a broken GitLab CI/CD functionality](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077).

## `timeout: run: /opt/gitlab/service/gitaly`エラーでアップグレードに失敗する {#upgrade-fails-with-timeout-run-optgitlabservicegitaly-error}

再設定の実行時に次のエラーが発生してパッケージのアップグレードが失敗した場合は、すべてのGitalyプロセスが停止していることを確認してから、`sudo gitlab-ctl reconfigure`を再実行します。

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

詳細については、[イシュー341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573)を参照してください。

## GitLabの再インストール時に再設定がスタックする {#reconfigure-is-stuck-when-re-installing-gitlab}

[既知の問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)により、GitLabをアンインストールしてから再インストールしようとすると、再設定プロセスが`ruby_block[wait for logrotate service socket] action run`でスタックすることがあります。この問題は、[GitLabをアンインストール](https://docs.gitlab.com/install/package/#uninstall-the-linux-package)する際に`systemctl`コマンドのいずれかが実行されなかった場合に発生します。

この問題を解決するには:

- GitLabをアンインストールする際にすべての手順に従ったことを確認し、必要に応じて手順を実行してください。
- [イシュー7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)の回避策に従ってください。

## PulpまたはRed Hat SatelliteでGitLabの`yum`リポジトリをミラーリングすると失敗する {#mirroring-the-gitlab-yum-repository-with-pulp-or-red-hat-satellite-fails}

<https://packages.gitlab.com/gitlab/>にあるLinuxパッケージの`yum`リポジトリを、[Pulp](https://pulpproject.org/)または[Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite)を使用して直接ミラーリングしようとすると、同期時に失敗します。ソフトウェアによって発生するエラーが異なります:

- Pulp 2またはSatellite 6.10未満は、`"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"`エラーで失敗します。
- Satellite 6.10は、`"pkgid"`エラーで失敗します。
- Pulp 3またはSatellite 6.10より新しいバージョンは成功したように見えますが、リポジトリのメタデータのみが同期されます。

これらの同期の失敗は、GitLab `yum`ミラーリポジトリ内のメタデータに関する問題が原因です。このメタデータには`filelists.xml.gz`ファイルが含まれており、通常はリポジトリ内のすべてのRPMのファイルリストが含まれます。GitLab `yum`リポジトリでは、このファイルを完全に生成した場合に発生するサイズの問題を回避するために、このファイルをほぼ空の状態にしています。

各GitLab RPMには膨大な数のファイルが含まれており、これにリポジトリ内に多数存在するRPMを掛けると、完全に生成した場合、`filelists.xml.gz`ファイルは非常に巨大になります。ストレージとビルドの制約のため、ファイル自体は作成しますが内容は入力しません。この空のファイルが原因で、PulpおよびRedHat Satellite（Pulpを使用）によるこのファイルのリポジトリのミラーリングに失敗します。

詳細については、[イシュー2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766)を参照してください。

### 問題を回避する {#work-around-the-issue}

この問題を回避するには:

1. `reposync`や`createrepo`などの代替RPMリポジトリミラーリングツールを使用して、公式のGitLab `yum`リポジトリのローカルコピーを作成します。これらのツールはローカルデータ内のリポジトリメタデータを再作成し、その際`filelists.xml.gz`ファイルも完全に生成します。
1. PulpまたはSatelliteの参照先をそのローカルミラーにしてください。

### ローカルミラーの例 {#local-mirror-example}

次に、ローカルミラーリングを実行する方法の例を示します。この例では、以下を使用します:

- リポジトリのWebサーバーとして[Apache](https://httpd.apache.org/)。
- GitLabリポジトリをローカルミラーに同期するための[`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html)および[`createrepo`](http://createrepo.baseurl.org/)。このローカルミラーは、PulpまたはRedHat Satelliteのソースとして使用できます。[Cobbler](https://cobbler.github.io/)などの他のツールも使用できます。

この例では: 

- ローカルミラーは、`RHEL 8`、`Rocky 8`、または`AlmaLinux 8`システムで動作しています。
- Webサーバーに使用するホスト名は`mirror.example.com`です。
- Pulp 3は、ローカルミラーから同期します。
- [GitLab Enterprise Editionリポジトリ](https://packages.gitlab.com/gitlab/gitlab-ee/)をミラーリングします。

#### Apacheサーバーを作成して設定する {#create-and-configure-an-apache-server}

次の例は、1つ以上のYumリポジトリミラーをホストするために、基本的なApache 2サーバーをインストールしてから設定する方法を示しています。Webサーバーの設定とセキュリティ保護の詳細については、[Apache](https://httpd.apache.org/)ドキュメントを参照してください。

1. `httpd`をインストールします:

   ```shell
   sudo dnf install httpd
   ```

1. `/etc/httpd/conf/httpd.conf`に`Directory`セクションを追加します:

   ```apache
   <Directory "/var/www/html/repos">
   Options All Indexes FollowSymLinks
   Require all granted
   </Directory>
   ```

1. `httpd`設定を完了します:

   ```shell
   sudo rm -f /etc/httpd/conf.d/welcome.conf
   sudo mkdir /var/www/html/repos
   sudo systemctl enable httpd --now
   ```

#### ミラーリングされたYumリポジトリURLを取得する {#get-the-mirrored-yum-repository-url}

1. GitLabリポジトリの`yum`設定ファイルをインストールします:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   sudo dnf config-manager --disable gitlab_gitlab-ee gitlab_gitlab-ee-source
   ```

1. リポジトリURLを取得します:

   ```shell
   sudo dnf config-manager --dump gitlab_gitlab-ee | grep baseurl
   baseurl = https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64
   ```

   `baseurl`の内容をローカルミラーのソースとして使用します。例: `https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64`。

#### ローカルミラーを作成する {#create-the-local-mirror}

1. `createrepo`パッケージをインストールします:

   ```shell
   sudo dnf install createrepo
   ```

1. `reposync`を実行して、RPMをローカルミラーにコピーします:

   ```shell
   sudo dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only
   ```

   `--newest-only`オプションは、最新のRPMのみをダウンロードします。このオプションを省略すると、リポジトリ内のすべてのRPM（それぞれ約1 GB）がダウンロードされます。

1. `createrepo`を実行して、リポジトリメタデータを再作成します:

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

これで、ローカルミラーリポジトリは、<http://mirror.example.com/repos/gitlab_gitlab-ee/>で利用可能になるはずです。

#### ローカルミラーを更新する {#update-the-local-mirror}

新しいGitLabバージョンがリリースされたときに新しいRPMを取得できるよう、ローカルミラーは定期的に更新する必要があります。これを行う方法の1つは、`cron`を使用することです。

次の内容で`/etc/cron.daily/sync-gitlab-mirror`を作成します:

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

`dnf reposync`コマンドで使用している`--delete`オプションは、対応するGitLabリポジトリに存在しなくなったRPMをローカルミラーから削除します。

#### ローカルミラーを使用する {#using-the-local-mirror}

1. Pulp `repository`と`remote`を作成します:

   ```shell
   pulp rpm repository create --retain-package-versions=1 --name "gitlab-ee"
   pulp rpm remote create --name gitlab-ee --url "http://mirror.example.com/repos/gitlab_gitlab-ee/" --policy immediate
   pulp rpm repository update --name gitlab-ee --remote gitlab-ee
   ```

1. リポジトリを同期します:

   ```shell
   pulp rpm repository sync --name gitlab-ee
   ```

   このコマンドは、GitLabリポジトリの変更をローカルミラーに反映するために、定期的に実行する必要があります。

リポジトリの同期後、公開と配信を作成して利用可能にできます。詳細については、<https://pulpproject.org/pulp_rpm/>を参照してください。

## エラー: `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443` {#error-e-connection-refused-to-d20rj4el6vkp4ccloudfrontnet-443}

`packages.gitlab.com`にあるパッケージリポジトリでホストされているパッケージをインストールする際、クライアントはCloudFrontアドレス`d20rj4el6vkp4c.cloudfront.net`へのリダイレクトを受信し、それに従います。エアギャップ環境のサーバーでは、次のエラーが発生することがあります:

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

この問題を解決するには、3つのオプションがあります:

- ドメイン単位で許可リストに登録できる場合は、エンドポイント`d20rj4el6vkp4c.cloudfront.net`をファイアウォール設定に追加します。
- ドメイン単位で許可リストに登録できない場合は、[CloudFront IPアドレス範囲](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips)をファイアウォール設定に追加します。このリストは変更される可能性があるため、ファイアウォール設定と同期した状態を常に維持する必要があります。
- パッケージファイルをパッケージを手動でダウンロードして、サーバーにアップロードします。

## パッケージストレージ操作時のエラー: `503 Service Unavailable` {#error-503-service-unavailable-for-package-storage-operations}

一部のパッケージストレージコンポーネントは、Google Cloud Storage（GCS）を介して提供されます。これらのコンポーネントは、パブリックAPTリポジトリエンドポイントに加えて、GCSエンドポイントへの送信HTTPSアクセスを必要とします。`apt update`が`503 Service Unavailable`エラーで失敗した場合、`storage.googleapis.com/packages-ops`へのアクセスがブロックされています。

このエラーを解決するには、ファイアウォールルールで、次のエンドポイントへの送信HTTPS（ポート`443`）接続が許可されていることを確認してください:

- `packages.gitlab.com`
- `storage.googleapis.com`
- Google Cloud Storageの`packages-ops`バケット

## `net.core.somaxconn`が低すぎないか確認する {#check-if-netcoresomaxconn-is-set-too-low}

`net.core.somaxconn`の値が低すぎるかどうかを識別するには、以下が役立つ場合があります:

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

`netstat -ant | grep -c SYN_RECV`の戻り値は、確立待ちの接続数です。この値が`net.core.somaxconn`より大きい場合:

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

タイムアウトまたはHTTP 502エラーが発生する可能性があるため、`gitlab.rb`の`puma['somaxconn']`変数を更新して、この値を増やすことをおすすめします。

## エラー: `exec request failed on channel 0`または`shell request failed on channel 0` {#error-exec-request-failed-on-channel-0-or-shell-request-failed-on-channel-0}

Git over SSHを使用してプルまたはプッシュすると、次のエラーが表示される場合があります:

- `exec request failed on channel 0`
- `shell request failed on channel 0`

これらのエラーは、`git`ユーザーからのプロセス数が制限を超えている場合に発生する可能性があります。

この問題を解決するには:

1. `gitlab-shell`が実行されているノードの`/etc/security/limits.conf`ファイルで、`git`ユーザーの`nproc`設定を増やします。通常、`gitlab-shell`はGitLab Railsノードで実行されます。
1. プルまたはプッシュGitコマンドを再試行します。

## SSH接続切断後のインストールのハング {#hung-installation-after-ssh-connection-loss}

リモート仮想マシンにGitLabをインストール中にSSH接続が切断されると、ゾンビ`dpkg`プロセスによってインストールがハングすることがあります。インストールを再開するには:

1. `top`を実行して、関連付けられている`apt`プロセスのプロセスIDを見つけます。これは、`dpkg`プロセスの親です。
1. `sudo kill <PROCESS_ID>`を実行して、`apt`プロセスを強制終了します。
1. 新規インストールの場合にのみ、`sudo gitlab-ctl cleanse`を実行します。この手順は既存データを消去するため、アップグレードには使用しないでください。
1. `sudo dpkg configure -a`を実行します。
1. `gitlab.rb`ファイルを編集し、目的の外部URLと、不足している可能性のあるその他の設定を追加します。
1. `sudo gitlab-ctl reconfigure`を実行します。

## GitLabを再設定する際のRedis関連エラー {#redis-related-error-when-reconfiguring-gitlab}

GitLabを再設定する際に、次のエラーが発生することがあります:

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

このエラーメッセージは、`redis-cli`との接続を確立しようとしているときに、Redisが再起動またはシャットダウンされた可能性があることを示しています。レシピが`gitlab-ctl restart redis`を実行し、その直後にバージョン確認を試みるため、このエラーを引き起こす競合状態が発生する可能性があります。

この問題を解決するには、次のコマンドを実行します:

```shell
sudo gitlab-ctl reconfigure
```

それでも失敗する場合は、`gitlab-ctl tail redis`の出力を確認し、`redis-cli`を実行してみてください。
