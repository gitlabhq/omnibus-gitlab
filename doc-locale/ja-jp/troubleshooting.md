---
stage: GitLab Delivery
group: Build, Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージのインストールに関するトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、Linuxパッケージのインストール時にユーザーが遭遇する可能性のある一般的な問題について説明します。

## パッケージのダウンロード時のハッシュ合計の不一致 {#hash-sum-mismatch-when-downloading-packages}

`apt-get install`は次のようなものを出力します:

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

この問題を解決するには、以下を実行します:

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

詳細については、[Packagecloud commentのJoe Damato氏](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/628#note_1824330)と[彼のブログ記事](https://blog.packagecloud.io/apt-hash-sum-mismatch/)を参照してください。

別の回避策として、[CEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ce)または[EEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ee)リポジトリから正しいパッケージを手動で選択してダウンロードします:

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## openSUSEおよびSLESプラットフォームへのインストールで、不明なキー署名について警告が表示される {#installation-on-opensuse-and-sles-platforms-warns-about-unknown-key-signature}

Linuxパッケージは、パッケージリポジトリが署名付きメタデータを提供するだけでなく、[GPGキーで署名](update/package_signatures.md)されています。これにより、ユーザーに配布されるパッケージの信頼性と整合性が保証されます。ただし、openSUSEおよびSLESオペレーティングシステムで使用されているパッケージマネージャーでは、これらの署名に関する誤った警告が次のように表示される場合があります:

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

これは、zypperがリポジトリ設定ファイルの`gpgkey`キーワードを無視するという、zypperの既知のバグです。Packagecloudの新しいバージョンでは、これに関する改善が行われる可能性がありますが、現在、ユーザーは手動でパッケージのインストールに同意する必要があります。

したがって、openSUSEまたはSLESシステムでは、このような警告が表示された場合でも、インストールを続行しても安全です。

## apt/yumがGPG署名について文句を言う {#aptyum-complains-about-gpg-signatures}

すでにGitLabリポジトリが設定されていて、`apt-get update`、`apt-get install`、または`yum install`を実行し、次のようなエラーが表示された:

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

または

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

これは、2020年4月にGitLabが[Packagecloudインスタンス](https://packages.gitlab.com)から利用できるaptおよびyumリポジトリのメタデータへの署名に使用されるGPGキーを変更したためです。このエラーが表示された場合、通常は、キーリング内のリポジトリメタデータへの署名に現在使用されている公開キーがないことを意味します。このエラーを解決するには、[新しいキーを取得する手順](update/package_signatures.md#fetch-latest-signing-key)に従ってください。

## 再設定でエラーが表示される: `NoMethodError - undefined method '[]=' for nil:NilClass` {#reconfigure-shows-an-error-nomethoderror---undefined-method--for-nilnilclass}

`sudo gitlab-ctl reconfigure`を実行したか、パッケージのアップグレードによって再設定がトリガーされ、次のようなエラーが発生しました:

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

このエラーは、`/etc/gitlab/gitlab.rb`設定ファイルに無効またはサポートされていない設定が含まれている場合にスローされます。タイプミスがないか、設定ファイルに古い設定が含まれていないか再確認してください。

`sudo gitlab-ctl diff-config`を使用して利用可能な最新の設定を確認するか、最新の[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を確認できます。

## ブラウザーでGitLabにアクセスできない {#gitlab-is-unreachable-in-my-browser}

[指定](settings/configuration.md#configure-the-external-url-for-gitlab) `external_url`を`/etc/gitlab/gitlab.rb`で試してください。また、ファイアウォールの設定も確認してください。 GitLabサーバーでポート80 (HTTP) または443 (HTTPS) が閉じられている可能性があります。

GitLabまたはその他のバンドルされたサービス (レジストリおよびMattermost) に`external_url`を指定しても、`key=value`形式には従いません。 `gitlab.rb`の他の部分が従います。次の形式で設定されていることを確認してください:

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
mattermost_external_url "https://mattermost.example.com"
```

{{< alert type="note" >}}

`=`と値の間に等号 (`external_url`) を追加しないでください。

{{< /alert >}}

## メールが配信されていません {#emails-are-not-being-delivered}

メールの配信をテストするには、GitLabインスタンスでまだ使用されていないメールアドレスで新しいGitLabアカウントを作成します。

必要に応じて、`/etc/gitlab/gitlab.rb`の次の設定を使用して、GitLabから送信されるメールの「From」フィールドを変更できます:

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## GitLabサービスのTCPポートはすでに使用されています {#tcp-ports-for-gitlab-services-are-already-taken}

デフォルトでは、PumaはTCPアドレス127.0.0.1:8080でリッスンします。NGINXは、すべてのインターフェースでポート80 (HTTP) および443 (HTTPS) でリッスンします。

Redis、PostgreSQL、およびPumaのポートは、次のように`/etc/gitlab/gitlab.rb`でオーバーライドできます:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

NGINXポートの変更については、[NGINXリッスンポートの設定](settings/nginx.md#set-the-nginx-listen-port)を参照してください。

## GitユーザーにSSHアクセス権がない {#git-user-does-not-have-ssh-access}

### SELinuxが有効なシステム {#selinux-enabled-systems}

SELinuxが有効なシステムでは、Gitユーザーの`.ssh`ディレクトリまたはそのコンテンツのセキュリティコンテキストが混乱する可能性があります。これは、`sudo
gitlab-ctl reconfigure`を実行して修正できます。これにより、`/var/opt/gitlab/.ssh`に`gitlab_shell_t`セキュリティコンテキストが設定されます。

この動作を改善するために、`semanage`を使用してコンテキストを永続的に設定します。`policycoreutils-python`ランタイムの依存関係が、`semanage`コマンドが利用可能であることを保証するために、RHELベースのオペレーティングシステムのRPMパッケージに追加されました。

#### SELinuxの問題を診断して解決する {#diagnose-and-resolve-selinux-issues}

Linuxパッケージは、`/etc/gitlab/gitlab.rb`のデフォルトのパスの変更を検出し、正しいファイルコンテキストを適用する必要があります。

{{< alert type="note" >}}

GitLab 16.10以降、管理者は`gitlab-ctl apply-sepolicy`を試してSELinuxの問題を自動的に修正できます。実行時のオプションについては、`gitlab-ctl apply-sepolicy --help`を参照してください。

{{< /alert >}}

カスタムデータパス設定を使用するインストールの場合、管理者はSELinuxの問題をを手動で解決する必要がある場合があります。

データパスは`gitlab.rb`経由で変更できますが、一般的なシナリオでは`symlink`パスの使用が強制されます。管理者は注意する必要があります。 `symlink`パスは、[Gitalyデータパス](settings/configuration.md#store-git-data-in-an-alternative-directory)など、すべてのシナリオでサポートされているわけではないためです。

たとえば、`/data/gitlab`がベースデータディレクトリとして`/var/opt/gitlab`に置き換えられた場合、次の手順でセキュリティコンテキストを修正します:

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

ポリシーが適用されると、SSHアクセスが機能していることを、ウェルカムメッセージを取得することで確認できます:

```shell
ssh -T git@gitlab-hostname
```

### すべてのシステム {#all-systems}

Gitユーザーは、デフォルトで、/etc/shadowに`'!'`で示されるロックされたパスワードで作成されます。"UsePam yes" が有効になっていない限り、OpenSSHデーモンは、SSHキーがあっても、Gitユーザーの認証を妨げます。別の安全な解決策は、`/etc/shadow`で`'!'`を`'*'`に置き換えることで、パスワードのロックを解除することです。Gitユーザーは制限付きShellで実行され、非スーパーユーザー用の`passwd`コマンドは新しいパスワードの前に現在のパスワードの入力を必要とするため、パスワードを変更できません。ユーザーは`'*'`と一致するパスワードを入力できません。つまり、アカウントはパスワードを引き続き持っていません。

Gitユーザーはシステムにアクセスできる必要があることに注意してください。したがって、`/etc/security/access.conf`でセキュリティ設定を確認し、Gitユーザーがブロックされていないことを確認してください。

## エラー: `FATAL: could not create shared memory segment: Cannot allocate memory` {#error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory}

パッケージ化されたPostgreSQLインスタンスは、共有メモリーとして総メモリーの25% を割り当てようとします。一部のLinux (仮想) サーバーでは、利用可能な共有メモリーが少なく、PostgreSQLの起動が妨げられます。`/var/log/gitlab/postgresql/current`で:

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

`/etc/gitlab/gitlab.rb`でPostgreSQLが割り当てようとする共有メモリーの量を手動で減らすことができます:

```ruby
postgresql['shared_buffers'] = "100MB"
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied` {#error-fatal-could-not-open-shared-memory-segment-postgresqlxxxxxxxxxx-permission-denied}

デフォルトでは、PostgreSQLは使用する共有メモリーの種類を検出します。共有メモリーが有効になっていない場合は、`/var/log/gitlab/postgresql/current`にこのエラーが表示されることがあります。これを修正するには、PostgreSQLの共有メモリー検出を無効にすることができます。`/etc/gitlab/gitlab.rb`に次の値を設定します:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: remaining connection slots are reserved for non-replication superuser connections` {#error-fatal-remaining-connection-slots-are-reserved-for-non-replication-superuser-connections}

PostgreSQLには、データベースサーバーへの同時接続の最大数を設定する設定があります。デフォルトの制限は400です。このエラーが表示された場合、GitLabインスタンスが同時接続数に対するこの制限を超えようとしていることを意味します。

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

この問題を解決するには、2つのオプションがあります:

- または、最大接続の値を大きくします:

  1. `/etc/gitlab/gitlab.rb`を編集します: 

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. GitLabを再起動します。

     ```shell
     sudo gitlab-ctl restart
     ```

- または、PostgreSQLの接続である[PgBouncerの使用](https://docs.gitlab.com/administration/postgresql/pgbouncer/)を検討してください。

## 再設定でGLIBCバージョンについて文句を言う {#reconfigure-complains-about-the-glibc-version}

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

これは、インストールしたLinuxパッケージが、サーバー上のものとは異なるOSリリース用に構築された場合に発生する可能性があります。オペレーティングシステムに適したLinuxパッケージをダウンロードしてインストールしたことを再確認してください。

## 再設定でGitユーザーの作成に失敗する {#reconfigure-fails-to-create-the-git-user}

これは、Gitユーザーとして`sudo gitlab-ctl reconfigure`を実行した場合に発生する可能性があります。別のユーザーに切り替えます。

さらに重要なことは、Linuxパッケージで使用されているGitユーザーまたはその他のユーザーにsudo権限を与えないことです。システムユーザーに不必要な特権を与えると、システムのセキュリティが低下します。

## systemdによるカーネルパラメータの変更に失敗しました {#failed-to-modify-kernel-parameters-with-sysctl}

systemdがカーネルパラメータを変更できない場合は、次のスタックトレースでエラーが発生する可能性があります:

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

これは仮想化されていないマシンでは発生する可能性は低いですが、openVZのような仮想化を備えたVPSでは、コンテナに必要なモジュールが有効になっていないか、コンテナがカーネルパラメータにアクセスできない可能性があります。

systemdがエラーを出した[モジュールを有効にする](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error)を試してください。

[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361)に記載されている回避策があり、GitLabの内部レシピを編集して、エラーを無視するスイッチを指定する必要があります。エラーを無視すると、GitLabサーバーのパフォーマンスに予期しない副次効果が発生する可能性があるため、これを行うことはお勧めしません。

このエラーの別のバリエーションでは、ファイルシステムが読み取り専用であると報告され、次のスタックトレースが表示されます:

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

このエラーは仮想マシンでのみ発生することも報告されており、推奨される回避策はホストで値を設定することです。GitLabに必要な値は、仮想マシンのファイル`/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf`内にあります。これらの値をホストOSの`/etc/sysctl.conf`ファイルに設定した後、ホストで`cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -`を実行します。次に、仮想マシン内で`gitlab-ctl reconfigure`を実行してみてください。カーネルが必要な設定ですでに実行されていることを検出し、エラーが発生しないはずです。

他の行についてこのプロセスを繰り返す必要がある場合があります。たとえば、`/etc/sysctl.conf`に次のようなものを追加した後、再設定が3回失敗します:

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

ファイルを見つけるよりも、Chef出力の行を見た方が簡単かもしれません (ファイルはエラーごとに異なるため)。このスニペットの最後の行を参照してください。

```plaintext
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf 2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj 2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

## ルートアクセスなしでGitLabをインストールできない {#i-am-unable-to-install-gitlab-without-root-access}

時々、ルートアクセスなしでGitLabをインストールできるかどうか尋ねる人がいます。これにはいくつかの理由で問題があります。

### `.deb`または`.rpm`のインストール {#installing-the-deb-or-rpm}

私たちの知る限りでは、特権のないユーザーとしてDebianまたはRPMパッケージをインストールする簡単な方法はありません。ビルドプロセスではソースRPMが作成されないため、LinuxパッケージRPMをインストールできません。

### ポート`80`および`443`での手間のかからないホスティング {#hassle-free-hosting-on-port-80-and-443}

GitLabをデプロイする最も一般的な方法は、Webサーバー (NGINX/Apache) をGitLabと同じサーバー上で実行し、Webサーバーが特権 (1024未満) TCPポートでリッスンするようにすることです。Linuxパッケージでは、ポート`80`および`443`を開くために、ルートとしてマスタープロセスを実行する必要がある、自動的に設定されたNGINXサービスをバンドルすることで、この利便性を提供します。

これが問題となる場合、GitLabをインストールする管理者はバンドルされたNGINXサービスを無効にすることができますが、これにより、アプリケーションの更新中にNGINX設定をGitLabと一致させる負担が発生します。

### サービス間の分離 {#isolation-between-services}

Linuxパッケージのバンドルされたサービス (GitLab自体、NGINX、PostgreSQL、Redis、Mattermost) は、Unixユーザーアカウントを使用して互いに分離されています。これらのユーザーアカウントの作成と管理には、ルートアクセスが必要です。デフォルトでは、Linuxパッケージは`gitlab-ctl reconfigure`中に必要なUnixアカウントを作成しますが、その動作は[無効に](settings/configuration.md#disable-user-and-group-account-management)できます。

原則として、各アプリケーションに独自のrunit (runsvdir)、PostgreSQLおよびRedisプロセスを提供する場合、Linuxパッケージは2つのユーザーアカウント (GitLab用とMattermost用) のみで実行できます。ただし、これは`gitlab-ctl reconfigure` Chefコードの大幅な変更となり、既存のすべてのLinuxパッケージインストールで大きなアップグレードの問題が発生する可能性があります。おそらく、`/var/opt/gitlab`の下のディレクトリ構造を再配置する必要があるでしょう。

### パフォーマンスを向上させるためのオペレーティングシステムの微調整 {#tweaking-the-operating-system-for-better-performance}

`gitlab-ctl reconfigure`中に、PostgreSQLのパフォーマンスを向上させ、接続制限を増やすために、いくつかのsysctl微調整を設定してインストールします。これは、ルートアクセスでのみ実行できます。

## `gitlab-rake assets:precompile`が`Permission denied`で失敗する {#gitlab-rake-assetsprecompile-fails-with-permission-denied}

一部のユーザーは、`gitlab-rake assets:precompile`の実行がLinuxパッケージでは機能しないと報告しています。これに対する簡単な答えは、そのコマンドを実行しないでください。ソースからのGitLabインストールのみを対象としています。

GitLab Webインターフェースは、Ruby on Railsで言うところの「アセット」と呼ばれるCSSファイルとJavaScriptファイルを使用します。[アップストリームGitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets)では、これらのファイルはデベロッパーにとって使いやすい方法で保存されます。読みやすく編集しやすいです。ただし、GitLabの通常のユーザーの場合、これらのファイルはデベロッパーにとって使いやすい形式にはしたくありません。GitLabの速度が低下するためです。これが、GitLabのセットアッププロセスの一部が、アセットをデベロッパーにとって使いやすい形式から、エンドユーザーにとって使いやすい (コンパクト、高速) 形式に変換することである理由です。これが`rake assets:precompile`スクリプトの目的です。

GitLabをソースからインストールする場合 (Linuxパッケージを入手する前の唯一の方法でした)、GitLabを更新するたびにGitLabサーバー上のアセットを変換する必要があります。人々はこの手順を見落としがちで、インターネット上にはまだ、ユーザーが`rake assets:precompile` (現在は`gitlab:assets:compile`に名前が変更されました) を実行することを互いに推奨する投稿、コメント、メールがあります。Linuxパッケージでは、状況が異なります。パッケージを構築するときに、[アセットをビルドします](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74)。LinuxパッケージでGitLabをインストールすると、変換されたアセットはすでにそこにあります。そのため、パッケージからGitLabをインストールするときに`rake assets:precompile`を実行する必要はありません。

`gitlab-rake assets:precompile`がアクセス許可エラーで失敗した場合、セキュリティの観点から見て正当な理由で失敗します。アセットを簡単に書き換えることができないという事実は、攻撃者がGitLabサーバーを使用して、GitLabサーバーの訪問者に悪意のあるJavaScriptコードを提供することを困難にします。

カスタムJavaScriptまたはCSSコードを使用してGitLabを実行する場合は、ソースからGitLabを実行するか、独自のパッケージを構築することをお勧めします。

自分が何をしているかを本当に理解している場合は、次のように`gitlab-rake gitlab:assets:compile`を実行できます:

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## エラー: `Short read or OOM loading DB` {#error-short-read-or-oom-loading-db}

[古いRedisセッションのクリーニング](https://docs.gitlab.com/administration/operations/)を試してください。

## エラー: `The requested URL returned error: 403` {#error-the-requested-url-returned-error-403}

aptリポジトリを使用してGitLabをインストールしようとしたときに、次のようなエラーが発生した場合:

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

サーバーの前面にリポジトリキャッシャーがあるかどうかを確認します (たとえば、`apt-cacher-ng`など)。

次の行をapt-cacher-ng設定に追加します (たとえば、`/etc/apt-cacher-ng/acng.conf`など):

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

`apt-cacher-ng`と、この変更が必要な理由の詳細については、[packagecloudブログ](https://blog.packagecloud.io/using-apt-cacher-ng-with-ssl-tls/)を参照してください。

## apt-mirrorを使用して複数のディストリビューションのパッケージをミラーリングすると失敗する {#mirroring-packages-for-multiple-distributions-using-apt-mirror-fails}

GitLab CEとGitLab EEのdebパッケージは、ディストリビューション全体で同じバージョン文字列を共有しますが、内部のコンテンツが異なります。Debianリポジトリ形式では、これらは[重複パッケージ](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages)として扱われます。これは、1つのdebリポジトリが複数のディストリビューションに安全に対応できないことを意味します。1つのディストリビューションのパッケージメタデータが別のディストリビューションのメタデータを上書きする可能性があるためです。

各ディストリビューションを専用パスで公開します。ただし、`https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>` URLへのリクエストを正しいディストリビューション`https://packages.gitlab.com/gitlab/gitlab-ce/<operating_system>/<distribution>`にリダイレクトするURLリダイレクトが設定されています。これにより、ユーザーは異なるディストリビューションに対して同じURLを使用し続けることができます。

ただし、この方法は、`apt-mirror`のようなミラーリングツールを使用して同じホストから複数のディストリビューションをミラーリングする場合には機能しません。そのため、誤ったディストリビューションのメタデータまたはパッケージをフェッチする可能性があります。

URLパスにディストリビューションを明示的に追加してください。たとえば、Jammyの場合は次のようになります:

```plaintext
deb https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-ee/ubuntu/jammy jammy main
deb https://packages.gitlab.com/gitlab/gitlab-fips/ubuntu/jammy jammy main
```

この形式では、キーの場所は次のとおりです:

- `InRelease`は`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/InRelease`にあります。
- `Packages.gz`は`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/dists/jammy/main/binary-amd64/Packages.gz`にあります。
- パッケージファイルは`https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/jammy/pool/main/g/gitlab-ce/gitlab-ce_18.5.0-ce.0_amd64.deb`にあります。

### `gitlab-runner` {#gitlab-runner}

`gitlab-runner`パッケージの構成は、同じパッケージが複数のディストリビューションで使用されるため、異なります。URLは`https://packages.gitlab.com/runner/gitlab-runner`のままにすることができます。

## 自己署名証明書またはカスタム認証局の使用 {#using-self-signed-certificate-or-custom-certificate-authorities}

カスタム認証局を持つ分離されたネットワークにGitLabをインストールする場合、または自己署名証明書を使用する場合は、証明書がGitLabから到達できることを確認してください。そうしないと、次のようなエラーが発生します:

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

GitLabがGitLab Shellのような内部サービスに接続しようとすると発生します。

これらのエラーを修正するには、[カスタム公開証明書のインストール](settings/ssl/_index.md#install-custom-public-certificates)セクションを参照してください。

## エラー: `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"` {#error-proxyroundtripper-xxx-failed-with-nethttp-timeout-awaiting-response-headers}

GitLab Workhorseが1分以内（デフォルト）にGitLabから応答を受信しない場合、502ページが表示されます。

リクエストがタイムアウトになる理由はさまざまあり、たとえば、ユーザーが非常に大きな差分を読み込むなどの場合が考えられます。

デフォルトのタイムアウト値を大きくするには、`/etc/gitlab/gitlab.rb`で値を設定します:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)し、変更を有効にします。

## 要求された変更は拒否されました {#the-change-you-wanted-was-rejected}

ほとんどの場合、GitLabの前にプロキシがあり、パッケージでデフォルトで設定されているプロキシヘッダーが環境に対して正しくありません。

[NGINXドキュメントのデフォルトプロキシヘッダーセクションの変更](settings/nginx.md#change-the-default-proxy-headers)で、デフォルトヘッダーをオーバーライドする方法について詳しく説明しています。

## CSRFトークンの信頼性を確認できませんでした完了422処理できません {#cant-verify-csrf-token-authenticity-completed-422-unprocessable}

ほとんどの場合、GitLabの前にプロキシがあり、パッケージでデフォルトで設定されているプロキシヘッダーが環境に対して正しくありません。

[NGINXドキュメントのデフォルトプロキシヘッダーセクションの変更](settings/nginx.md#change-the-default-proxy-headers)で、デフォルトヘッダーをオーバーライドする方法について詳しく説明しています。

## 拡張機能`pg_trgm`がありません {#extension-missing-pg_trgm}

[GitLabには](https://docs.gitlab.com/install/postgresql_extensions/)PostgreSQL拡張機能`pg_trgm`が必要です。バンドルされたデータベースを含むLinuxパッケージを使用している場合、アップグレード時に拡張機能が自動的に有効になります。

ただし、外部（パッケージ化されていない）データベースを使用している場合は、拡張機能を手動で有効にする必要があります。この理由として、外部データベースを使用するLinuxパッケージインスタンスには、拡張機能が存在するかどうかを確認する方法がなく、拡張機能を有効にする方法もないことが挙げられます。

この問題を修正するには、まず`pg_trgm`拡張機能をインストールする必要があります。拡張機能は、`postgresql-contrib`パッケージにあります。Debianの場合:

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

[GitLabを実行](https://docs.gitlab.com/install/requirements/#memory)するには、エラーなしで実行するために2GBのメモリが必要です。インストールされている2GBのメモリは、サーバー上の他のプロセスのリソース使用量によっては十分でない可能性があります。GitLabがアップグレードまたはバックアップの実行時に正常に動作する場合は、スワップを追加すると問題が解決するはずです。通常の実行中にサーバーがスワップを使用している場合は、RAMを追加してパフォーマンスを向上させることができます。

## NGINXエラー：`could not build server_names_hash, you should increase server_names_hash_bucket_size` {#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size}

GitLabの外部URLがデフォルトのバケットサイズ（64バイト）よりも長い場合、NGINXが動作を停止し、ログにこのエラーが表示されることがあります。より大きなサーバー名を許可するには、`/etc/gitlab/gitlab.rb`のバケットサイズを2倍にします:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## NFS root_squashで`'root' cannot chown`が原因で再構成に失敗しました {#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash}

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

これは、NFSを使用してディレクトリをマウントし、`root_squash`モードで構成した場合に発生する可能性があります。再構成では、ディレクトリの所有権を適切に設定できません。NFSサーバーのNFSエクスポートで`no_root_squash`を使用するように切り替えるか、[ストレージディレクトリの管理を無効にする](settings/configuration.md#disable-storage-directories-management)か、自分で権限を管理する必要があります。

## `gitlab-runsvdir`が起動していません {#gitlab-runsvdir-not-starting}

これは、systemdを使用するオペレーティングシステム（例：Ubuntu 18.04以降、CentOSなど）に適用されます。

`gitlab-runsvdir`は、`basic.target`ではなく`multi-user.target`中に開始されます。GitLabをアップグレードした後、このサービスの起動に問題がある場合は、コマンドを使用して、システムが`multi-user.target`に必要なすべてのサービスを適切に起動したことを確認する必要がある場合があります:

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

すべての行に`loaded active active`が表示されます。以下の行に示すように、`inactive dead`が表示されている場合は、何らかの問題が発生している可能性があります:

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

systemdによってキューに入れられている可能性のあるジョブを調べるには、次を実行します:

```shell
systemctl list-jobs
```

`running`ジョブが表示されている場合、サービスがスタックしている可能性があり、GitLabの起動がブロックされます。たとえば、一部のユーザーはPlymouthが起動しないという問題を抱えています:

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

Dockerコンテナでは、GitLabパッケージは`/.dockerenv`ファイルの存在を検出し、initシステムの自動検出をスキップします。ただし、非Dockerコンテナ（containerd、cri-oなど）では、そのファイルが存在せず、パッケージはsysvinitにフォールバックするため、インストールで問題が発生する可能性があります。これを回避するために、ユーザーは`gitlab.rb`ファイルに次の設定を追加して、initデーモンの検出を明示的に無効にすることができます:

```ruby
package['detect_init'] = false
```

この構成を使用する場合、`gitlab-ctl reconfigure`を実行する前に、`runsvdir-start`コマンドを使用してrunitサービスを開始する必要があります:

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## AWS Cloudformationの使用中に`gitlab-ctl reconfigure`がハングする {#gitlab-ctl-reconfigure-hangs-while-using-aws-cloudformation}

GitLab systemdユニットファイルは、`After`フィールドと`WantedBy`フィールドの両方で、デフォルトで`multi-user.target`を使用します。これは、サービスが`remote-fs`ターゲットと`network`ターゲットの後に実行されるようにするためであり、GitLabが適切に機能します。

ただし、これは、AWS Cloudformationで使用される、[cloud-init](https://cloudinit.readthedocs.io/en/latest/)独自のユニット順序とうまく相互作用しません。

これを修正するために、ユーザーは`gitlab.rb`の`package['systemd_wanted_by']`設定と`package['systemd_after']`設定を利用して、適切な順序付けに必要な値を指定し、`sudo gitlab-ctl reconfigure`を実行できます。再構成が完了したら、変更を有効にするために`gitlab-runsvdir`サービスを再起動します。

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

**IPv6**アドレス形式が返された場合は、ネットワークインターフェースで**IPv6**プロトコルのサポート（キーワード`ipv6`）が有効になっているかどうかをさらに確認します:

```shell
ip addr # or 'ifconfig' on older operating systems
```

**IPv6**ネットワークプロトコルのサポートがないか無効になっているが、DNS構成がホスト名を**IPv6**アドレスとして解決する場合、GitLabサービスはネットワーク接続を確立できません。

これは、ホストを**IPv4**アドレスではなく**IPv6**アドレスに解決するために、DNS構成（または`/etc/hosts`）を修正することで解決できます。

## エラー：`... bad component(expected host component: my_url.tld)` `external_url`にアンダースコアが含まれている場合 {#error--bad-componentexpected-host-component-my_urltld-when-external_url-contains-underscores}

`external_url`をアンダースコアで設定した場合（たとえば、`https://my_company.example.com`）、CI/CDで次の問題が発生する可能性があります:

- プロジェクトの**設定 > CI/CD**ページを開くことができなくなります。
- Runnerはジョブを選択せず、エラー500で失敗します。

その場合は、[`production.log`](https://docs.gitlab.com/administration/logs/#productionlog)に次のエラーが含まれます:

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

回避策として、`external_url`でアンダースコアを使用しないでください。それについては未解決の問題があります: [アンダースコア付きの`external_url`を設定すると、GitLab CI/CD機能が破損する](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077)。

## `timeout: run: /opt/gitlab/service/gitaly`エラーでアップグレードに失敗する {#upgrade-fails-with-timeout-run-optgitlabservicegitaly-error}

次のエラーが発生して再構成の実行時にパッケージのアップグレードが失敗した場合は、すべてのGitalyプロセスが停止していることを確認してから、`sudo gitlab-ctl reconfigure`を再実行します。

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

詳細については、[issue 341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573)を参照してください。

## GitLabの再インストール時に再構成がスタックする {#reconfigure-is-stuck-when-re-installing-gitlab}

[既知の問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)のため、GitLabをアンインストールして再度インストールしようとした後、再構成プロセスが`ruby_block[wait for logrotate service socket] action run`でスタックすることがあります。この問題は、[GitLabをアンインストール](https://docs.gitlab.com/install/package/#uninstall-the-linux-package)するときに、`systemctl`コマンドの1つが実行されない場合に発生します。

この問題を解決するには:

- GitLabをアンインストールするときは、すべての手順に従い、必要に応じて実行してください。
- [issue 7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)の回避策に従ってください。

## PulpまたはRed Hat SatelliteでのGitLab `yum`リポジトリのミラーリングが失敗する {#mirroring-the-gitlab-yum-repository-with-pulp-or-red-hat-satellite-fails}

[Pulp](https://pulpproject.org/)または[Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite)を使用した<https://packages.gitlab.com/gitlab/>にあるLinuxパッケージの`yum`リポジトリの直接ミラーリングは、同期時に失敗します。異なるソフトウェアによって異なるエラーが発生します:

- Pulp 2またはSatellite < 6.10は、`"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"`エラーで失敗します。
- Satellite 6.10は、`"pkgid"`エラーで失敗します。
- Pulp 3またはSatellite > 6.10は成功するようですが、リポジトリメタデータのみが同期されます。

これらの同期の失敗は、GitLab `yum`ミラーリポジトリ内のメタデータに関する問題が原因です。このメタデータには、通常はリポジトリ内のすべてのRPMのファイルのリストを含む`filelists.xml.gz`ファイルが含まれています。GitLab `yum`リポジトリは、ファイルが完全に入力された場合に発生するサイズの問題を回避するために、このファイルをほとんど空のままにします。

各GitLab RPMには膨大な数のファイルが含まれており、リポジトリ内の多数のRPMを掛けると、完全に入力された場合、巨大な`filelists.xml.gz`ファイルになります。ストレージとビルドの制約のため、ファイルを作成しますが、入力しません。空のファイルにより、PulpおよびRedHat Satellite（Pulpを使用）ファイルのリポジトリのミラーリングに失敗します。

詳細については、[issue 2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766)を参照してください。

### 問題を回避策する {#work-around-the-issue}

問題を回避策するには:

1. `reposync`や`createrepo`などの代替RPMリポジトリミラーリングツールを使用して、公式のGitLab `yum`リポジトリのローカルコピーを作成します。これらのツールは、完全に入力された`filelists.xml.gz`ファイルの作成を含む、ローカルデータ内のリポジトリメタデータを再作成します。
1. PulpまたはSatelliteをローカルミラーにポイントします。

### ローカルミラーの例 {#local-mirror-example}

次に、ローカルミラーリングを実行する方法の例を示します。この例では、以下を使用します:

- [Apache](https://httpd.apache.org/)をリポジトリのWebサーバーとして使用します。
- [`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html)および[`createrepo`](http://createrepo.baseurl.org/)を使用して、GitLabリポジトリをローカルミラーに同期します。このローカルミラーは、PulpまたはRedHat Satelliteのソースとして使用できます。[Cobbler](https://cobbler.github.io/)などの他のツールも使用できます。

この例では: 

- ローカルミラーは、`RHEL 8`、`Rocky 8`、または`AlmaLinux 8`システムで実行されています。
- Webサーバーに使用されるホスト名は`mirror.example.com`です。
- Pulp 3は、ローカルミラーから同期します。
- [GitLab Enterprise Editionリポジトリ](https://packages.gitlab.com/gitlab/gitlab-ee)のミラーリングです。

#### Apacheサーバーを作成および構成する {#create-and-configure-an-apache-server}

次の例は、1つ以上のYumリポジトリミラーをホストするために、基本的なApache 2サーバーをインストールおよび構成する方法を示しています。Webサーバーの構成とセキュリティ保護の詳細については、[Apache](https://httpd.apache.org/)ドキュメントを参照してください。

1. `httpd`をインストールします。

   ```shell
   sudo dnf install httpd
   ```

1. `/etc/httpd/conf/httpd.conf`に`Directory`スタンザを追加します:

   ```apache
   <Directory "/var/www/html/repos">
   Options All Indexes FollowSymLinks
   Require all granted
   </Directory>
   ```

1. `httpd`構成を完了します:

   ```shell
   sudo rm -f /etc/httpd/conf.d/welcome.conf
   sudo mkdir /var/www/html/repos
   sudo systemctl enable httpd --now
   ```

#### ミラーリングされたYumリポジトリのURLを取得します {#get-the-mirrored-yum-repository-url}

1. GitLabリポジトリの`yum`構成ファイルをインストールします:

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

   `--newest-only`オプションは、最新のRPMのみをダウンロードします。このオプションを省略すると、リポジトリ内のすべてのRPM（約1 GB）がダウンロードされます。

1. `createrepo`を実行して、リポジトリメタデータを再作成します:

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

ローカルミラーリポジトリは、<http://mirror.example.com/repos/gitlab_gitlab-ee/>で使用できるはずです。

#### ローカルミラーを更新する {#update-the-local-mirror}

新しいGitLabバージョンがリリースされたら、新しいRPMを取得するために、ローカルミラーを定期的に更新する必要があります。これを行う1つの方法は、`cron`を使用することです。

次の内容で`/etc/cron.daily/sync-gitlab-mirror`を作成します:

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

`dnf reposync`コマンドで使用される`--delete`オプションは、対応するGitLabリポジトリに存在しなくなったローカルミラー内のRPMを削除します。

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

   このコマンドは、GitLabリポジトリへの変更でローカルミラーを更新するために、定期的に実行する必要があります。

リポジトリが同期されたら、公開と配布を作成して使用できるようにすることができます。詳細については、<https://docs.pulpproject.org/pulp_rpm/>を参照してください。

## エラー: `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443` {#error-e-connection-refused-to-d20rj4el6vkp4ccloudfrontnet-443}

`packages.gitlab.com`でパッケージリポジトリでホストされているパッケージをインストールすると、クライアントはCloudFrontアドレス`d20rj4el6vkp4c.cloudfront.net`へのリダイレクトを受信して従います。エアギャップ環境のサーバーは、次のエラーを受信する可能性があります:

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

この問題を解決するには、3つのオプションがあります:

- ドメインで許可リストに登録できる場合は、エンドポイント`d20rj4el6vkp4c.cloudfront.net`をファイアウォール設定に追加します。
- ドメインで許可リストに登録できない場合は、[CloudFront IPアドレス範囲](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips)をファイアウォール設定に追加します。このリストは変更される可能性があるため、ファイアウォール設定と同期しておく必要があります。
- パッケージファイルをパッケージを手動でダウンロードして、サーバーにアップロードします。

## エラー：`503 Service Unavailable`パッケージストレージ操作でサービスを利用できません {#error-503-service-unavailable-for-package-storage-operations}

一部のパッケージストレージコンポーネントは、Google Cloud Storage（GCS）を介して提供されます。これらのコンポーネントは、パブリックAPTリポジトリエンドポイントに加えて、GCSエンドポイントへの送信HTTPSアクセスを必要とします。`apt update`が`503 Service Unavailable`エラーで失敗した場合、`storage.googleapis.com/packages-ops`へのアクセスがブロックされています。

このエラーを解決するには、ファイアウォールルールで、次のエンドポイントへの送信HTTPS（ポート`443`）接続が許可されていることを確認してください:

- `packages.gitlab.com`
- `storage.googleapis.com`
- Google Cloud Storageの`packages-ops`バケット

## `net.core.somaxconn`が低すぎないか確認してください {#check-if-netcoresomaxconn-is-set-too-low}

以下は、`net.core.somaxconn`の値が低すぎるかどうかを識別するのに役立つ場合があります:

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

`netstat -ant | grep -c SYN_RECV`からの戻り値は、確立されるのを待機している接続の数です。値が`net.core.somaxconn`より大きい場合:

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

タイムアウトまたはHTTP 502エラーが発生する可能性があり、`gitlab.rb`の`puma['somaxconn']`変数を更新して、この値を大きくすることをお勧めします。

## エラー：`exec request failed on channel 0`または`shell request failed on channel 0` {#error-exec-request-failed-on-channel-0-or-shell-request-failed-on-channel-0}

Git over SSHを使用してプルまたはプッシュすると、次のエラーが表示される場合があります:

- `exec request failed on channel 0`
- `shell request failed on channel 0`

これらのエラーは、`git`ユーザーからのプロセス数が制限を超えている場合に発生する可能性があります。

このイシューを解決するには、次の手順を実行します:

1. `gitlab-shell`が実行されているノードの`/etc/security/limits.conf`ファイルで、`git`ユーザーの`nproc`設定を増やします。通常、`gitlab-shell`はGitLab Railsノードで実行されます。
1. プルまたはプッシュGitコマンドを再試行します。

## SSH接続が失われた後のインストールハング {#hung-installation-after-ssh-connection-loss}

リモート仮想マシンにGitLabをインストールしていて、SSH接続が失われた場合、インストールがゾンビ`dpkg`プロセスでハングする可能性があります。インストールを再開するには:

1. `top`を実行して、関連付けられている`apt`プロセスのプロセスIDを見つけます。これは、`dpkg`プロセスの親です。
1. `sudo kill <PROCESS_ID>`を実行して、`apt`プロセスを強制終了します。
1. フレッシュインストールを実行する場合のみ、`sudo gitlab-ctl cleanse`を実行します。この手順では、既存のデータが消去されるため、アップグレードには使用しないでください。
1. `sudo dpkg configure -a`を実行します。
1. 目的の外部URLと、不足している可能性のあるその他の設定を含めるように、`gitlab.rb`ファイルを編集します。
1. `sudo gitlab-ctl reconfigure`を実行します。

## GitLabを再設定する際のリダイレクト関連エラー {#redis-related-error-when-reconfiguring-gitlab}

GitLabを再設定する際に、次のエラーが発生する可能性があります:

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

エラーメッセージは、`redis-cli`との接続を確立しようとしているときに、Redisが再起動またはシャットダウンされた可能性があることを示しています。レシピが`gitlab-ctl restart redis`を実行し、すぐにバージョンを確認しようとすることを考えると、エラーを引き起こす競合状態が発生する可能性があります。

この問題を解決するには、次のコマンドを実行します:

```shell
sudo gitlab-ctl reconfigure
```

それが失敗した場合は、`gitlab-ctl tail redis`の出力を確認し、`redis-cli`を実行してみてください。
