---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: バックアップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## Linuxパッケージインストールにおける設定のバックアップと復元 {#backup-and-restore-configuration-on-a-linux-package-installation}

すべてのLinuxパッケージインストール設定は`/etc/gitlab`に保存されます。GitLabアプリケーションのバックアップとは別に、[設定と証明書](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#data-not-included-in-a-backup)のコピーを安全な場所に保管してください。これにより、暗号化されたアプリケーションデータが、それを復号化するために必要なキーと一緒に失われたり、漏洩したり、盗まれたりする可能性が減少します。

特に、`gitlab-secrets.json`ファイル（および場合によっては`gitlab.rb`ファイル）には、SQLデータベース内の機密情報を保護するためのデータベース暗号化キーが含まれています:

- [2要素認証](https://docs.gitlab.com/security/two_factor_authentication/) (2FA)ユーザーシークレット
- [セキュアファイル](https://docs.gitlab.com/ci/secure_files/)

これらのファイルが失われると、2FAユーザーは[GitLabアカウント](https://docs.gitlab.com/user/profile/)へのアクセスを失い、「セキュアな変数」はCI設定から失われます。

設定をバックアップするには、`sudo gitlab-ctl backup-etc`を実行します。これは`/etc/gitlab/config_backup/`にtarアーカイブを作成します。ディレクトリおよびバックアップファイルはrootのみが読み取り可能です。

> [!note]
> `sudo gitlab-ctl backup-etc --backup-path <DIRECTORY>`を実行すると、バックアップが指定されたディレクトリに配置されます。そのディレクトリが存在しない場合は作成されます。絶対パスを推奨します。

毎日のアプリケーションバックアップを作成するには、rootユーザーのcronテーブルを編集します:

```shell
sudo crontab -e -u root
```

cronテーブルがエディタに表示されます。

`/etc/gitlab/`の内容を含むtarファイルを作成するコマンドを入力します。たとえば、バックアップが平日の火曜日（2日目）から土曜日（6日目）まで毎日朝に実行されるようにスケジュールします:

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

> [!note]
> `/secret/gitlab/backups/`が存在することを確認してください。

tarファイルは次のように抽出できます。

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

設定バックアップを復元した後は、`sudo gitlab-ctl reconfigure`を実行することを忘れないでください。

> [!note]
> マシンのSSHホストキーは、`/etc/ssh/`の別の場所に保存されます。完全なマシン復元を実行する必要がある場合は、中間者攻撃の警告を避けるために、[これらのキーもバックアップして復元する](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)ようにしてください。

### 設定バックアップのライフタイムを制限する（古いバックアップを削除） {#limit-backup-lifetime-for-configuration-backups-prune-old-backups}

GitLab設定バックアップは、[GitLabアプリケーションバックアップに使用される](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#limit-backup-lifetime-for-local-files-prune-old-backups)のと同じ`backup_keep_time`設定を使用して削除できます。

この設定を利用するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

デフォルトの`backup_keep_time`設定は`0`で、すべてのGitLab設定とアプリケーションバックアップを保持します。

`backup_keep_time`が設定されると、`sudo gitlab-ctl backup-etc --delete-old-backups`を実行して、現在の時刻から`backup_keep_time`を差し引いたよりも古いすべてのバックアップを削除できます。

既存のすべてのバックアップを保持したい場合は、パラメータ`--no-delete-old-backups`を指定できます。

> [!warning]
> パラメータが指定されない場合、デフォルトは`--delete-old-backups`であり、`backup_keep_time`が0より大きい場合、現在の時刻から`backup_keep_time`を差し引いたよりも古いバックアップはすべて削除されます。

## アプリケーションバックアップの作成 {#creating-an-application-backup}

リポジトリとGitLabメタデータのバックアップを作成するには、[バックアップ作成ドキュメント](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)に従ってください。

バックアップ作成により、`/var/opt/gitlab/backups`にtarファイルが保存されます。

GitLabバックアップを別のディレクトリに保存したい場合は、`/etc/gitlab/gitlab.rb`に次の設定を追加して`sudo gitlab-ctl
reconfigure`を実行します:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Dockerコンテナ内のGitLabインスタンスのバックアップを作成する {#creating-backups-for-gitlab-instances-in-docker-containers}

> [!warning]
> インストールでPgBouncerを使用している場合、パフォーマンス上の理由、またはPatroniクラスターとともに使用する場合に、バックアップコマンドには[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

コマンドの前に`docker exec -t <your container name>`を付加することで、ホスト上でバックアップをスケジュールできます。

アプリケーションのバックアップ:

```shell
docker exec -t <your container name> gitlab-backup
```

設定とシークレットのバックアップ:

```shell
docker exec -t <your container name> /bin/sh -c 'gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/'
```

> [!note]
> これらのバックアップをコンテナ外に保持するには、以下のディレクトリにボリュームをマウントします:

1. `/secret/gitlab/backups`。
1. `/var/opt/gitlab`（[すべてのアプリケーションデータ](https://docs.gitlab.com/install/docker/installation/#create-a-directory-for-the-volumes)用）。これにはバックアップが含まれます。
1. `/var/opt/gitlab/backups`（オプション）。The `gitlab-backup`ツールは[デフォルトで](#creating-an-application-backup)このディレクトリに書き込みます。このディレクトリは`/var/opt/gitlab`内にネストされた状態ですが、[Dockerはこれらのマウントをソート](https://github.com/moby/moby/pull/8055)するため、互いに連携して動作できます。

   この設定により、たとえば次のことが可能になります:

   - 通常のローカルストレージ上のアプリケーションデータ（2番目のマウント経由）。
   - ネットワークストレージ上のバックアップボリューム（3番目のマウント経由）。

## アプリケーションバックアップの復元 {#restoring-an-application-backup}

[復元ドキュメント](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/)を参照してください。

## パッケージ化されていないデータベースを使用したバックアップと復元 {#backup-and-restore-using-non-packaged-database}

パッケージ化されていないデータベースを使用している場合は、[パッケージ化されていないデータベースの使用に関するドキュメント](database.md#using-a-non-packaged-postgresql-database-management-server)を参照してください。

## リモート（クラウド）ストレージへのバックアップをアップロード {#upload-backups-to-remote-cloud-storage}

詳細については、[バックアップドキュメント](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage)を確認してください。

## バックアップディレクトリを手動で管理する {#manually-manage-backup-directory}

Linuxパッケージインストールでは、`gitlab_rails['backup_path']`で設定されたバックアップディレクトリが作成されます。そのディレクトリはGitLabを実行しているユーザーが所有し、そのユーザーのみがアクセスできるように厳格なパーミッションが設定されています。そのディレクトリにはバックアップアーカイブが保持され、それらには機密情報が含まれています。一部の組織では、たとえばバックアップアーカイブをオフサイトに送るため、パーミッションを異なるものにする必要があります。

バックアップディレクトリ管理を無効にするには、`/etc/gitlab/gitlab.rb`で次のように設定します:

```ruby
gitlab_rails['manage_backup_path'] = false
```

> [!warning]
> この設定オプションを設定した場合、`gitlab_rails['backup_path']`で指定されたディレクトリを作成し、`user['username']`で指定されたユーザーに正しいアクセスを許可するパーミッションを設定するのはユーザーの責任です。これに失敗すると、GitLabはバックアップアーカイブを作成できません。

## コンテナレジストリメタデータデータベースバックアップ認証情報 {#container-registry-metadata-database-backup-credentials}

{{< history >}}

- GitLab [18.11](https://gitlab.com/groups/gitlab-org/-/work_items/21179)で導入されました。

{{< /history >}}

`gitlab-backup`を使用してコンテナレジストリメタデータデータベースをバックアップする場合、GitLabはレジストリPostgreSQLデータベースに接続するための認証情報を保存する必要があります。これらの認証情報は、ディスク上の制限されたファイルに書き込まれ、ランタイム時にバックアップツールによって取得されます。

### バックアップロールを有効にする {#enable-the-backup-role}

レジストリ認証情報ファイルの作成を有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['backup_role'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 単一ノードインストール {#single-node-installations}

コンテナレジストリがGitLabとコロケーションされている単一ノードインストールでは、データベース接続設定は`registry['database']`設定から自動的に導き出されます。バックアップおよび復元するPostgreSQLロールの認証情報のみを設定する必要があります:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['backup_role'] = true

   # Credentials for the PostgreSQL role used when creating backups
   gitlab_rails['backup_registry_user']     = 'registry_backup'  # default
   gitlab_rails['backup_registry_password'] = '<backup_password>'

   # Credentials for the PostgreSQL role used when restoring backups
   gitlab_rails['restore_registry_user']     = 'registry_restore'  # default
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### マルチノードインストール（専用バックアップノード） {#multi-node-installations-dedicated-backup-node}

マルチノードインストール、またはコンテナレジストリがコロケーションされていない専用のバックアップノードで`gitlab-backup`を実行する場合は、接続の詳細を明示的に指定します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['backup_role'] = true

   gitlab_rails['backup_registry']['database_connection'] = {
     'host'        => 'registry-db.example.com',
     'port'        => 5432,           # default
     'dbname'      => 'registry',     # default
     'sslmode'     => 'require',
     'sslcert'     => '/path/to/client.crt',
     'sslkey'      => '/path/to/client.key',
     'sslrootcert' => '/path/to/ca.crt'
   }

   gitlab_rails['backup_registry_user']      = 'registry_backup'
   gitlab_rails['backup_registry_password']  = '<backup_password>'
   gitlab_rails['restore_registry_user']     = 'registry_restore'
   gitlab_rails['restore_registry_password'] = '<restore_password>'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 認証情報ファイル {#credential-files}

`sudo gitlab-ctl reconfigure`の後、以下のファイルが`/opt/gitlab/etc/gitlab-backup/env/`の下に作成されます:

| ファイル | 書き込まれた環境変数 |
| ---- | ----------------------------- |
| `env-connection` | `REGISTRY_DATABASE_HOST`, `REGISTRY_DATABASE_PORT`, `REGISTRY_DATABASE_NAME`, `REGISTRY_DATABASE_SSLMODE`, `REGISTRY_DATABASE_SSLCERT`, `REGISTRY_DATABASE_SSLKEY`, `REGISTRY_DATABASE_SSLROOTCERT` |
| `env-backup_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD`（バックアップロールの認証情報） |
| `env-restore_user` | `REGISTRY_DATABASE_USER`, `REGISTRY_DATABASE_PASSWORD`（復元ロールの認証情報） |

すべてのファイルは`root:root`が所有し、`0400`パーミッションを持っています。親ディレクトリには`0750`パーミッションがあります。空でない値を持つ変数のみがファイルに書き込まれます。
