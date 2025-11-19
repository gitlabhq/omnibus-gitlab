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

このページでは、ユーザーがLinuxパッケージのインストール時に遭遇する可能性のある一般的な問題について説明します。

## パッケージダウンロード時のハッシュサムの不一致 {#hash-sum-mismatch-when-downloading-packages}

`apt-get install`は次のような出力をします:

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

この問題を修正するには、以下を実行します:

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

詳細については、[Joe Damato's from Packagecloud comment](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/628#note_1824330)と[彼のブログ記事](https://blog.packagecloud.io/apt-hash-sum-mismatch/)を参照してください。

別の回避策として、[CEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ce)または[EEパッケージ](https://packages.gitlab.com/gitlab/gitlab-ee)リポジトリから正しいパッケージを手動でダウンロードする方法があります:

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## openSUSEおよびSLESプラットフォームでのインストール時に不明なキー署名について警告が表示される {#installation-on-opensuse-and-sles-platforms-warns-about-unknown-key-signature}

Linuxパッケージは、署名されたメタデータを提供するパッケージリポジトリに加えて、[GPGキーで署名](update/package_signatures.md)されています。これにより、ユーザーに配布されるパッケージの信頼性と整合性が確保されます。ただし、openSUSEおよびSLESオペレーティングシステムで使用されているパッケージマネージャーは、次のような署名で誤った警告を表示する場合があります:

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

これは、zypperがリポジトリ設定ファイルの`gpgkey`キーワードを無視するzypperの既知のバグです。Packagecloudの新しいバージョンではこれに関する改善があるかもしれませんが、現在、ユーザーは手動でパッケージのインストールに同意する必要があります。

そのため、openSUSEまたはSLESシステムでは、そのような警告が表示された場合でも、インストールを続行しても安全です。

## apt/yumがGPG署名についてクエリを出す {#aptyum-complains-about-gpg-signatures}

GitLabリポジトリがすでに構成されており、`apt-get update`、`apt-get install`、または`yum install`を実行したときに、次のエラーが表示されました:

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

または

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

これは、2020年4月に、GitLabが[Packagecloudインスタンス](https://packages.gitlab.com)を介して利用可能なaptおよびyumリポジトリのメタデータに署名するために使用されるGPGキーを変更したためです。このエラーが表示される場合、一般に、キーリング内のリポジトリメタデータに署名するために現在使用されている公開キーがないことを意味します。このエラーを修正するには、[新しいキーをフェッチする手順](update/package_signatures.md#fetch-latest-signing-key)に従ってください。

## 再設定でエラーが表示される: `NoMethodError - undefined method '[]=' for nil:NilClass` {#reconfigure-shows-an-error-nomethoderror---undefined-method--for-nilnilclass}

`sudo gitlab-ctl reconfigure`を実行したか、パッケージのアップグレードがトリガーとなり、次のようなエラーが発生しました:

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

このエラーは、`/etc/gitlab/gitlab.rb`設定ファイルに、無効またはサポートされていない設定が含まれている場合にスローされます。タイプミスがないか、または設定ファイルに廃止された設定が含まれていないことを再確認してください。

`sudo gitlab-ctl diff-config`を使用するか、最新の[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)をチェックして、利用可能な最新の設定を確認できます。

## ブラウザでGitLabにアクセスできない {#gitlab-is-unreachable-in-my-browser}

`/etc/gitlab/gitlab.rb`で`external_url`を[指定](settings/configuration.md#configure-the-external-url-for-gitlab)してみてください。ファイアウォールの設定も確認してください。GitLabサーバーでポート80（HTTP）または443（HTTPS）が閉じられている可能性があります。

GitLabまたはその他のバンドルされたサービス（レジストリとMattermost）の`external_url`を指定しても、`gitlab.rb`の他の部分が従う`key=value`形式にはなりません。次の形式で設定されていることを確認してください:

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
mattermost_external_url "https://mattermost.example.com"
```

{{< alert type="note" >}}

`external_url`と値の間に等号（`=`）を追加しないでください。

{{< /alert >}}

## メールが配信されない {#emails-are-not-being-delivered}

メールの配信をテストするには、GitLabインスタンスでまだ使用されていないメールの新しいGitLabアカウントを作成します。

必要に応じて、GitLabから送信されたメールの「From」フィールドを`/etc/gitlab/gitlab.rb`の次の設定で変更できます:

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## GitLabサービスのTCPポートがすでに使用されている {#tcp-ports-for-gitlab-services-are-already-taken}

デフォルトでは、PumaはTCPアドレス127.0.0.1:8080でリッスンします。NGINXは、すべてのインターフェースで、ポート80（HTTP）または443（HTTPS）でリッスンします。

Redis、PostgreSQL、およびPumaのポートは、次のように`/etc/gitlab/gitlab.rb`でオーバーライドできます:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

NGINXのポートの変更については、[NGINXリッスンポートの設定](settings/nginx.md#set-the-nginx-listen-port)を参照してください。

## GitユーザーにSSHアクセス権がない {#git-user-does-not-have-ssh-access}

### SELinux対応システム {#selinux-enabled-systems}

SELinux対応システムでは、Gitユーザーの`.ssh`ディレクトリまたはそのコンテンツのセキュリティコンテキストがめちゃくちゃになる可能性があります。これは、`sudo
gitlab-ctl reconfigure`を実行することで修正できます。これにより、`/var/opt/gitlab/.ssh`に`gitlab_shell_t`セキュリティコンテキストが設定されます。

この動作を改善するために、`semanage`を使用してコンテキストを永続的に設定します。`semanage`コマンドが利用可能であることを確認するために、RHELベースのオペレーティングシステムのRPMパッケージに、ランタイム依存である`policycoreutils-python`が追加されました。

#### SELinuxの問題を診断して解決する {#diagnose-and-resolve-selinux-issues}

Linuxパッケージは`/etc/gitlab/gitlab.rb`のデフォルトのパス変更を検出し、正しいファイルコンテキストを適用する必要があります。

{{< alert type="note" >}}

GitLab 16.10以降、管理者は`gitlab-ctl apply-sepolicy`を試して、SELinuxの問題を自動的に修正できます。ランタイムオプションについては、`gitlab-ctl apply-sepolicy --help`を参照してください。

{{< /alert >}}

カスタムデータパス設定を使用するインストールの場合、管理者はSELinuxの問題を手動で解決する必要がある場合があります。

データパスは`gitlab.rb`を介して変更される可能性がありますが、一般的なシナリオでは`symlink`パスの使用が強制されます。管理者は注意する必要があります。`symlink`パスは、Gitalyデータパスなど、すべてのシナリオでサポートされているわけではないためです[Gitalyデータパス](settings/configuration.md#store-git-data-in-an-alternative-directory)。

たとえば、`/data/gitlab`がベースデータディレクトリとして`/var/opt/gitlab`を置き換えた場合、以下を実行するとセキュリティコンテキストが修正されます:

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

ポリシーが適用された後、ウェルカムメッセージを取得することで、SSHアクセスが機能していることを確認できます:

```shell
ssh -T git@gitlab-hostname
```

### すべてのシステム {#all-systems}

Gitユーザーは、デフォルトで、/etc/shadowの`'!'`で示されるロックされたパスワードで作成されます。「UsePam yes」が有効になっていない限り、OpenSSHデーモンは、SSHキーを使用している場合でも、Gitユーザーの認証を許可しません。別の安全なソリューションは、`/etc/shadow`の`'!'`を`'*'`に置き換えることでパスワードをロック解除することです。Gitユーザーは制限されたシェルで実行され、非スーパーユーザーの`passwd`コマンドでは新しいパスワードの前に現在のパスワードを入力する必要があるため、パスワードを変更することはできません。ユーザーは`'*'`に一致するパスワードを入力できません。つまり、アカウントにはパスワードが引き続きありません。

Gitユーザーはシステムにアクセスできる必要があることに注意してください。したがって、`/etc/security/access.conf`でセキュリティ設定を確認し、Gitユーザーがブロックされていないことを確認してください。

## エラー: `FATAL: could not create shared memory segment: Cannot allocate memory` {#error-fatal-could-not-create-shared-memory-segment-cannot-allocate-memory}

パッケージ化されたPostgreSQLインスタンスは、共有メモリとして合計メモリの25％を割り当てようとします。一部のLinux（仮想マシン）サーバーでは、利用可能な共有メモリが少なく、PostgreSQLが起動しません。`/var/log/gitlab/postgresql/current`で:

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

PostgreSQLが割り当てようとする共有メモリの量を`/etc/gitlab/gitlab.rb`で手動で減らすことができます:

```ruby
postgresql['shared_buffers'] = "100MB"
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied` {#error-fatal-could-not-open-shared-memory-segment-postgresqlxxxxxxxxxx-permission-denied}

デフォルトでは、PostgreSQLは使用する共有メモリタイプを検出しようとします。共有メモリが有効になっていない場合は、`/var/log/gitlab/postgresql/current`にこのエラーが表示される場合があります。これを修正するには、PostgreSQLの共有メモリ検出を無効にできます。`/etc/gitlab/gitlab.rb`で次の値を設定します:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## エラー: `FATAL: remaining connection slots are reserved for non-replication superuser connections` {#error-fatal-remaining-connection-slots-are-reserved-for-non-replication-superuser-connections}

PostgreSQLには、データベースサーバーへの同時接続の最大数を設定する設定があります。このエラーが表示される場合、GitLabインスタンスが同時接続数に関するこの制限を超えようとしていることを意味します。

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

この問題を修正するには、2つのオプションがあります:

- 最大接続値を増やすか、どちらかです:

  1. `/etc/gitlab/gitlab.rb`を編集します: 

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

- または、PostgreSQL用の接続プーラーである[PgBouncerの使用](https://docs.gitlab.com/administration/postgresql/pgbouncer/)を検討できます。

## 再構成でGLIBCバージョンについてクエリを出す {#reconfigure-complains-about-the-glibc-version}

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

これは、インストールしたLinuxパッケージが、サーバー上のバージョンとは異なるOSリリース用にビルドされた場合に発生する可能性があります。オペレーティングシステムに対応する正しいLinuxパッケージをダウンロードしてインストールしたことを再確認してください。

## 再構成でGitユーザーの作成に失敗する {#reconfigure-fails-to-create-the-git-user}

これは、Gitユーザーとして`sudo gitlab-ctl reconfigure`を実行した場合に発生する可能性があります。別のユーザーに切り替えます。

さらに重要なこととして、Linuxパッケージで使用されるGitユーザーまたは他のユーザーにsudo権限を付与しないでください。システムユーザーに不要な権限を与えると、システムのセキュリティが弱まります。

## sysctlでカーネルパラメータを変更できませんでした {#failed-to-modify-kernel-parameters-with-sysctl}

sysctlがカーネルパラメータを変更できない場合、次のスタックトレースでエラーが発生する可能性があります:

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

これは、仮想化されていないマシンでは発生する可能性は低いですが、openVZのような仮想化を備えたVPSでは、コンテナに必要なモジュールが有効になっていないか、コンテナがカーネルパラメータにアクセスできない可能性があります。

sysctlでエラーが発生した[モジュールの有効化](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error)を試してください。

[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361)に記載されている回避策が報告されており、障害を無視するスイッチを提供することにより、GitLabの内部レシピを編集する必要があります。エラーを無視すると、GitLabサーバーのパフォーマンスに予期しない副作用が発生する可能性があるため、これを行うことはお勧めしません。

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

このエラーは仮想マシンでのみ発生することも報告されており、推奨される回避策は、ホストに値を設定することです。GitLabに必要な値は、仮想マシンのファイル`/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf`内にあります。ホストOSの`/etc/sysctl.conf`ファイルでこれらの値を設定した後、ホストで`cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -`を実行します。次に、仮想マシン内で`gitlab-ctl reconfigure`を実行してみてください。カーネルが必要な設定ですでに実行されていることを検出し、エラーは発生しません。

他の行についてもこのプロセスを繰り返す必要がある場合があります。たとえば、`/etc/sysctl.conf`に次のようなものを追加した後、再構成が3回失敗します:

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

ファイルを見つけるよりも、Chef出力の行を見る方が簡単かもしれません（ファイルはエラーごとに異なるため）。このスニペットの最後の行を参照してください。

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

ルートアクセスなしでGitLabをインストールできるかどうかを尋ねる人が時々います。これはいくつかの理由で問題があります。

### `.deb`または`.rpm`のインストール {#installing-the-deb-or-rpm}

私たちの知る限りでは、特権のないユーザーとしてDebianまたはRPMパッケージをインストールするクリーンな方法はありません。ビルドプロセスでソースRPMが作成されないため、LinuxパッケージRPMをインストールできません。

### ポート`80`と`443`での手間のかからないホスティング {#hassle-free-hosting-on-port-80-and-443}

GitLabをデプロイする最も一般的な方法は、GitLabと同じサーバー上でWebサーバー（NGINX/Apache）を実行し、特権（1024未満）のTCPポートでリッスンするようにWebサーバーを設定することです。Linuxパッケージでは、ポート`80`と`443`を開くためにルートとしてメインプロセスを実行する必要がある自動的に構成されたNGINXサービスをバンドルすることにより、この利便性を提供します。

これが問題になる場合、管理者がGitLabをインストールすると、バンドルされたNGINXサービスを無効にできますが、これにより、アプリケーションの更新中にNGINX設定をGitLabと一致させるという負担が生じます。

### サービス間の分離 {#isolation-between-services}

Linuxパッケージ（GitLab自体、NGINX、PostgreSQL、Redis、Mattermost）のバンドルされたサービスは、Unixユーザーアカウントを使用して相互に分離されています。これらのユーザーアカウントの作成と管理には、ルートアクセスが必要です。デフォルトでは、Linuxパッケージは`gitlab-ctl reconfigure`中に必要なUnixアカウントを作成しますが、その動作は[無効](settings/configuration.md#disable-user-and-group-account-management)にできます。

原則として、各アプリケーションに独自のrunit（runsvdir）、PostgreSQL、およびRedisプロセスを提供する場合、Linuxパッケージは、2つのユーザーアカウント（GitLab用とMattermost用）のみで実行できます。ただし、これは`gitlab-ctl reconfigure` Chefコードの大きな変更であり、既存のすべてのLinuxパッケージインストールに大きなアップグレードの苦痛をもたらす可能性があります。`/var/opt/gitlab`の下のディレクトリ構造を再配置する必要があるでしょう。

### パフォーマンスを向上させるためのオペレーティングシステムの微調整 {#tweaking-the-operating-system-for-better-performance}

`gitlab-ctl reconfigure`中に、PostgreSQLのパフォーマンスを向上させ、接続制限を増やすために、いくつかのsysctl微調整を設定してインストールします。これは、ルートアクセスでのみ実行できます。

## `gitlab-rake assets:precompile`が`Permission denied`で失敗する {#gitlab-rake-assetsprecompile-fails-with-permission-denied}

一部のユーザーから、`gitlab-rake assets:precompile`を実行すると、Linuxパッケージでは機能しないというレポートがあります。これに対する簡単な答えは、そのコマンドを実行しないことです。これは、ソースからのGitLabインストールのみを対象としています。

GitLab Webインターフェースでは、CSSファイルとJavaScriptファイルを使用します。これらは、Ruby on Railsの用語では「アセット」と呼ばれます。[アップストリームGitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets)では、これらのファイルは開発者にとって使いやすい方法で保存されています。読みやすく編集しやすいです。ただし、GitLabの通常のユーザーである場合、GitLabの動作が遅くなるため、これらのファイルを開発者にとって使いやすい形式にする必要はありません。これが、GitLab設定プロセスの一部が、アセットを開発者にとって使いやすい形式からエンドユーザーにとって使いやすい（コンパクトで高速な）形式に変換することである理由です。それが`rake assets:precompile`スクリプトの目的です。

ソースからGitLabをインストールする場合（Linuxパッケージが登場する前は、これが唯一の方法でした）、GitLabを更新するたびに、GitLabサーバー上のアセットを変換する必要があります。以前は、この手順を見落とされていましたが、インターネット上には、ユーザーが`rake assets:precompile`を実行することを互いに推奨する投稿、コメント、メールがまだあります（現在は`gitlab:assets:compile`に名前が変更されています）。Linuxパッケージでは、状況が異なります。パッケージをビルドするとき、[アセットをコンパイル](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74)します。Linuxパッケージを使用してGitLabをインストールすると、変換されたアセットはすでにそこにあります！そのため、パッケージからGitLabをインストールするときに`rake assets:precompile`を実行する必要はありません。

`gitlab-rake assets:precompile`が権限エラーで失敗すると、セキュリティの観点から正当な理由で失敗します。アセットを簡単に書き換えることができないという事実は、攻撃者がGitLabサーバーを使用して悪意のあるJavaScriptコードをGitLabサーバーの訪問者に提供することを困難にします。

カスタムJavaScriptまたはCSSコードを使用してGitLabを実行する場合は、おそらくソースからGitLabを実行するか、独自のパッケージをビルドする方が良いでしょう。

実際に何をしているのかを理解している場合は、次のように`gitlab-rake gitlab:assets:compile`を実行できます:

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## エラー: `Short read or OOM loading DB` {#error-short-read-or-oom-loading-db}

[古いRedisセッションのクリーン](https://docs.gitlab.com/administration/operations/)を試してください。

## エラー: `The requested URL returned error: 403` {#error-the-requested-url-returned-error-403}

aptリポジトリを使用してGitLabをインストールしようとしたときに、次のようなエラーが発生した場合:

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

たとえば、`apt-cacher-ng`のように、サーバーの前面にリポジトリキャッシャーがあるかどうかを確認します。

apt-cacher-ngの設定ファイル（`/etc/apt-cacher-ng/acng.conf`など）に次の行を追加します:

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

`apt-cacher-ng`の詳細と、この変更が必要な理由については、[packagecloudブログ](https://blog.packagecloud.io/using-apt-cacher-ng-with-ssl-tls/)を参照してください。

## 自己署名認証局またはカスタム認証局の使用 {#using-self-signed-certificate-or-custom-certificate-authorities}

カスタム認証局を使用する分離されたネットワークにGitLabをインストールする場合、または自己署名証明書を使用する場合は、GitLabが証明書に到達できることを確認してください。そうしないと、次のようなエラーが発生します:

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

GitLabがGitLab Shellなどの内部サービスと接続しようとした場合。

これらのエラーを修正するには、[カスタムパブリック証明書のインストール](settings/ssl/_index.md#install-custom-public-certificates)セクションを参照してください。

## エラー: `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"` {#error-proxyroundtripper-xxx-failed-with-nethttp-timeout-awaiting-response-headers}

GitLab Workhorseが1分以内（デフォルト）にGitLabから応答を受信しない場合、502ページを提供します。

リクエストがタイムアウトする理由はさまざまです。たとえば、ユーザーが非常に大きな差分を読み込んでいる可能性があります。

`/etc/gitlab/gitlab.rb`で値を設定することにより、デフォルトのタイムアウト値を大きくすることができます:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

ファイルを保存して、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#omnibus-gitlab-reconfigure)し、変更を有効にします。

## ご希望の変更は拒否されました {#the-change-you-wanted-was-rejected}

おそらく、GitLabの前面にプロキシがあり、Linuxパッケージでデフォルトで設定されたプロキシヘッダーがご使用の環境では正しくありません。

デフォルトのヘッダーをオーバーライドする方法の詳細については、[NGINXドキュメントのデフォルトのプロキシヘッダーの変更セクション](settings/nginx.md#change-the-default-proxy-headers)を参照してください。

## CSRFトークンの信頼性を確認できません完了422処理できません {#cant-verify-csrf-token-authenticity-completed-422-unprocessable}

おそらく、GitLabの前面にプロキシがあり、Linuxパッケージでデフォルトで設定されたプロキシヘッダーがご使用の環境では正しくありません。

デフォルトのヘッダーをオーバーライドする方法の詳細については、[NGINXドキュメントのデフォルトのプロキシヘッダーの変更セクション](settings/nginx.md#change-the-default-proxy-headers)を参照してください。

## 拡張機能ミッシング`pg_trgm` {#extension-missing-pg_trgm}

[GitLabでは](https://docs.gitlab.com/install/requirements/#postgresql-requirements)PostgreSQL拡張機能`pg_trgm`が必要です。バンドルされたデータベースでLinuxパッケージを使用している場合は、アップグレード時に拡張機能が自動的に有効になるはずです。

ただし、外部（Linuxパッケージ化されていない）データベースを使用している場合は、拡張機能を手動で有効にする必要があります。これには、外部データベースを備えたLinuxパッケージインスタンスには、拡張機能が存在するかどうかを確認する方法がなく、拡張機能を有効にする方法もないためです。

このイシューを解決するには、最初に`pg_trgm`拡張機能をインストールする必要があります。拡張機能は`postgresql-contrib`パッケージにあります。Debianの場合:

```shell
sudo apt-get install postgresql-contrib
```

拡張機能をインストールしたら、スーパーユーザーとして`psql`にアクセスし、拡張機能を有効にします。

1. スーパーユーザーとして`psql`にアクセスします:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. 拡張機能を有効にします:

   ```plaintext
   CREATE EXTENSION pg_trgm;
   \q
   ```

1. ここで、移行を再度実行します:

   ```shell
   sudo gitlab-rake db:migrate
   ```

---

Dockerを使用している場合は、最初にコンテナにアクセスしてから、上記のコマンドを実行し、最後にコンテナを再起動する必要があります。

1. コンテナにアクセスします:

   ```shell
   docker exec -it gitlab bash
   ```

1. 上記のコマンドを実行します。

1. コンテナを再起動します:

   ```shell
   docker restart gitlab
   ```

## エラー: `Errno::ENOMEM: Cannot allocate memory during backup or upgrade` {#error-errnoenomem-cannot-allocate-memory-during-backup-or-upgrade}

[GitLabを](https://docs.gitlab.com/install/requirements/#memory)エラーなしで実行するには、2GBの利用可能なメモリが必要です。2GBのメモリをインストールしても、サーバー上の他のプロセスのリソース使用量によっては十分でない場合があります。アップグレードまたはバックアップの実行時以外にGitLabが正常に動作する場合は、スワップを追加すると問題が解決されます。通常の使用中にサーバーがスワップを使用している場合は、RAMを追加してパフォーマンスを向上させることができます。

## NGINXエラー: `could not build server_names_hash, you should increase server_names_hash_bucket_size` {#nginx-error-could-not-build-server_names_hash-you-should-increase-server_names_hash_bucket_size}

GitLabの外部URLがデフォルトのバケットサイズ（64バイト）より長い場合、NGINXが動作を停止し、ログにこのエラーが表示されることがあります。より大きなサーバー名を許可するには、`/etc/gitlab/gitlab.rb`でバケットサイズを2倍にします:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## NFS root_squashにより`'root' cannot chown`が原因で再設定が失敗する:  {#reconfigure-fails-due-to-root-cannot-chown-with-nfs-root_squash}

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

NFSを使用してディレクトリをマウントし、`root_squash`モードで設定した場合に、これが発生する可能性があります。再構成では、ディレクトリの所有権を適切に設定できません。NFSサーバー上のNFSエクスポートで`no_root_squash`を使用するように切り替えるか、[ストレージディレクトリの管理を無効に](settings/configuration.md#disable-storage-directories-management)して、自分で権限を管理する必要があります。

## `gitlab-runsvdir`が起動していません {#gitlab-runsvdir-not-starting}

これは、systemdを使用するオペレーティングシステム（Ubuntu 18.04以降、CentOSなど）に適用されます。

`gitlab-runsvdir`は、`multi-user.target`ではなく、`basic.target`の間に開始されます。GitLabのアップグレード後にこのサービスの開始に問題がある場合は、コマンドを使用して、システムが`multi-user.target`に必要なすべてのサービスを正しく起動したことを確認する必要がある場合があります:

```shell
systemctl -t target
```

すべてが正常に機能している場合、出力はこのように表示されるはずです:

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

すべての行に`loaded active active`が表示されるはずです。下の行に示すように、`inactive dead`が表示されている場合、何らかの問題がある可能性があります:

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

systemdによってキューに入れられているジョブを調べるには、次を実行します:

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

Dockerコンテナでは、GitLabパッケージは`/.dockerenv`ファイルの存在を検出し、initシステムの自動検出をスキップします。ただし、非Dockerコンテナ（containerd、cri-oなど）では、そのファイルは存在せず、パッケージはsysvinitにフォールバックするため、インストールで問題が発生する可能性があります。これを防ぐために、ユーザーは`gitlab.rb`ファイルで次の設定を追加することにより、initデーモンの検出を明示的に無効にできます:

```ruby
package['detect_init'] = false
```

この設定を使用している場合、`runsvdir-start`コマンドを使用して、`gitlab-ctl reconfigure`を実行する前にrunitサービスを開始する必要があります:

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## `gitlab-ctl reconfigure`は、AWS Cloudformationの使用中にハングします {#gitlab-ctl-reconfigure-hangs-while-using-aws-cloudformation}

GitLab systemdユニットファイルはデフォルトで、`After`フィールドと`WantedBy`フィールドの両方に`multi-user.target`を使用します。これは、サービスが`remote-fs`ターゲットと`network`ターゲットの後に実行されるようにするためであり、GitLabが適切に機能するためです。

ただし、これはAWS Cloudformationで使用される[cloud-init](https://cloudinit.readthedocs.io/en/latest/)独自のユニット順序付けとうまく相互作用しません。

これを修正するには、ユーザーは`gitlab.rb`の`package['systemd_wanted_by']`設定と`package['systemd_after']`設定を使用して、適切な順序付けに必要な値を指定し、`sudo gitlab-ctl reconfigure`を実行できます。再構成が完了したら、変更を有効にするには、`gitlab-runsvdir`サービスを再起動します。

```shell
sudo systemctl restart gitlab-runsvdir
```

## エラー: `Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)` {#error-errnoeafnosupport-address-family-not-supported-by-protocol---socket2}

GitLabの起動時に、次のようなエラーが発生した場合:

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

**IPv6**アドレス形式が返された場合は、ネットワークインターフェースで**IPv6**プロトコルサポート（キーワード`ipv6`）が有効になっているかどうかをさらに確認します:

```shell
ip addr # or 'ifconfig' on older operating systems
```

**IPv6**ネットワークプロトコルサポートが存在しないか無効になっているが、ドメイン名システム構成がホスト名を**IPv6**アドレスとして解決する場合、GitLabサービスはネットワーク接続を確立できません。

これは、（`/etc/hosts`）ドメイン名サービス構成を修正して、ホストを**IPv4**（IPv6）ではなく**IPv6**（IPv4）アドレスに解決することで解決できます。

<!-- markdownlint-disable line-length -->

## `external_url`にアンダースコアが含まれている場合にエラー: `URI::InvalidComponentError (bad component(expected host component: my_url.tld)` {#error-uriinvalidcomponenterror-bad-componentexpected-host-component-my_urltld-when-external_url-contains-underscores}

`external_url`にアンダースコア（たとえば、`https://my_company.example.com`）を設定している場合は、CI/CDで次の問題が発生する可能性があります:

- プロジェクトの**設定 > CI/CD**ページを開くことができなくなります。
- Runnerはジョブを取得せず、エラー500で失敗します。

その場合、[`production.log`](https://docs.gitlab.com/administration/logs/#productionlog)には次のエラーが含まれます:

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

回避策として、`external_url`でアンダースコアを使用しないでください。これに関する未解決のイシューがあります: [アンダースコア付きの`external_url`設定は、GitLab CI/CD機能が破損する原因となります](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077)。

<!-- markdownlint-enable line-length -->

## `timeout: run: /opt/gitlab/service/gitaly`エラーでアップグレードに失敗しました {#upgrade-fails-with-timeout-run-optgitlabservicegitaly-error}

次のエラーで再構成を実行するとパッケージのアップグレードが失敗する場合は、すべてのGitalyプロセスが停止していることを確認してから、
`sudo gitlab-ctl reconfigure`を再実行します。

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

詳細については、[イシュー341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573)を参照してください。

## GitLabの再インストール時に再構成がスタックする {#reconfigure-is-stuck-when-re-installing-gitlab}

[既知の問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)のため、GitLabをアンインストールして再度インストールしようとすると、再構成プロセスが`ruby_block[wait for logrotate service socket] action run`でスタックすることがあります。この問題は、[GitLabをアンインストール](https://docs.gitlab.com/install/package/#uninstall-the-linux-package)するときに、`systemctl`コマンドの1つが実行されない場合に発生します。

この問題を解決するには、以下を実行します:

- GitLabをアンインストールするときにすべての手順に従い、必要に応じて実行していることを確認してください。
- [問題7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776)の回避策に従ってください。

## PulpまたはRed Hat Satelliteを使用したGitLab `yum`リポジトリのミラーリングが失敗する {#mirroring-the-gitlab-yum-repository-with-pulp-or-red-hat-satellite-fails}

[Pulp](https://pulpproject.org/)または[Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite)を使用した<https://packages.gitlab.com/gitlab/>にあるLinuxパッケージ`yum`リポジトリの直接ミラーリングは、同期時に失敗します。エラーはソフトウェアによって異なります:

- Pulp 2またはSatellite <6.10は、`"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"`エラーで失敗します。
- Satellite 6.10は、`"pkgid"`エラーで失敗します。
- Pulp 3またはSatellite >6.10は成功したように見えますが、リポジトリメタデータのみが同期されます。

これらの同期の失敗は、GitLab `yum`ミラーリポジトリのメタデータの問題が原因です。このメタデータには、通常、
リポジトリ内のすべてのRPMのファイルのリストが含まれる`filelists.xml.gz`ファイルが含まれています。
GitLab `yum`リポジトリは、ファイルが完全入力された場合の原因となるサイズの問題を回避するために、このファイルをほとんど空のままにします。

各GitLab RPMには膨大な数のファイルが含まれており、リポジトリ内の多数のRPMを掛けると、`filelists.xml.gz`ファイルが完全入力された場合に巨大になります。ストレージとビルドの制約のため、ファイルを作成しますが、入力されたません。空のファイルにより、PulpおよびRedHat Satellite（Pulpを使用）リポジトリのファイルのミラーリングが失敗します。

詳細については、[問題2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766)を参照してください。

### イシューを回避する {#work-around-the-issue}

イシューを回避するには:

1. `reposync`や`createrepo`などの代替RPMリポジトリミラーリングツールを使用して、公式のGitLab `yum`リポジトリのローカルコピーを作成します。これらのツールは、完全に入力された`filelists.xml.gz`ファイルの作成を含む、ローカルコピーにリポジトリメタデータを再作成します。
1. PulpまたはSatelliteをローカルコピーミラーにポイントします。

### ローカルコピーミラーの例 {#local-mirror-example}

次に、ローカルコピーミラーリングを行う方法の例を示します。この例では、以下を使用します:

- [Apache](https://httpd.apache.org/)をリポジトリのWebサーバーとして使用します。
- [`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html)と[`createrepo`](http://createrepo.baseurl.org/)を使用して、GitLabリポジトリをローカルコピーミラーに同期します。このローカルコピーミラーは、PulpまたはRedHat Satelliteのソースとして使用できます。[Cobbler](https://cobbler.github.io/)などの他のツールも使用できます。

この例では: 

- ローカルコピーミラーは、`RHEL 8`、`Rocky 8`、または`AlmaLinux 8`システムで実行されています。
- Webサーバーに使用されるホスト名は`mirror.example.com`です。
- Pulp 3はローカルコピーミラーから同期します。
- [GitLab Enterprise Editionリポジトリ](https://packages.gitlab.com/gitlab/gitlab-ee)のミラーリングです。

#### Apacheサーバーを作成および構成する {#create-and-configure-an-apache-server}

次の例は、基本的なApache 2サーバーをインストールおよび構成して、1つ以上のYumリポジトリミラーをホストする方法を示しています。Webサーバーの構成とセキュリティ保護の詳細については、[Apache](https://httpd.apache.org/)ドキュメントを参照してください。

1. `httpd`をインストールします:

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

#### ミラーリングされたYumリポジトリURLを取得する {#get-the-mirrored-yum-repository-url}

1. GitLabリポジトリの`yum`構成ファイルをインストールします:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   sudo dnf config-manager --disable gitlab_gitlab-ee gitlab_gitlab-ee-source
   ```

1. リポジトリのURLを取得します:

   ```shell
   sudo dnf config-manager --dump gitlab_gitlab-ee | grep baseurl
   baseurl = https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64
   ```

   `baseurl`の内容をローカルコピーミラーのソースとして使用します。たとえば`https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64`などです。

#### ローカルコピーミラーを作成する {#create-the-local-mirror}

1. `createrepo`パッケージをインストールします:

   ```shell
   sudo dnf install createrepo
   ```

1. `reposync`を実行して、RPMをローカルコピーミラーにコピーします:

   ```shell
   sudo dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only
   ```

   `--newest-only`オプションは、最新のRPMのみをダウンロードします。このオプションを省略すると、リポジトリ内のすべてのRPM（それぞれ約1 GB）がダウンロードされます。

1. `createrepo`を実行して、リポジトリメタデータを再作成します:

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

ローカルコピーミラーリポジトリが<http://mirror.example.com/repos/gitlab_gitlab-ee/>で使用可能になっているはずです。

#### ローカルコピーミラーを更新する {#update-the-local-mirror}

新しいGitLabバージョンがリリースされるときに新しいRPMを取得するには、ローカルコピーミラーを定期的に更新する必要があります。これを行う1つの方法は、`cron`を使用することです。

次の内容で`/etc/cron.daily/sync-gitlab-mirror`を作成します:

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

`dnf reposync`コマンドで使用される`--delete`オプションは、対応するGitLabリポジトリに存在しなくなったローカルコピーミラー内のRPMを削除します。

#### ローカルコピーミラーの使用 {#using-the-local-mirror}

1. Pulpの`repository`と`remote`を作成します:

   ```shell
   pulp rpm repository create --retain-package-versions=1 --name "gitlab-ee"
   pulp rpm remote create --name gitlab-ee --url "http://mirror.example.com/repos/gitlab_gitlab-ee/" --policy immediate
   pulp rpm repository update --name gitlab-ee --remote gitlab-ee
   ```

1. リポジトリを同期します:

   ```shell
   pulp rpm repository sync --name gitlab-ee
   ```

   このコマンドは、GitLabリポジトリへの変更でローカルコピーミラーを更新するために定期的に実行する必要があります。

リポジトリが同期されたら、公開と配信を作成して、使用できるようにすることができます。詳細については、<https://docs.pulpproject.org/pulp_rpm/>を参照してください。

## エラー: `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443` {#error-e-connection-refused-to-d20rj4el6vkp4ccloudfrontnet-443}

`packages.gitlab.com`にあるパッケージリポジトリでホストされているパッケージをインストールすると、クライアントはCloudFrontアドレス`d20rj4el6vkp4c.cloudfront.net`にリダイレクトされて従います。エアギャップ環境のサーバーは、次のエラーを受信する可能性があります:

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

この問題を解決するには、3つのオプションがあります:

- ドメインで許可リストを許可できる場合は、エンドポイント`d20rj4el6vkp4c.cloudfront.net`をファイアウォール設定に追加します。
- ドメインで許可リストを許可できない場合は、[CloudFront IPアドレス範囲](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips)をファイアウォール設定に追加します。変更される可能性があるため、このリストをファイアウォール設定と同期させておく必要があります。
- パッケージファイルを手動でダウンロードして、サーバーにアップロードします。

## `net.core.somaxconn`が低すぎるかどうかを確認する {#check-if-netcoresomaxconn-is-set-too-low}

以下は、`net.core.somaxconn`の値が低すぎる場合に役立ちます:

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

`netstat -ant | grep -c SYN_RECV`からの戻り値は、確立を待機している接続の数です。値が`net.core.somaxconn`より大きい場合:

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

タイムアウトまたはHTTP 502エラーが発生する可能性があり、`gitlab.rb`の`puma['somaxconn']`変数を更新して、この値を大きくすることをお勧めします。

## エラー: `exec request failed on channel 0`または`shell request failed on channel 0` {#error-exec-request-failed-on-channel-0-or-shell-request-failed-on-channel-0}

Git over SSHを使用してプルまたはプッシュすると、次のエラーが表示されることがあります:

- `exec request failed on channel 0`
- `shell request failed on channel 0`

これらのエラーは、`git`ユーザーからのプロセス数が制限を超えている場合に発生する可能性があります。

このイシューを解決するには、次の手順を実行してください:

1. `gitlab-shell`が実行されているノードの`/etc/security/limits.conf`ファイルで、`git`ユーザーの`nproc`設定を増やします。通常、`gitlab-shell`はGitLab Railsノードで実行されます。
1. Gitコマンドのプルまたはプッシュを再試行します。

## SSH接続の切断後にインストールが停止する {#hung-installation-after-ssh-connection-loss}

リモート仮想マシンにGitLabをインストールしていて、SSH接続が失われた場合、インストールが停止し、ゾンビ`dpkg`プロセスが発生する可能性があります。インストールを再開するには:

1. `top`を実行して、関連する`apt`プロセスのプロセスIDを検索します。これは`dpkg`プロセスの親です。
1. `sudo kill <PROCESS_ID>`を実行して`apt`プロセスを強制終了します。
1. フレッシュインストールを実行する場合のみ、`sudo gitlab-ctl cleanse`を実行してください。このステップでは既存のデータが消去されるため、アップグレードには使用しないでください。
1. `sudo dpkg configure -a`を実行します。
1. `gitlab.rb`ファイルを編集して、目的の外部URLと、他に不足している設定を含めます。
1. `sudo gitlab-ctl reconfigure`を実行します。

## GitLabの再設定時のRedis関連エラー {#redis-related-error-when-reconfiguring-gitlab}

GitLabの再設定時に、次のエラーが発生する可能性があります:

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

このエラーメッセージは、`redis-cli`との接続を確立しようとしている間に、Redisが再起動またはシャットダウンされた可能性があることを示しています。このレシピは`gitlab-ctl restart redis`を実行し、すぐにバージョンを確認しようとするため、エラーの原因となる競合状態が発生する可能性があります。

この問題を解決するには、次のコマンドを実行します:

```shell
sudo gitlab-ctl reconfigure
```

それが失敗した場合は、`gitlab-ctl tail redis`の出力を確認し、`redis-cli`を実行してみてください。
