---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージインストールにおける設定オプション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabを設定するには、`/etc/gitlab/gitlab.rb`ファイル内の関連するオプションを設定します。

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)には、利用可能なすべてのオプションの完全なリストが含まれています。新規インストールでは、`/etc/gitlab/gitlab.rb`にリストされているテンプレートのオプションがすべてデフォルトで設定されています。

{{< alert type="note" >}}

`/etc/gitlab/gitlab.rb`の編集時に提供される例は、インスタンスのデフォルト設定を必ずしも反映しているとは限りません。

{{< /alert >}}

デフォルト設定の一覧については、[パッケージのデフォルト](https://docs.gitlab.com/administration/package_information/defaults/)を参照してください。

## GitLabの外部URLを設定する {#configure-the-external-url-for-gitlab}

正しいリポジトリクローンリンクをユーザーに表示するには、ユーザーがリポジトリにアクセスするために使用するURLをGitLabに提供する必要があります。サーバーのIPを使用できますが、完全修飾ドメイン名（FQDN）を使用することをおすすめします。GitLab Self-ManagedインスタンスでのDNSの使用に関する詳細については、[DNSドキュメント](dns.md)を参照してください。

外部URLを変更するには:

1. オプション。外部URLを変更する前に、以前に[カスタム**ホームページのURL**または**サインアウト後のパス**](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#sign-in-information)を定義したかどうかを確認します。これらの設定はどちらも、新しい外部URLを設定した後に意図しないリダイレクトを引き起こす可能性があります。URLを定義した場合は、完全に削除してください。

1. `/etc/gitlab/gitlab.rb`を編集し、`external_url`を希望するURLに変更します:

   ```ruby
   external_url "http://gitlab.example.com"
   ```

   または、サーバーのIPアドレスを使用できます:

   ```ruby
   external_url "http://10.0.0.1"
   ```

   前の例では、プレーンなHTTPを使用しています。HTTPSを使用する場合は、[SSLを設定する方法](ssl/_index.md)を参照してください。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。GitLabをしばらく使用していた場合は、外部URLを変更した後、[Markdownキャッシュを無効化](https://docs.gitlab.com/administration/invalidate_markdown_cache/)する必要もあります。

### インストール時に外部URLを特定する {#specify-the-external-url-at-the-time-of-installation}

Linuxパッケージを使用している場合は、`EXTERNAL_URL`環境変数を使用して、最小限のコマンド数でGitLabインスタンスをセットアップできます。この変数が設定されている場合、自動的に検出され、その値が`gitlab.rb`ファイルに`external_url`として書き込まれます。

`EXTERNAL_URL`環境変数は、パッケージのインストールとアップグレードにのみ影響します。通常のリ設定の実行では、`/etc/gitlab/gitlab.rb`の値が使用されます。

パッケージの更新の一環として、`EXTERNAL_URL`変数が誤って設定されている場合、警告なしに`/etc/gitlab/gitlab.rb`の既存の値が置き換えられます。そのため、変数をグローバルに設定するのではなく、インストールコマンドに具体的に渡すことをお勧めします:

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

## GitLabの相対URLを設定する {#configure-a-relative-url-for-gitlab}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< alert type="warning" >}}

GitLabの相対URLを設定すると、[Geoに関する既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)と[テストの制限](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)が発生します。

{{< /alert >}}

GitLabを独自の（サブ）ドメインにインストールすることをおすすめしますが、不可能な場合があります。その場合、GitLabは、たとえば`https://example.com/gitlab`のように、相対URLの下にインストールすることもできます。

URLを変更すると、すべてのリモートURLも変更されるため、GitLabインスタンスを指すローカルリポジトリで手動で編集する必要があります。

これらの手順は、Linuxパッケージインストール用です。自己コンパイル（ソース）インストールの手順については、[相対URLの下にGitLabをインストールする](https://docs.gitlab.com/install/relative_url/)を参照してください。

GitLabで相対URLを有効にするには:

1. `external_url`を`/etc/gitlab/gitlab.rb`に設定します:

   ```ruby
   external_url "https://example.com/gitlab"
   ```

   この例では、GitLabが提供される相対URLは`/gitlab`です。好みに合わせて変更してください。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

何か問題が発生した場合は、[トラブルシューティングセクション](#relative-url-troubleshooting)を参照してください。

## ルート以外のユーザーから外部設定ファイルを読み込む {#load-external-configuration-file-from-non-root-user}

Linuxパッケージインストールは、`/etc/gitlab/gitlab.rb`ファイルからすべての設定を読み込みます。このファイルには厳密なファイル権限があり、`root`ユーザーが所有しています。厳密な権限と所有権の理由は、`/etc/gitlab/gitlab.rb`が`gitlab-ctl reconfigure`中に`root`ユーザーによってRubyコードとして実行されているためです。これは、`/etc/gitlab/gitlab.rb`への書き込みアクセス権を持つユーザーが、`root`によってコードとして実行される設定を追加できることを意味します。

特定の組織では、ルートユーザーとしてではなく、設定ファイルへのアクセスが許可されています。ファイルへのパスを指定することにより、外部設定ファイルを`/etc/gitlab/gitlab.rb`内に含めることができます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   from_file "/home/admin/external_gitlab.rb"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`from_file`を使用する場合:

- `from_file`を使用して`/etc/gitlab/gitlab.rb`に含めるコードは、GitLabをリ設定すると、`root`権限で実行されます。
- `from_file`の後に`/etc/gitlab/gitlab.rb`で設定された設定は、含まれているファイルからの設定よりも優先されます。

## ファイルから証明書を読み取ります {#read-certificate-from-file}

証明書を含むファイルは、個別のファイルとして保存し、`sudo gitlab-ctl reconfigure`の実行時にメモリーに読み込むことができます。証明書を含むファイルは、平文である必要があります。

この例では、[PostgreSQLデータベースサーバー証明書](database.md#configuring-ssl)は、`/etc/gitlab/gitlab.rb`に直接コピーアンドペーストするのではなく、ファイルから直接読み取ります。

```ruby
postgresql['internal_certificate'] = File.read('/path/to/server.crt')
```

## `git_data_dirs`からの移行 {#migrating-from-git_data_dirs}

18.0以降、`git_data_dirs`は、Gitalyストレージの場所を設定するためのサポート対象の手段ではなくなります。`git_data_dirs`を明示的に定義する場合は、設定を移行する必要があります。

たとえば、Gitalyサービスの場合、`/etc/gitlab/gitlab.rb`設定が次のようになっているとします:

```ruby
git_data_dirs({
  "default" => {
    "path" => "/mnt/nas/git-data"
   }
})
```

代わりに、`gitaly['configuration']`で設定を再定義する必要があります。以前は内部的に追加されていたため、`/repositories`サフィックスをパスに追加する必要があることに注意してください。

```ruby
gitaly['configuration'] = {
  storage: [
    {
      name: 'default',
      path: '/mnt/nas/git-data/repositories',
    },
  ],
}
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`path`の親ディレクトリもOmnibusで管理する必要があることに注意することが重要です。上記の例に従って、Omnibusはリ設定時に`/mnt/nas/git-data`の権限を変更する必要があり、ランタイム中にそのディレクトリにデータを保存する場合があります。この動作を可能にする適切な`path`を選択する必要があります。

<!-- vale gitlab_base.SubstitutionWarning = YES -->

RailsおよびSidekiqクライアントの場合、`/etc/gitlab/gitlab.rb`設定が次のようになっているとします:

```ruby
git_data_dirs({
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
   }
})
```

代わりに、`gitlab_rails['repositories_storages']`で設定を再定義する必要があります:

```ruby
gitlab_rails['repositories_storages'] = {
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
  }
}
```

## 代替ディレクトリにGitデータを保存する {#store-git-data-in-an-alternative-directory}

デフォルトでは、Linuxパッケージインストールは、Gitリポジトリデータを`/var/opt/gitlab/git-data/repositories`に保存し、Gitalyサービスは`unix:/var/opt/gitlab/gitaly/gitaly.socket`でリッスンします。

ディレクトリの場所を変更するには、

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

   複数のGitデータディレクトリを追加することもできます:

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
       {
         name: 'alternative',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。すでに`/var/opt/gitlab/git-data`に既存のGitリポジトリがある場合は、それらを新しい場所に移動できます:
   1. 移動中にユーザーがリポジトリに書き込むのを防ぎます:

      ```shell
      sudo gitlab-ctl stop
      ```

   1. リポジトリを新しい場所に同期します。`repositories`の背後にスラッシュ_はありません_が、`git-data`の背後にはスラッシュ_があります_:

      ```shell
      sudo rsync -av --delete /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/
      ```

   1. 必要なプロセスを開始し、誤った権限を修正するために、リ設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. `/mnt/nas/git-data/`のディレクトリレイアウトを再確認してください。予想される出力は`repositories`である必要があります:

      ```shell
      sudo ls /mnt/nas/git-data/
      ```

   1. GitLabを起動し、Webインターフェースでリポジトリを参照できることを確認します:

      ```shell
      sudo gitlab-ctl start
      ```

別のサーバーでGitalyを実行している場合は、[Gitalyの設定に関するドキュメント](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients)を参照してください。

すべてのリポジトリを移動するのではなく、既存のリポジトリストレージ間で特定のプロジェクトを移動する場合は、[プロジェクトAPIの編集](https://docs.gitlab.com/api/projects/#edit-project)エンドポイントを使用し、`repository_storage`属性を指定します。

## Gitユーザーまたはグループの名前を変更する {#change-the-name-of-the-git-user-or-group}

{{< alert type="warning" >}}

既存のインストールのユーザーまたはグループを変更することはお勧めしません。予測できない副次効果が発生する可能性があるためです。

{{< /alert >}}

デフォルトでは、Linuxパッケージインストールは、Git GitLab Shellログイン、Gitデータ自体の所有権、およびWebインターフェースでのSSH URL生成にユーザー名`git`を使用します。同様に、`git`グループは、Gitデータのグループ所有権に使用されます。

新しいLinuxパッケージインストールでユーザーとグループを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   user['username'] = "gitlab"
   user['group'] = "gitlab"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

既存のインストールのユーザー名を変更する場合、リ設定の実行ではネストされたディレクトリの所有権は変更されないため、手動で変更する必要があります。

少なくとも、リポジトリとアップロードディレクトリの所有権を変更する必要があります:

```shell
sudo chown -R gitlab:gitlab /var/opt/gitlab/git-data/repositories
sudo chown -R gitlab:gitlab /var/opt/gitlab/gitlab-rails/uploads
```

## 数値ユーザーとグループ識別子を指定する {#specify-numeric-user-and-group-identifiers}

Linuxパッケージインストールは、GitLab、PostgreSQLデータベース、Redis、NGINXなどのユーザーを作成します。これらのユーザーの数値識別子を指定するには:

1. 古いユーザーとグループの識別子を書き留めてください。後で必要になる可能性があります:

   ```shell
   sudo cat /etc/passwd
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、必要な識別子を変更します:

   ```ruby
   user['uid'] = 1234
   user['gid'] = 1234
   postgresql['uid'] = 1235
   postgresql['gid'] = 1235
   redis['uid'] = 1236
   redis['gid'] = 1236
   web_server['uid'] = 1237
   web_server['gid'] = 1237
   registry['uid'] = 1238
   registry['gid'] = 1238
   mattermost['uid'] = 1239
   mattermost['gid'] = 1239
   prometheus['uid'] = 1240
   prometheus['gid'] = 1240
   ```

1. GitLabを停止し、リ設定してから起動します:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl start
   ```

1. オプション。`user['uid']`と`user['gid']`を変更する場合は、Linuxパッケージで直接管理されていないファイルのUID/識別子を必ず更新してください（ログなど）:

   ```shell
   find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   ```

## ユーザーとグループのアカウント管理を無効にする {#disable-user-and-group-account-management}

デフォルトでは、Linuxパッケージインストールは、システムユーザーとグループのアカウントを作成し、情報を最新の状態に保ちます。これらのシステムアカウントは、パッケージのさまざまなコンポーネントを実行します。ほとんどのユーザーは、この動作を変更する必要はありません。ただし、システムアカウントが他のソフトウェア（LDAPなど）によって管理されている場合は、GitLabパッケージによって行われるアカウント管理を無効にする必要がある場合があります。

デフォルトでは、Linuxパッケージインストールは、次のユーザーとグループが存在することを想定しています:

| Linuxユーザーとグループ | 必須                                | 説明                                                           | デフォルトのホームディレクトリ       | デフォルトのShell |
|----------------------|-----------------------------------------|-----------------------------------------------------------------------|------------------------------|---------------|
| `git`                | はい                                     | GitLabユーザー/グループ                                                     | `/var/opt/gitlab`            | `/bin/sh`     |
| `gitlab-www`         | はい                                     | Webサーバーのユーザー/グループ                                                 | `/var/opt/gitlab/nginx`      | `/bin/false`  |
| `gitlab-prometheus`  | はい                                     | PrometheusモニタリングおよびさまざまなexporterのPrometheusユーザー/グループ | `/var/opt/gitlab/prometheus` | `/bin/sh`     |
| `gitlab-redis`       | Redisがパッケージ化されている場合のみ      | GitLabのRedisユーザー/グループ                                           | `/var/opt/gitlab/redis`      | `/bin/false`  |
| `gitlab-psql`        | PostgreSQLデータベースがパッケージ化されている場合のみ | PostgreSQLデータベースユーザー/グループ                                                 | `/var/opt/gitlab/postgresql` | `/bin/sh`     |
| `gitlab-consul`      | GitLab Consulを使用している場合のみ           | GitLab Consulのユーザー/グループ                                              | `/var/opt/gitlab/consul`     | `/bin/sh`     |
| `registry`           | GitLabレジストリを使用している場合のみ         | GitLabレジストリのユーザー/グループ                                            | `/var/opt/gitlab/registry`   | `/bin/sh`     |
| `mattermost`         | GitLab Mattermostを使用している場合のみ       | GitLab Mattermostのユーザー/グループ                                          | `/var/opt/gitlab/mattermost` | `/bin/sh`     |
| `gitlab-backup`      | `gitlab-backup-cli`を使用する場合のみ     | GitLabバックアップCliユーザー                                                | `/var/opt/gitlab/backups`    | `/bin/sh`     |

ユーザーおよびグループアカウント管理を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   manage_accounts['enable'] = false
   ```

1. オプション。異なるユーザー/グループ名を使用することもできますが、その場合はユーザー/グループの詳細を指定する必要があります:

   ```ruby
   # GitLab
   user['username'] = "git"
   user['group'] = "git"
   user['shell'] = "/bin/sh"
   user['home'] = "/var/opt/custom-gitlab"

   # Web server
   web_server['username'] = 'webserver-gitlab'
   web_server['group'] = 'webserver-gitlab'
   web_server['shell'] = '/bin/false'
   web_server['home'] = '/var/opt/gitlab/webserver'

   # Prometheus
   prometheus['username'] = 'gitlab-prometheus'
   prometheus['group'] = 'gitlab-prometheus'
   prometheus['shell'] = '/bin/sh'
   prometheus['home'] = '/var/opt/gitlab/prometheus'

   # Redis (not needed when using external Redis)
   redis['username'] = "redis-gitlab"
   redis['group'] = "redis-gitlab"
   redis['shell'] = "/bin/false"
   redis['home'] = "/var/opt/redis-gitlab"

   # Postgresql (not needed when using external Postgresql)
   postgresql['username'] = "postgres-gitlab"
   postgresql['group'] = "postgres-gitlab"
   postgresql['shell'] = "/bin/sh"
   postgresql['home'] = "/var/opt/postgres-gitlab"

   # Consul
   consul['username'] = 'gitlab-consul'
   consul['group'] = 'gitlab-consul'
   consul['dir'] = "/var/opt/gitlab/registry"

   # Registry
   registry['username'] = "registry"
   registry['group'] = "registry"
   registry['dir'] = "/var/opt/gitlab/registry"
   registry['shell'] = "/usr/sbin/nologin"

   # Mattermost
   mattermost['username'] = 'mattermost'
   mattermost['group'] = 'mattermost'
   mattermost['home'] = '/var/opt/gitlab/mattermost'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ユーザーのホームディレクトリを移動する {#move-the-home-directory-for-a-user}

GitLabユーザーの場合、パフォーマンスを向上させるために、ホームディレクトリはローカルディスクに設定し、NFSのような共有ストレージには設定しないことをお勧めします。NFSで設定すると、GitリクエストはGit設定を読み取りるために別のネットワークリクエストを行う必要があり、Git操作のレイテンシーが増加します。

既存のホームディレクトリを移動するには、GitLabサービスを停止する必要があり、停止時間が必要です:

1. GitLabを停止します:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Runitサーバーを停止します:

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. ホームディレクトリを変更します:

   ```shell
   sudo usermod -d /path/to/home <username>
   ```

   既存のデータがある場合は、手動で新しい場所にコピー/rsyncする必要があります:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   user['home'] = "/var/opt/custom-gitlab"
   ```

1. Runitサーバーを起動します:

   ```shell
   sudo systemctl start gitlab-runsvdir
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ストレージディレクトリの管理を無効にする {#disable-storage-directories-management}

Linuxパッケージは、必要なすべてのディレクトリを正しい所有権と権限で作成し、これを最新の状態に保つようにしています。

一部のディレクトリには大量のデータが保持されているため、特定の設定では、それらのディレクトリはNFS（またはその他の）共有にマウントされている可能性が最も高くなります。

一部のマウントタイプでは、ルートユーザー（初期セットアップのデフォルトユーザー）によるディレクトリの自動作成が許可されていません。たとえば、共有で`root_squash`が有効になっているNFSなどです。これを回避するために、Linuxパッケージは、ディレクトリのオーナーユーザーを使用してそれらのディレクトリを作成しようとします。

### `/etc/gitlab`ディレクトリの管理を無効にする {#disable-the-etcgitlab-directory-management}

`/etc/gitlab`ディレクトリがマウントされている場合は、そのディレクトリの管理をオフにすることができます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   manage_storage_directories['manage_etc'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### `/var/opt/gitlab`ディレクトリの管理を無効にする {#disable-the-varoptgitlab-directory-management}

すべてのGitLabストレージディレクトリを個別のマウントにマウントする場合は、ストレージディレクトリの管理を完全に無効にする必要があります。

Linuxパッケージインストールでは、これらのディレクトリがファイルシステムに存在することを想定しています。この設定が設定されている場合は、正しい権限を作成して設定するのはあなた次第です。

この設定を有効にすると、次のディレクトリの作成が防止されます:

| デフォルトの場所                                       | 権限 | 所有権        | 目的 |
|--------------------------------------------------------|-------------|------------------|---------|
| `/var/opt/gitlab/git-data`                             | `2770`      | `git:git`        | リポジトリのディレクトリを保持します |
| `/var/opt/gitlab/git-data/repositories`                | `2770`      | `git:git`        | Gitリポジトリを保持します |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`      | `git:gitlab-www` | 大規模なオブジェクトディレクトリを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`      | `git:git`        | CIアーティファクトを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`      | `git:git`        | 外部マージリクエストの差分を保持します |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`      | `git:git`        | LFSオブジェクトを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`      | `git:git`        | パッケージリポジトリを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`      | `git:git`        | 依存プロキシを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`      | `git:git`        | Terraformの状態を保持します |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`      | `git:git`        | アップロードされたセキュアファイルを保持します |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`      | `git:gitlab-www` | ユーザーページを保持します |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`      | `git:git`        | ユーザーの添付ファイルを保持します |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`      | `git:git`        | CIビルドログを保持します |
| `/var/opt/gitlab/.ssh`                                 | `0700`      | `git:git`        | 認証キーを保持します |

ストレージディレクトリの管理を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 指定されたファイルシステムがマウントされた後にのみ、Linuxパッケージインストールサービスを開始する {#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted}

Linuxパッケージインストールサービス（NGINX、Redis、Pumaなど）が、指定されたファイルシステムがマウントされる前に開始されないようにする場合は、`high_availability['mountpoint']`設定を設定できます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< alert type="note" >}}

   マウントポイントが存在しない場合、GitLabはリ設定に失敗します。

   {{< /alert >}}

## ランタイムディレクトリを設定する {#configure-the-runtime-directory}

Prometheusモニタリングが有効になっている場合、GitLab Exporterは、各Pumaプロセス（Railsメトリクス）の測定を実行します。各Pumaプロセスは、コントローラーリクエストごとに一時的な場所にメトリクスファイルを書き込む必要があります。次に、Prometheusはこれらのファイルをすべて収集し、それらの値を処理します。

ディスクI/Oの作成を回避するために、Linuxパッケージはランタイムディレクトリを使用します。

`reconfigure`中、パッケージは`/run`が`tmpfs`マウントであるかどうかを確認します。そうでない場合は、次の警告が表示され、Railsメトリクスは無効になります:

```plaintext
Runtime directory '/run' is not a tmpfs mount.
```

Railsメトリクスを再度有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集して`tmpfs`マウントを作成します（設定に`=`がないことに注意してください）:

   ```ruby
   runtime_dir '/path/to/tmpfs'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 認証失敗BANを設定する {#configure-a-failed-authentication-ban}

Gitおよびコンテナレジストリに対して[認証失敗BAN](https://docs.gitlab.com/security/rate_limits/#failed-authentication-ban-for-git-and-container-registry)を設定できます。クライアントがBANされると、403エラーコードが返されます。

次の設定を構成できます:

| 設定        | 説明 |
|----------------|-------------|
| `enabled`      | デフォルトでは`false`です。Gitおよびレジストリの認証BANを有効にするには、これを`true`に設定します。 |
| `ip_whitelist` | ブロックしないIP。これらは、Ruby配列で文字列としてフォーマットする必要があります。単一のIPまたはCIDR表記（例: `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`）を使用できます。 |
| `maxretry`     | 指定された時間内にリクエストを実行できる最大回数。 |
| `findtime`     | 失敗したリクエストが拒否リストに追加されるまで、IPに対してカウントできる秒単位の最大時間。 |
| `bantime`      | IPがブロックされる合計時間（秒）。 |

Gitおよびコンテナレジストリの認証BANを構成するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['rack_attack_git_basic_auth'] = {
     'enabled' => true,
     'ip_whitelist' => ["127.0.0.1"],
     'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
     'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
     'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## インストール中の自動キャッシュのクリアを無効にする {#disable-automatic-cache-cleaning-during-installation}

大規模なGitLabインスタンスがある場合、完了に時間がかかるため、`rake cache:clear`タスクを実行したくない場合があります。デフォルトでは、キャッシュクリアタスクは再構成中に自動的に実行されます。

インストール中に自動キャッシュのクリアを無効にするには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # This is an advanced feature used by large gitlab deployments where loading
   # whole RAILS env takes a lot of time.
   gitlab_rails['rake_cache_clear'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Sentryを使用したエラーレポートとログ記録 {#error-reporting-and-logging-with-sentry}

{{< alert type="warning" >}}

GitLab 17.0以降、Sentryバージョン21.5.0以降のみがサポートされます。ホストするSentryインスタンスの以前のバージョンを使用している場合は、GitLab環境からのエラーの収集を継続するために、[Sentryをアップグレード](https://develop.sentry.dev/self-hosted/releases/)する必要があります。

{{< /alert >}}

Sentryは、SaaS（<https://sentry.io/welcome/>）として使用することも、[自分でホスト](https://develop.sentry.dev/self-hosted/)することもできる、オープンソースのエラーレポートおよびログ記録ツールです。

Sentryを構成するには、次の手順に従います:

1. Sentryでプロジェクトを作成します。
1. 作成したプロジェクトの[データソース名（DSN）](https://docs.sentry.io/concepts/key-terms/dsn-explainer/)を見つけます。
1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<public_key>@<host>/<project_id>'            # value used by the Rails SDK
   gitlab_rails['sentry_clientside_dsn'] = 'https://<public_key>@<host>/<project_id>' # value used by the Browser JavaScript SDK
   gitlab_rails['sentry_environment'] = 'production'
   ```

   [Sentry環境](https://docs.sentry.io/concepts/key-terms/environments/)を使用して、ラボ、開発、ステージング、本番環境など、デプロイされた複数のGitLab環境全体でエラーとイシューを追跡できます。

1. オプション。特定のサーバーから送信されるすべてのイベントにカスタム[Sentryタグ付け](https://docs.sentry.io/concepts/key-terms/enrich-data/)を設定するには、環境変数`GITLAB_SENTRY_EXTRA_TAGS`を設定できます。この変数は、そのサーバーからのすべての例外に対してSentryに渡されるタグ付けを表すJSONエンコードされたハッシュです。

   たとえば、次のように設定するとします:

   ```ruby
   gitlab_rails['env'] = {
     'GITLAB_SENTRY_EXTRA_TAGS' => '{"stage": "main"}'
   }
   ```

   `stage`タグに`main`の値が追加されます。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## CDN URLを設定する {#set-a-content-delivery-network-url}

`gitlab_rails['cdn_host']`を使用して、コンテンツ配信ネットワーク（CDN）またはアセットホストで静的アセットをサービスします。これにより、[Railsアセットホスト](https://guides.rubyonrails.org/configuring.html#config-asset-host)が構成されます。

CDN/アセットホストを設定するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['cdn_host'] = 'https://mycdnsubdomain.fictional-cdn.com'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

アセットホストとして機能するように共通サービスを構成するための追加ドキュメントは、[このイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5708)で追跡されます。

## コンテンツセキュリティポリシーを設定する {#set-a-content-security-policy}

コンテンツセキュリティポリシー（CSP）を設定することは、JavaScriptクロスサイトスクリプティング（XSS）攻撃を阻止するのに役立ちます。詳細については、[CSPに関するMozillaのドキュメント](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)を参照してください。

[インラインJavaScriptを使用したCSPとnonce-source](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src)は、GitLab.comで利用できます。GitLabセルフマネージドでは、[デフォルトで構成されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/30720)。

{{< alert type="note" >}}

CSPルールを不適切に設定すると、GitLabが正常に動作しなくなる可能性があります。ポリシーを実際にロールアウトしていく前に、`report_only`を`true`に変更して設定をテストするとよいかもしれません。

{{< /alert >}}

CSPを追加するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false
   }
   ```

   CSPの安全なデフォルト値は、GitLabにより自動的に提供されます。ディレクティブに`<default_value>`値を明示的に設定することは、値を設定しないことと同じであり、デフォルト値が使用されます。

   カスタムCSPを追加するには、次のようにします:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false,
       directives: {
         default_src: "'none'",
         script_src: "https://example.com"
       }
   }
   ```

   明示的に構成されていないディレクティブには、セキュアなデフォルト値が使用されます。

   CSPディレクティブを未設定にするには、`false`の値を設定します。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ホストヘッダー攻撃を防ぐために許可されるホストを設定する {#set-allowed-hosts-to-prevent-host-header-attacks}

GitLabが意図したものとは異なるホストヘッダーを受け入れないようにするには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['allowed_hosts'] = ['gitlab.example.com']
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`allowed_hosts`を構成しなくても、GitLabで既知のセキュリティイシューはありませんが、潜在的な[HTTPホストヘッダー攻撃](https://portswigger.net/web-security/host-header)に対する多層防御のために推奨されます。

Apacheなどのカスタム外部プロキシを使用している場合は、localhostアドレスまたは名前（`localhost`または`127.0.0.1`）を追加する必要がある場合があります。Workhorseへのプロキシを介して渡される潜在的なHTTPホストヘッダー攻撃を軽減するために、外部プロキシにフィルターを追加する必要があります。

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1', 'localhost']
```

## セッションクッキーの設定 {#session-cookie-configuration}

生成されたWebセッションクッキー値のプレフィックスを変更するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['session_store_session_cookie_token_prefix'] = 'custom_prefix_'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

デフォルト値は空の文字列`""`です。

## 平文ストレージなしでコンポーネントに機密設定を提供する {#provide-sensitive-configuration-to-components-without-plain-text-storage}

一部のコンポーネントは、`gitlab.rb`で`extra_config_command`オプションを公開します。これにより、外部スクリプトは、平文ストレージから読み取るのではなく、動的にシークレットを提供できます。

使用可能なオプションは次のとおりです:

| `gitlab.rb`の設定                          | 責任 |
|----------------------------------------------|----------------|
| `redis['extra_config_command']`              | Redisサーバーの設定ファイルに追加の設定を提供します。 |
| `gitlab_rails['redis_extra_config_command']` | GitLab Railsアプリケーションで使用されるRedis設定ファイルに追加の設定を提供します。（`resque.yml`、`redis.yml`、`redis.<redis_instance>.yml`ファイル） |
| `gitlab_rails['db_extra_config_command']`    | GitLab Railsアプリケーションで使用されるDB設定ファイルに追加の設定を提供します。（`database.yml`） |
| `gitlab_kas['extra_config_command']`         | Kubernetes（KAS）用のGitLabエージェントサーバーに追加の設定を提供します。 |
| `gitlab_workhorse['extra_config_command']`   | GitLab Workhorseに追加の設定を提供します。 |
| `gitlab_exporter['extra_config_command']`    | GitLabエクスポーターに追加の設定を提供します。 |

これらのオプションのいずれかに割り当てられた値は、必要な形式の機密設定をSTDOUTに書き込む実行可能実行可能スクリプトへの絶対パスである必要があります。コンポーネント:

1. 指定されたスクリプトを実行します。
1. ユーザーとデフォルトの設定ファイルによって設定された値を、スクリプトによって出力された値に置き換えます。

### RedisサーバーおよびクライアントコンポーネントにRedisパスワードを提供する {#provide-redis-password-to-redis-server-and-client-components}

例として、以下のスクリプトと`gitlab.rb`スニペットを使用して、RedisサーバーとRedisへの接続が必要なコンポーネントにパスワードを指定できます。

{{< alert type="note" >}}

Redisサーバーにパスワードを指定する場合、このメソッドは、ユーザーが`gitlab.rb`ファイルに平文パスワードを保持しないようにするだけです。パスワードは、`/var/opt/gitlab/redis/redis.conf`にあるRedisサーバー設定ファイルに平文で記述されます。

{{< /alert >}}

1. 以下のスクリプトを`/opt/generate-redis-conf`として保存します

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'json'
   require 'yaml'

   class RedisConfig
     REDIS_PASSWORD = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch Redis password

     class << self
       def server
         puts "requirepass '#{REDIS_PASSWORD}'"
         puts "masterauth '#{REDIS_PASSWORD}'"
       end

       def rails
         puts YAML.dump({
           'password' => REDIS_PASSWORD
         })
       end

       def kas
         puts YAML.dump({
           'redis' => {
             'password' => REDIS_PASSWORD
           }
         })
       end

       def workhorse
         puts JSON.dump({
           redis: {
             password: REDIS_PASSWORD
           }
         })
       end

       def gitlab_exporter
         puts YAML.dump({
           'probes' => {
             'sidekiq' => {
               'opts' => {
                 'redis_password' => REDIS_PASSWORD
               }
             }
           }
         })
       end
     end
   end

   def print_error_and_exit
     $stdout.puts "Usage: generate-redis-conf <COMPONENT>"
     $stderr.puts "Supported components are: server, rails, kas, workhorse, gitlab_exporter"

     exit 1
   end

   print_error_and_exit if ARGV.length != 1

   component = ARGV.shift
   begin
     RedisConfig.send(component.to_sym)
   rescue NoMethodError
     print_error_and_exit
   end
   ```

1. 上記で作成したスクリプトが実行可能であることを確認します:

   ```shell
   chmod +x /opt/generate-redis-conf
   ```

1. 以下のスニペットを`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   redis['extra_config_command'] = '/opt/generate-redis-conf server'

   gitlab_rails['redis_extra_config_command'] = '/opt/generate-redis-conf rails'
   gitlab_workhorse['extra_config_command'] = '/opt/generate-redis-conf workhorse'
   gitlab_kas['extra_config_command'] = '/opt/generate-redis-conf kas'
   gitlab_exporter['extra_config_command'] = '/opt/generate-redis-conf gitlab_exporter'
   ```

1. `sudo gitlab-ctl reconfigure`を実行します。

### PostgreSQLデータベースのユーザーパスワードをGitLab Railsに提供する {#provide-the-postgresql-user-password-to-gitlab-rails}

例として、以下のスクリプトと設定を使用して、GitLab RailsがPostgreSQLデータベースサーバーへの接続に使用するパスワードを提供できます。

1. 以下のスクリプトを`/opt/generate-db-config`として保存します:

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'yaml'

   db_password = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch DB password

   puts YAML.dump({
    'main' => {
      'password' => db_password
    },
    'ci' => {
      'password' => db_password
    }
   })
   ```

1. 上記で作成したスクリプトが実行可能であることを確認します:

   ```shell
   chmod +x /opt/generate-db-config
   ```

1. 以下のスニペットを`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['db_extra_config_command'] = '/opt/generate-db-config'
   ```

1. `sudo gitlab-ctl reconfigure`を実行します。

## 関連トピック {#related-topics}

- [代理の無効化](https://docs.gitlab.com/api/#disable-impersonation)
- [LDAPサインインを設定](https://docs.gitlab.com/administration/auth/ldap/)
- [スマートカード認証](https://docs.gitlab.com/administration/auth/smartcard/)
- 次のようなもののために[NGINXを設定](nginx.md)します:
  - HTTPSを設定
  - `HTTP`リクエストを`HTTPS`にリダイレクト
  - デフォルトのポートとSSL証明書の場所を変更
  - NGINX listen-addressまたはアドレスを設定
  - カスタムNGINX設定をGitLabサーバーブロックに挿入
  - カスタム設定をNGINX設定に挿入
  - `nginx_status`を有効にする
- [パッケージ化されていないWebサーバーを使用](nginx.md#use-a-non-bundled-web-server)
- [パッケージ化されていないPostgreSQLデータベース管理サーバーを使用](database.md)
- [パッケージ化されていないRedisインスタンスを使用](redis.md)
- [GitLabランタイム環境に`ENV`変数を追加](environment-variables.md)
- [`gitlab.yml`と`application.yml`設定を変更](gitlab.yml.md)
- [SMTP経由でアプリケーションメールを送信](smtp.md)
- [OmniAuth（Google、Twitter、GitHubログイン）を設定](https://docs.gitlab.com/integration/omniauth/)
- [Pumaの設定を調整](https://docs.gitlab.com/administration/operations/puma/)

## トラブルシューティング {#troubleshooting}

### 相対URLのトラブルシューティング {#relative-url-troubleshooting}

相対URL設定（画像がない、応答しないコンポーネントなど）への移動後にGitLabアセットの表示が壊れていることに気付いた場合は、[GitLab](https://gitlab.com/gitlab-org/gitlab)で`Frontend`ラベルが付いたイシューを提起してください。

### エラー: `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]` {#error-mixlibshelloutshellcommandfailed-linux_usergitlab-user-and-group}

[ユーザーのホームディレクトリを移動する](#move-the-home-directory-for-a-user)ときに、runitサービスが停止しておらず、ユーザーのホームディレクトリが手動で移動されていない場合、GitLabは再構成中にエラーが発生します:

```plaintext
account[GitLab user and group] (package::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

ホームディレクトリを移動する前に、必ず`runit`を停止してください。

### Gitユーザーまたはグループの名前を変更した後、GitLabが502を返す {#gitlab-responds-with-502-after-changing-the-name-of-the-git-user-or-group}

既存のインストールで[Gitユーザーまたはグループの名前](#change-the-name-of-the-git-user-or-group)を変更した場合、これにより多くの副次効果が発生する可能性があります。

アクセスできないファイルに関連するエラーをチェックして、その権限を修正してみてください:

```shell
gitlab gitlab-ctl tail -f
```
