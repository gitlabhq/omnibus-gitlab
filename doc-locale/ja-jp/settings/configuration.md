---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージインストールの設定オプション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabを設定するには、`/etc/gitlab/gitlab.rb`ファイルに関連オプションを設定します。

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)には、利用可能なオプションの完全なリストが含まれています。新規インストールでは、`/etc/gitlab/gitlab.rb`にリストされているテンプレートのすべてのオプションがデフォルトで設定されています。

> [!note]
> `/etc/gitlab/gitlab.rb`を編集する際に提供される例は、必ずしもインスタンスのデフォルト設定を反映しているとは限りません。

デフォルト設定のリストについては、[package defaults](https://docs.gitlab.com/administration/package_information/defaults/)を参照してください。

## GitLabの外部URLを設定する {#configure-the-external-url-for-gitlab}

ユーザーに正しいリポジトリクローンリンクを表示するには、ユーザーがリポジトリにアクセスするために使用するURLをGitLabに提供する必要があります。サーバーのIPアドレスを使用することもできますが、FQDN（完全修飾ドメイン名）が推奨されます。GitLab Self-ManagedインスタンスでのDNSの使用に関する詳細は、[DNS documentation](dns.md)を参照してください。

外部URLを変更するには:

1. オプション。外部URLを変更する前に、[カスタムの**ホームページのURL**または**After sign-out path**](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#sign-in-information)を以前に定義したことがあるかを確認してください。これらの設定はどちらも、新しい外部URLを設定した後に意図しないリダイレクトを引き起こす可能性があります。URLを定義している場合は、完全に削除してください。

1. `/etc/gitlab/gitlab.rb`を編集し、`external_url`をお好みのURLに変更します:

   ```ruby
   external_url "http://gitlab.example.com"
   ```

   または、サーバーのIPアドレスを使用することもできます:

   ```ruby
   external_url "http://10.0.0.1"
   ```

   以前の例では、プレーンなHTTPを使用しています。HTTPSを使用したい場合は、[configure SSL](ssl/_index.md)の方法を参照してください。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。しばらくGitLabを使用していた場合、外部URLを変更した後、[invalidate the Markdownキャッシュ](https://docs.gitlab.com/administration/invalidate_markdown_cache/)も行う必要があります。

### インストール時に外部URLを指定する {#specify-the-external-url-at-the-time-of-installation}

Linuxパッケージを使用する場合、`EXTERNAL_URL`環境変数を使用することで、最小限のコマンドでGitLabインスタンスを設定できます。この変数が設定されている場合、自動的に検出され、その値は`gitlab.rb`ファイルに`external_url`として書き込まれます。

`EXTERNAL_URL`環境変数は、パッケージのインストールとアップグレードのみに影響します。通常の再設定実行では、`/etc/gitlab/gitlab.rb`の値が使用されます。

パッケージの更新の一部として、誤って`EXTERNAL_URL`変数を設定していると、`/etc/gitlab/gitlab.rb`の既存の値が警告なしに置き換えられます。そのため、この変数をグローバルに設定するのではなく、インストールコマンドに特定の変数として渡すことを推奨します:

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

## GitLabの相対URLを設定する {#configure-a-relative-url-for-gitlab}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

> [!warning]
> GitLabの相対URLを設定すると、[known issues with Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)と[testing limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)が知られています。

GitLabを独自の（サブ）ドメインにインストールすることを推奨しますが、不可能な場合もあります。その場合、GitLabは相対URLの下にインストールすることもできます。たとえば、`https://example.com/gitlab`です。

URLを変更すると、すべてのリモートURLも変更されるため、GitLabインスタンスを指すローカルリポジトリのURLは手動で編集する必要があります。

これらの手順は、Linuxパッケージのインストールに関するものです。自己コンパイル（ソース）インストールについては、[install GitLab under a relative URL](https://docs.gitlab.com/install/relative_url/)を参照してください。

GitLabで相対URLを有効にするには:

1. `/etc/gitlab/gitlab.rb`で`external_url`を設定します:

   ```ruby
   external_url "https://example.com/gitlab"
   ```

   この例では、GitLabが提供される相対URLは`/gitlab`です。お好みに合わせて変更してください。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

何かイシューがある場合は、[troubleshooting section](#relative-url-troubleshooting)を参照してください。

## root以外のユーザーから外部設定ファイルを読み込む {#load-external-configuration-file-from-non-root-user}

Linuxパッケージのインストールは、すべての設定を`/etc/gitlab/gitlab.rb`ファイルから読み込みます。このファイルは厳密なファイル権限を持ち、`root`ユーザーによって所有されています。厳密な権限と所有権の理由は、`/etc/gitlab/gitlab.rb`が`gitlab-ctl reconfigure`中に`root`ユーザーによってRubyコードとして実行されるためです。これは、`/etc/gitlab/gitlab.rb`への書き込みアクセス権を持つユーザーが、`root`によってコードとして実行される設定を追加できることを意味します。

一部の組織では、設定ファイルへのアクセスは許可されていますが、rootユーザーとしては許可されていません。`/etc/gitlab/gitlab.rb`内に外部設定ファイルを含めるには、ファイルのパスを指定します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   from_file "/home/admin/external_gitlab.rb"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`from_file`を使用する場合:

- `from_file`を使用して`/etc/gitlab/gitlab.rb`に含めるコードは、GitLabを再設定するときに`root`権限で実行されます。
- `from_file`が含まれた後に`/etc/gitlab/gitlab.rb`で設定された設定は、含まれているファイルからの設定よりも優先されます。

## ファイルから証明書を読み込む {#read-certificate-from-file}

証明書は個別のファイルとして保存し、`sudo gitlab-ctl reconfigure`を実行するときにメモリに読み込むことができます。証明書を含むファイルはプレーンテキストである必要があります。

この例では、[PostgreSQL server certificate](database.md#configuring-ssl)は、`/etc/gitlab/gitlab.rb`に直接コピー＆ペーストするのではなく、ファイルから直接読み込まれます。

```ruby
postgresql['internal_certificate'] = File.read('/path/to/server.crt')
```

## `git_data_dirs`からの移行 {#migrating-from-git_data_dirs}

18.0以降、`git_data_dirs`はGitalyのストレージ場所を設定するサポートされた手段ではなくなります。`git_data_dirs`を明示的に定義している場合、設定を移行する必要があります。

たとえば、Gitalyサービスの場合、`/etc/gitlab/gitlab.rb`の設定は次のとおりです:

```ruby
git_data_dirs({
  "default" => {
    "path" => "/mnt/nas/git-data"
   }
})
```

代わりに`gitaly['configuration']`の下で設定を再定義する必要があります。`/repositories`サフィックスはパスに追加する必要があります。これは以前は内部で追加されていたためです。

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

`path`の親ディレクトリもOmnibusによって管理される必要があることに注意してください。上記の例に従い、Omnibusは再設定時に`/mnt/nas/git-data`の権限を変更し、ランタイム中にそのディレクトリにデータを保存する場合があります。この動作を可能にする適切な`path`を選択する必要があります。

<!-- vale gitlab_base.SubstitutionWarning = YES -->

RailsおよびSidekiqクライアントの場合、`/etc/gitlab/gitlab.rb`の設定が次のとおりである場合:

```ruby
git_data_dirs({
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
   }
})
```

代わりに`gitlab_rails['repositories_storages']`の下で設定を再定義する必要があります:

```ruby
gitlab_rails['repositories_storages'] = {
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
  }
}
```

## Gitデータを別のディレクトリに保存する {#store-git-data-in-an-alternative-directory}

デフォルトでは、LinuxパッケージのインストールはGitリポジトリデータを`/var/opt/gitlab/git-data/repositories`の下に保存し、Gitalyサービスは`unix:/var/opt/gitlab/gitaly/gitaly.socket`でリッスンします。

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

1. オプション。`/var/opt/gitlab/git-data`に既存のGitリポジトリがある場合は、新しい場所に移動できます:
   1. リポジトリを移動している間、ユーザーが書き込みできないようにします:

      ```shell
      sudo gitlab-ctl stop
      ```

   1. リポジトリを新しい場所に同期します。`repositories`の後ろにスラッシュは_ありません_が、`git-data`の後ろにはスラッシュが_あります_:

      ```shell
      sudo rsync -av --delete /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/
      ```

   1. 必要なプロセスを開始し、誤った権限を修正するために再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. `/mnt/nas/git-data/`のディレクトリレイアウトを再確認します。予期される出力は`repositories`です:

      ```shell
      sudo ls /mnt/nas/git-data/
      ```

   1. GitLabを開始し、Webインターフェースでリポジトリを参照できることを確認します:

      ```shell
      sudo gitlab-ctl start
      ```

別のサーバーでGitalyを実行している場合は、[the documentation on configuring Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients)を参照してください。

すべてのリポジトリを移動するのではなく、既存のリポジトリストレージ間で特定のプロジェクトを移動したい場合は、[Edit Project API](https://docs.gitlab.com/api/projects/#edit-a-project)エンドポイントを使用し、`repository_storage`属性を指定してください。

## Gitユーザーまたはグループの名前を変更する {#change-the-name-of-the-git-user-or-group}

> [!warning]
> 既存のインストールのユーザーまたはグループを変更することは推奨しません。予期せぬ副次効果を引き起こす可能性があるためです。

デフォルトでは、Linuxパッケージのインストールは、Git Lab Shellログイン、Gitデータ自体の所有権、およびWebインターフェースでのSSH URL生成のためにユーザー名`git`を使用します。同様に、`git`グループはGitデータのグループ所有権に使用されます。

新しいLinuxパッケージのインストールでユーザーとグループを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   user['username'] = "gitlab"
   user['group'] = "gitlab"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

既存のインストールのユーザー名を変更する場合、再設定実行ではネストされたディレクトリの所有権は変更されないため、手動で行う必要があります。

少なくとも、リポジトリとアップロードディレクトリの所有権を変更する必要があります:

```shell
sudo chown -R gitlab:gitlab /var/opt/gitlab/git-data/repositories
sudo chown -R gitlab:gitlab /var/opt/gitlab/gitlab-rails/uploads
```

## 数値ユーザーおよびグループ識別子を指定する {#specify-numeric-user-and-group-identifiers}

Linuxパッケージのインストールは、GitLab、PostgreSQL、Redis、NGINXなどのユーザーを作成します。これらのユーザーの数値識別子を指定するには:

1. 後で必要になる可能性があるため、古いユーザーおよびグループ識別子を書き留めてください:

   ```shell
   sudo cat /etc/passwd
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、必要な識別子をすべて変更します:

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

1. GitLabを停止し、再設定してから起動します:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl start
   ```

1. オプション。`user['uid']`と`user['gid']`を変更する場合、Linuxパッケージによって直接管理されていないファイル（例：ログ）のuid/guidを必ず更新してください:

   ```shell
   find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   ```

## ユーザーおよびグループアカウント管理を無効にする {#disable-user-and-group-account-management}

デフォルトでは、Linuxパッケージのインストールはシステムユーザーとグループアカウントを作成し、情報を更新し続けます。これらのシステムアカウントは、パッケージのさまざまなコンポーネントを実行します。ほとんどのユーザーは、この動作を変更する必要はありません。ただし、システムアカウントが他のソフトウェア（例：LDAP）によって管理されている場合、GitLabパッケージによるアカウント管理を無効にする必要があるかもしれません。

デフォルトでは、Linuxパッケージのインストールは、以下のユーザーとグループが存在することを想定しています:

| Linuxユーザーとグループ | 必須                                | 説明                                                           | デフォルトホームディレクトリ       | デフォルトShell |
|----------------------|-----------------------------------------|-----------------------------------------------------------------------|------------------------------|---------------|
| `git`                | はい                                     | GitLabユーザー/グループ                                                     | `/var/opt/gitlab`            | `/bin/sh`     |
| `gitlab-www`         | はい                                     | Webサーバーユーザー/グループ                                                 | `/var/opt/gitlab/nginx`      | `/bin/false`  |
| `gitlab-prometheus`  | はい                                     | Prometheusモニタリングおよびさまざまなexporter用のPrometheusユーザー/グループ | `/var/opt/gitlab/prometheus` | `/bin/sh`     |
| `gitlab-redis`       | パッケージ化されたRedisを使用する場合のみ      | GitLab用のRedisユーザー/グループ                                           | `/var/opt/gitlab/redis`      | `/bin/false`  |
| `gitlab-psql`        | パッケージ化されたPostgreSQLを使用する場合のみ | PostgreSQLユーザー/グループ                                                 | `/var/opt/gitlab/postgresql` | `/bin/sh`     |
| `gitlab-consul`      | GitLab Consulを使用する場合のみ           | GitLab Consulユーザー/グループ                                              | `/var/opt/gitlab/consul`     | `/bin/sh`     |
| `registry`           | GitLabレジストリを使用する場合のみ         | GitLabレジストリユーザー/グループ                                            | `/var/opt/gitlab/registry`   | `/bin/sh`     |
| `mattermost`         | GitLab Mattermostを使用する場合のみ       | GitLab Mattermostユーザー/グループ                                          | `/var/opt/gitlab/mattermost` | `/bin/sh`     |
| `gitlab-backup`      | `gitlab-backup-cli`を使用する場合のみ     | GitLabバックアップCliユーザー                                                | `/var/opt/gitlab/backups`    | `/bin/sh`     |

ユーザーおよびグループアカウント管理を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   manage_accounts['enable'] = false
   ```

1. オプション。異なるユーザー名/グループ名を使用することもできますが、その場合はユーザー/グループの詳細を指定する必要があります:

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

GitLabユーザーの場合、パフォーマンス向上のため、ホームディレクトリはローカルディスクに設定し、NFSのような共有ストレージには設定しないことを推奨します。NFSに設定すると、GitリクエストがGit設定を読み込むために別のネットワークリクエストを行う必要があり、これによりGit操作のレイテンシーが増加します。

既存のホームディレクトリを移動するには、GitLabサービスを停止する必要があり、ある程度のダウンタイムが発生します:

1. GitLabを停止します:

   ```shell
   sudo gitlab-ctl stop
   ```

1. runitサーバーを停止します:

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. ホームディレクトリを変更します:

   ```shell
   sudo usermod -d /path/to/home <username>
   ```

   既存のデータがある場合は、新しい場所に手動でコピー/rsyncする必要があります:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   user['home'] = "/var/opt/custom-gitlab"
   ```

1. runitサーバーを起動します:

   ```shell
   sudo systemctl start gitlab-runsvdir
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ストレージディレクトリ管理を無効にする {#disable-storage-directories-management}

Linuxパッケージは、必要なすべてのディレクトリを正しい所有権と権限で作成し、これを更新し続けます。

一部のディレクトリには大量のデータが保持されているため、特定のセットアップでは、これらのディレクトリはNFS（または他の）共有にマウントされている可能性が非常に高いです。

一部のマウントタイプでは、rootユーザー（初期設定のデフォルトユーザー）によるディレクトリの自動作成が許可されていません。たとえば、共有で`root_squash`が有効になっているNFSなどです。これを回避するために、Linuxパッケージは、ディレクトリのオーナーユーザーを使用してそれらのディレクトリを作成しようとします。

### `/etc/gitlab`ディレクトリの管理を無効にする {#disable-the-etcgitlab-directory-management}

`/etc/gitlab`ディレクトリがマウントされている場合、そのディレクトリの管理をオフにすることができます:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   manage_storage_directories['manage_etc'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### `/var/opt/gitlab`ディレクトリの管理を無効にする {#disable-the-varoptgitlab-directory-management}

すべてのGitLabストレージディレクトリをそれぞれ別々にマウントしている場合は、ストレージディレクトリの管理を完全に無効にする必要があります。

Linuxパッケージのインストールでは、これらのディレクトリがファイルシステム上に存在することを想定しています。この設定が有効になっている場合、正しい権限を作成および設定するのはユーザーの責任です。

この設定を有効にすると、以下のディレクトリの作成が防止されます:

| デフォルトの場所                                       | 権限 | 所有権        | 目的 |
|--------------------------------------------------------|-------------|------------------|---------|
| `/var/opt/gitlab/git-data`                             | `2770`      | `git:git`        | リポジトリディレクトリを保持する |
| `/var/opt/gitlab/git-data/repositories`                | `2770`      | `git:git`        | Gitリポジトリを保持する |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`      | `git:gitlab-www` | 大規模オブジェクトディレクトリを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`      | `git:git`        | CIアーティファクトを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`      | `git:git`        | 外部マージリクエストの差分を保持する |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`      | `git:git`        | LFSオブジェクトを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`      | `git:git`        | パッケージリポジトリを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`      | `git:git`        | 依存プロキシを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`      | `git:git`        | Terraformステートを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`      | `git:git`        | アップロードされたセキュアファイルを保持する |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`      | `git:gitlab-www` | ユーザーページを保持する |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`      | `git:git`        | ユーザーの添付ファイルを保持する |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`      | `git:git`        | CIビルドログを保持する |
| `/var/opt/gitlab/.ssh`                                 | `0700`      | `git:git`        | 承認済みキーを保持する |

ストレージディレクトリの管理を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 指定されたファイルシステムがマウントされた後にのみLinuxパッケージのインストールサービスを開始する {#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted}

Linuxパッケージのインストールサービス（NGINX、Redis、Pumaなど）が指定されたファイルシステムがマウントされる前に起動するのを防ぎたい場合、`high_availability['mountpoint']`設定を設定できます:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!note]
   > マウントポイントが存在しない場合、GitLabは再設定に失敗します。

## ランタイムディレクトリを設定する {#configure-the-runtime-directory}

Prometheusモニタリングが有効な場合、GitLab Exporterは各Pumaプロセス（Railsメトリクス）の測定を実行します。各Pumaプロセスは、各コントローラーリクエストに対してメトリクスファイルを一時的な場所に書き込む必要があります。次に、Prometheusはこれらのすべてのファイルとプロセス値を収集します。

ディスクI/Oの作成を避けるために、Linuxパッケージはランタイムディレクトリを使用します。

`reconfigure`中に、パッケージは`/run`が`tmpfs`マウントであるかどうかを確認します。そうでない場合、次の警告が表示され、Railsメトリクスは無効になります:

```plaintext
Runtime directory '/run' is not a tmpfs mount.
```

Railsメトリクスを再度有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集して`tmpfs`マウントを作成します（設定には`=`がないことに注意してください）:

   ```ruby
   runtime_dir '/path/to/tmpfs'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 失敗した認証のBANを設定する {#configure-a-failed-authentication-ban}

Gitとコンテナレジストリに対して、[failed authentication ban](https://docs.gitlab.com/security/rate_limits/#failed-authentication-ban-for-git-and-container-registry)を設定できます。クライアントがBANされると、403エラーコードが返されます。

次の設定を設定できます:

| 設定        | 説明 |
|----------------|-------------|
| `enabled`      | デフォルトでは`false`です。これを`true`に設定して、Gitおよびレジストリの認証BANを有効にします。 |
| `ip_whitelist` | ブロックしないIP。それらはRuby配列の文字列としてフォーマットする必要があります。単一のIPまたはCIDR表記を使用できます。たとえば、`["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`です。 |
| `maxretry`     | 指定された時間内にリクエストを行うことができる最大回数。 |
| `findtime`     | 拒否リストに追加される前に、失敗したリクエストがIPに対してカウントできる最大時間（秒単位）。 |
| `bantime`      | IPがブロックされる合計時間（秒単位）。 |

Gitとコンテナレジストリの認証BANを設定するには:

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

## インストール中の自動キャッシュクリーニングを無効にする {#disable-automatic-cache-cleaning-during-installation}

大規模なGitLabインストールの場合、`rake cache:clear`タスクの実行には時間がかかるため、実行したくない場合があります。デフォルトでは、キャッシュクリアタスクは再設定中に自動的に実行されます。

インストール中の自動キャッシュクリーニングを無効にするには:

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

## Sentryによるエラー報告とログ記録 {#error-reporting-and-logging-with-sentry}

> [!warning]
> GitLab 17.0以降では、Sentryバージョン21.5.0以降のみがサポートされます。ホストしているSentryインスタンスの以前のバージョンを使用している場合は、GitLab環境からエラーを収集し続けるために[upgrade Sentry](https://develop.sentry.dev/self-hosted/releases/)する必要があります。

Sentryは、SaaS（<https://sentry.io/welcome/>）として、または[host it yourself](https://develop.sentry.dev/self-hosted/)として使用できるオープンソースのエラー報告およびログ記録ツールです。

Sentryを設定するには:

1. Sentryでプロジェクトを作成します。
1. 作成したプロジェクトの[Data Source Name (DSN)](https://docs.sentry.io/concepts/key-terms/dsn-explainer/)を見つけます。
1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<public_key>@<host>/<project_id>'            # value used by the Rails SDK
   gitlab_rails['sentry_clientside_dsn'] = 'https://<public_key>@<host>/<project_id>' # value used by the Browser JavaScript SDK
   gitlab_rails['sentry_environment'] = 'production'
   ```

   [Sentry environment](https://docs.sentry.io/concepts/key-terms/environments/)は、ラボ、開発、ステージング、本番環境など、複数のデプロイされたGitLab環境全体でエラーとイシューを追跡するために使用できます。

1. オプション。オプション。特定のサーバーから送信されるすべてのイベントにカスタム[Sentryタグ](https://docs.sentry.io/concepts/key-terms/enrich-data/)を設定するには、`GITLAB_SENTRY_EXTRA_TAGS`環境変数を設定できます。この変数は、そのサーバーからのすべての例外に対してSentryに渡されるべきタグを表すJSONエンコードされたハッシュです。

   たとえば、次のように設定すると:

   ```ruby
   gitlab_rails['env'] = {
     'GITLAB_SENTRY_EXTRA_TAGS' => '{"stage": "main"}'
   }
   ```

   `main`の値を持つ`stage`タグが追加されます。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## CDN URLを設定する {#set-a-content-delivery-network-url}

`gitlab_rails['cdn_host']`を使用して、CDN（Content Delivery Network）またはアセットホストで静的アセットをサービスします。これにより、[Rails asset host](https://guides.rubyonrails.org/configuring.html#config-asset-host)を設定します。

CDN/アセットホストを設定するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['cdn_host'] = 'https://mycdnsubdomain.fictional-cdn.com'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

アセットホストとして機能する共通サービスを設定するための追加ドキュメントは、[this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5708)で追跡されます。

## Content-Security-Policyを設定する {#set-a-content-security-policy}

コンテンツセキュリティポリシー（CSP）を設定することは、JavaScriptクロスサイトスクリプティング（XSS）攻撃を阻止するのに役立ちます。詳細については、[the Mozilla documentation on CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)を参照してください。

[CSP and nonce-source withインラインJavaScript](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src)はGitLab.comで利用可能です。GitLab Self-Managedインスタンスでは、[not configured by default](https://gitlab.com/gitlab-org/gitlab/-/issues/30720)です。

> [!note]
> CSPルールを不適切に設定すると、GitLabが正しく機能しなくなる可能性があります。ポリシーを実際にロールアウトしていく前に、`report_only`を`true`に変更して設定をテストするとよいかもしれません。

CSPを追加するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false
   }
   ```

   CSPの安全なデフォルト値は、GitLabにより自動的に提供されます。ディレクティブの`<default_value>`値を明示的に設定することは、値を設定しないことと同等であり、デフォルト値を使用します。

   カスタムCSPを追加するには、次のようにします。

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

   明示的に設定されていないディレクティブには、セキュアなデフォルト値が使用されます。

   CSPディレクティブを解除するには、`false`の値を設定します。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ホストヘッダー攻撃を防ぐために許可されたホストを設定する {#set-allowed-hosts-to-prevent-host-header-attacks}

GitLabが意図しないホストヘッダーを受け入れるのを防ぐには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['allowed_hosts'] = ['gitlab.example.com']
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`allowed_hosts`を設定しないことによって引き起こされるGitLabの既知のセキュリティイシューはありませんが、潜在的な[HTTP Host header attacks](https://portswigger.net/web-security/host-header)に対する多層防御のために推奨されます。

Apacheのようなカスタム外部プロキシを使用する場合、localhostアドレスまたは名前（`localhost`または`127.0.0.1`）を追加する必要があるかもしれません。プロキシを介してworkhorseに渡される潜在的なHTTP Hostヘッダー攻撃を軽減するために、外部プロキシにフィルターを追加する必要があります。

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1', 'localhost']
```

## セッションクッキーの設定 {#session-cookie-configuration}

生成されるWebセッションクッキー値のプレフィックスを変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['session_store_session_cookie_token_prefix'] = 'custom_prefix_'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

デフォルト値は空の文字列`""`です。

## プレーンテキストストレージなしでコンポーネントに機密設定を提供する {#provide-sensitive-configuration-to-components-without-plain-text-storage}

一部のコンポーネントは、`gitlab.rb`に`extra_config_command`オプションを公開しています。これにより、外部スクリプトがプレーンテキストストレージから読み取るのではなく、シークレットを動的に提供できるようになります。

利用可能なオプションは次のとおりです:

| `gitlab.rb`の設定                          | 責任 |
|----------------------------------------------|----------------|
| `redis['extra_config_command']`              | Redisサーバー設定ファイルに追加の設定を提供します。 |
| `gitlab_rails['redis_extra_config_command']` | GitLab Railsアプリケーションで使用されるRedis設定ファイル（`resque.yml`、`redis.yml`、`redis.<redis_instance>.yml`ファイル）に追加の設定を提供します。 |
| `gitlab_rails['db_extra_config_command']`    | GitLab Railsアプリケーションで使用されるDB設定ファイル（`database.yml`）に追加の設定を提供します。 |
| `gitlab_kas['extra_config_command']`         | Kubernetes (KAS) 用のGitLabエージェントサーバーに追加の設定を提供します。 |
| `gitlab_workhorse['extra_config_command']`   | GitLab Workhorseに追加の設定を提供します。 |
| `gitlab_exporter['extra_config_command']`    | GitLab Exporterに追加の設定を提供します。 |

これらのオプションのいずれかに割り当てられる値は、必要な形式で機密設定をSTDOUTに書き込む実行可能スクリプトへの絶対パスである必要があります。コンポーネント:

1. 提供されたスクリプトを実行します。
1. ユーザーおよびデフォルト設定ファイルによって設定された値を、スクリプトによって出力された値で置き換えます。

### RedisサーバーおよびクライアントコンポーネントにRedisパスワードを提供する {#provide-redis-password-to-redis-server-and-client-components}

例として、以下のスクリプトと`gitlab.rb`スニペットを使用して、RedisサーバーおよびRedisに接続する必要があるコンポーネントのパスワードを指定できます。

> [!note]
> Redisサーバーにパスワードを指定する場合、この方法はユーザーが`gitlab.rb`ファイルにプレーンテキストパスワードを持つことを避けるだけです。パスワードは、`/var/opt/gitlab/redis/redis.conf`にあるRedisサーバー設定ファイルにプレーンテキストで書き込まれます。

1. 以下のスクリプトを`/opt/generate-redis-conf`として保存します。

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

1. 上記で作成したスクリプトが実行可能であることを確認してください:

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

### PostgreSQLユーザーパスワードをGitLab Railsに提供する {#provide-the-postgresql-user-password-to-gitlab-rails}

例として、以下のスクリプトと設定を使用して、GitLab RailsがPostgreSQLサーバーへの接続に使用すべきパスワードを提供できます。

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

1. 上記で作成したスクリプトが実行可能であることを確認してください:

   ```shell
   chmod +x /opt/generate-db-config
   ```

1. 以下のスニペットを`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['db_extra_config_command'] = '/opt/generate-db-config'
   ```

1. `sudo gitlab-ctl reconfigure`を実行します。

## 関連トピック {#related-topics}

- [代理の無効化](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)
- [Set up LDAP sign-in](https://docs.gitlab.com/administration/auth/ldap/)
- [スマートカードauthentication](https://docs.gitlab.com/administration/auth/smartcard/)
- 次のようなことのために[Set up NGINX](nginx.md):
  - HTTPSを設定します
  - `HTTP`リクエストを`HTTPS`にリダイレクトします。
  - デフォルトポートとSSL証明書の場所を変更します。
  - NGINXのlisten-addressまたはアドレスを設定します。
  - GitLabサーバーブロックにカスタムNGINX設定を挿入します。
  - NGINX設定にカスタム設定を挿入します。
  - `nginx_status`を有効にします。
- [Use a non-packaged web-server](nginx.md#use-a-non-bundled-web-server)
- [Use a non-packaged PostgreSQLデータベースmanagement server](database.md)
- [Use a non-packaged Redisインスタンス](redis.md)
- [`ENV`変数をGitLabランタイム環境に追加する](environment-variables.md)
- [`gitlab.yml`および`application.yml`設定を変更する](gitlab.yml.md)
- [Send application email via SMTP](smtp.md)
- [Set up OmniAuth (Google, Twitter, GitHub login)](https://docs.gitlab.com/integration/omniauth/)
- [Adjust Puma settings](https://docs.gitlab.com/administration/operations/puma/)

## トラブルシューティング {#troubleshooting}

### 相対URLのトラブルシューティング {#relative-url-troubleshooting}

相対URLの設定に移行した後、GitLabアセットが破損しているように見えるイシュー（画像が見つからない、コンポーネントが応答しないなど）に気づいた場合は、[GitLab](https://gitlab.com/gitlab-org/gitlab)に`Frontend`ラベルを付けてイシューを提起してください。

### エラー: `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]` {#error-mixlibshelloutshellcommandfailed-linux_usergitlab-user-and-group}

[moving the home directory for a user](#move-the-home-directory-for-a-user)の際、runitサービスが停止しておらず、ユーザーのホームディレクトリが手動で移動されていない場合、GitLabは再設定中にエラーに遭遇します:

```plaintext
account[GitLab user and group] (package::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

ホームディレクトリを移動する前に、必ず`runit`を停止してください。

### Gitユーザーまたはグループの名前を変更した後、GitLabが502で応答する {#gitlab-responds-with-502-after-changing-the-name-of-the-git-user-or-group}

既存のインストールで[name of the Git user or group](#change-the-name-of-the-git-user-or-group)を変更した場合、多くの副次効果を引き起こす可能性があります。

アクセスできないファイルに関連するエラーを確認し、その権限を修正してみてください:

```shell
gitlab gitlab-ctl tail -f
```
