---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バックアップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## Linuxパッケージインストールでの設定のバックアップと復元 {#backup-and-restore-configuration-on-a-linux-package-installation}

Linuxパッケージインストールのすべての設定は、`/etc/gitlab`に保存されます。[設定と証明書](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#data-not-included-in-a-backup)のコピーを安全な場所に、GitLabアプリケーションのバックアップとは別に保管することをお勧めします。これにより、暗号化されたアプリケーションデータが、復号化に必要なキーとともに、紛失、漏洩、または盗難される可能性が低くなります。

特に、`gitlab-secrets.json`ファイル（および場合によっては`gitlab.rb`ファイル）には、SQLデータベース内の機密情報を保護するためのデータベース暗号化キーが含まれています:

- [2要素認証](https://docs.gitlab.com/security/two_factor_authentication/)（2FA）ユーザーシークレット
- [セキュアファイル](https://docs.gitlab.com/ci/secure_files/)

これらのファイルを紛失すると、2FAを使用しているユーザーは[GitLabアカウント](https://docs.gitlab.com/user/profile/)にアクセスできなくなり、「セキュアな変数」はCI設定から失われます。

設定をバックアップするには、`sudo gitlab-ctl backup-etc`を実行します。これにより、`/etc/gitlab/config_backup/`にtarアーカイブが作成されます。ディレクトリとバックアップファイルは、rootのみが読み取り可能です。

{{< alert type="note" >}}

`sudo gitlab-ctl backup-etc --backup-path <DIRECTORY>`を実行すると、指定されたディレクトリにバックアップが配置されます。ディレクトリが存在しない場合は作成されます。絶対パスをお勧めします。

{{< /alert >}}

毎日のアプリケーションバックアップを作成するには、ユーザーrootのcronテーブルを編集します:

```shell
sudo crontab -e -u root
```

cronテーブルがエディタに表示されます。

`/etc/gitlab/`のコンテンツを含むtarファイルを作成するコマンドを入力します。たとえば、平日後の毎朝、火曜日（2日）から土曜日（6日）にバックアップを実行するようにスケジュールします:

```plaintext
15 04 * * 2-6  gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/
```

{{< alert type="note" >}}

`/secret/gitlab/backups/`が存在することを確認してください。

{{< /alert >}}

tarファイルを次のように展開できます。

```shell
# Rename the existing /etc/gitlab, if any
sudo mv /etc/gitlab /etc/gitlab.$(date +%s)
# Change the example timestamp below for your configuration backup
sudo tar -xf gitlab_config_1487687824_2017_02_21.tar -C /
```

設定のバックアップを復元した後、`sudo gitlab-ctl reconfigure`を実行することを忘れないでください。

{{< alert type="note" >}}

マシンのSSHホストキーは、`/etc/ssh/`の別の場所に保存されています。マシン全体を復元する必要がある場合は、中間者攻撃の警告を回避するために、[これらのキーをバックアップおよび復元する](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)ことも確認してください。

{{< /alert >}}

### 設定のバックアップのライフタイムを制限する（古いバックアップを削除する） {#limit-backup-lifetime-for-configuration-backups-prune-old-backups}

GitLabの設定バックアップは、[GitLabアプリケーションのバックアップに使用される](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#limit-backup-lifetime-for-local-files-prune-old-backups)同じ`backup_keep_time`設定を使用して削除できます

この設定を利用するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

`backup_keep_time`のデフォルトの設定は`0`で、すべてのGitLabの設定とアプリケーションのバックアップが保持されます。

`backup_keep_time`を設定すると、`sudo gitlab-ctl backup-etc --delete-old-backups`を実行して、現在の時間から`backup_keep_time`を差し引いた値よりも古いすべてのバックアップを削除できます。

既存のすべてのバックアップを保持する場合は、パラメータ`--no-delete-old-backups`を指定できます。

{{< alert type="warning" >}}

パラメータが指定されていない場合、デフォルトは`--delete-old-backups`で、`backup_keep_time`が0より大きい場合、現在の時間から`backup_keep_time`を差し引いた値よりも古いバックアップはすべて削除されます。

{{< /alert >}}

## アプリケーションバックアップの作成 {#creating-an-application-backup}

リポジトリとGitLabメタデータのバックアップを作成するには、[バックアップ作成ドキュメント](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)に従ってください。

バックアップの作成により、`/var/opt/gitlab/backups`にtarファイルが保存されます。

GitLabのバックアップを別のディレクトリに保存する場合は、次の設定を`/etc/gitlab/gitlab.rb`に追加し、`sudo gitlab-ctl
reconfigure`を実行します:

```ruby
gitlab_rails['backup_path'] = '/mnt/backups'
```

## Dockerコンテナ内のGitLabインスタンスのバックアップを作成する {#creating-backups-for-gitlab-instances-in-docker-containers}

{{< alert type="warning" >}}

パフォーマンス上の理由、またはPatroniクラスターで使用する場合、PgBouncerを使用するインストールでは、バックアップコマンドには[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

{{< /alert >}}

`docker exec -t <your container name>`をコマンドの先頭に追加すると、ホストでバックアップをスケジュールできます。

バックアップアプリケーション:

```shell
docker exec -t <your container name> gitlab-backup
```

バックアップ設定とシークレット:

```shell
docker exec -t <your container name> /bin/sh -c 'gitlab-ctl backup-etc && cd /etc/gitlab/config_backup && cp $(ls -t | head -n1) /secret/gitlab/backups/'
```

{{< alert type="note" >}}

これらのバックアップをコンテナの外部に保持するには、次のディレクトリにボリュームをマウントします:

{{< /alert >}}

1. `/secret/gitlab/backups`。
1. `/var/opt/gitlab`（バックアップを含む[すべてのアプリケーションデータ](https://docs.gitlab.com/install/docker/#set-up-the-volumes-location)）。
1. `/var/opt/gitlab/backups`（オプション）。`gitlab-backup`ツールは、[デフォルトで](#creating-an-application-backup)このディレクトリに書き込みます。このディレクトリが`/var/opt/gitlab`のネストされた内にある間、[Dockerはこれらのマウントをソート](https://github.com/moby/moby/pull/8055)し、それらを調和して動作させることができます。

   この設定により、たとえば、次のことが可能になります:

   - 通常のローカルストレージ上のアプリケーションデータ（2番目のマウント経由）。
   - ネットワークストレージ上のバックアップボリューム（3番目のマウント経由）。

## アプリケーションバックアップの復元 {#restoring-an-application-backup}

[復元ドキュメント](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/)を参照してください。

## パッケージ化されていないデータベースを使用したバックアップと復元 {#backup-and-restore-using-non-packaged-database}

パッケージ化されていないデータベースを使用している場合は、[パッケージ化されていないデータベースの使用に関するドキュメント](database.md#using-a-non-packaged-postgresql-database-management-server)を参照してください。

## リモート（クラウド）ストレージにバックアップをアップロードする {#upload-backups-to-remote-cloud-storage}

詳細については、[バックアップドキュメント](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage)を確認してください。

## バックアップディレクトリを手動で管理する {#manually-manage-backup-directory}

Linuxパッケージインストールでは、`gitlab_rails['backup_path']`で設定されたバックアップディレクトリが作成されます。このディレクトリは、GitLabを実行しているユーザーが所有しており、そのユーザーのみがアクセスできるように厳密なアクセス許可が設定されています。そのディレクトリにはバックアップアーカイブが保持され、機密情報が含まれます。一部の組織では、たとえばバックアップアーカイブをオフサイトに発送するために、アクセス許可が異なる必要があります。

バックアップディレクトリの管理を無効にするには、`/etc/gitlab/gitlab.rb`で次のように設定します:

```ruby
gitlab_rails['manage_backup_path'] = false
```

{{< alert type="warning" >}}

この設定オプションを設定する場合は、`gitlab_rails['backup_path']`で指定されたディレクトリを作成し、`user['username']`で指定されたユーザーが正しいアクセス権を持つことができるようにアクセス許可を設定する必要があります。そうしないと、GitLabがバックアップアーカイブを作成できなくなります。

{{< /alert >}}
