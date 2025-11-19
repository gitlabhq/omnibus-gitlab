---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メンテナンスコマンド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下のコマンドは、インストール後に実行できます。

## サービスステータスの取得 {#get-service-status}

各GitLabコンポーネントの現在の状態とアップタイムを確認するには、`sudo gitlab-ctl status`を実行します。

出力は次のようになります:

```plaintext
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: puma: (pid 961) 7s; run: log: (pid 960) 7s
```

例として、上記の例の最初の行は次のように解釈できます:

- `Nginx`は、プロセス名です。
- `972`は、プロセス識別子です。
- NGINXは7秒間（`7s`）実行されています。
- `log`は、先行するプロセスにアタッチされた[svlogdロギングプロセス](https://manpages.ubuntu.com/manpages/lunar/en/man8/svlogd.8.html)を示します。
- `971`は、ロギングプロセスのプロセス識別子です。
- ロギングプロセスは7秒間（`7s`）実行されています。

## 設定の表示 {#show-configuration}

`sudo gitlab-ctl show-config`を実行して、`gitlab-ctl reconfigure`によって生成される設定を表示します。出力はJSON形式で、次のようになります:

```json
{
  "gitlab": {
    "gitlab_sshd": {

    },
    "gitlab_shell": {
      "secret_token": "<SECRET_TOKEN>",
      "auth_file": "/var/opt/gitlab/.ssh/authorized_keys"
    },
    "gitlab_rails": {
      "smtp_address": "smtp.example.com",
      "smtp_port": 587,
      "smtp_user_name": "user@example.com",
      "smtp_password": "<SMTP_PASSWORD>",
      "smtp_domain": "smtp.example.com",
      "smtp_authentication": "login",
      "monitoring_whitelist": [
        "127.0.0.0/8",
        "::1/128",
      ],
   ...
    }
  }
}
```

GitLabを再設定すると、`/var/opt/gitlab`ディレクトリにある自動生成されたYAML設定ファイルを参照して、適用された最新の設定を確認できます。上記の例では、`gitlab-rails`の設定を`/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`で確認できます。

## 末尾のプロセスログ {#tail-process-logs}

[Linuxパッケージ](../settings/logs.md)インストールに関するログを参照してください。

## 起動と停止 {#starting-and-stopping}

Linuxパッケージがインストールされ、設定されると、サーバーには、`/etc/inittab`または`/etc/init/gitlab-runsvdir.conf` Upstartリソースを介して起動時に開始されるrunitサービスディレクトリ（`runsvdir`）プロセスが実行されます。`runsvdir`プロセスを直接処理する必要はありません。`gitlab-ctl`フロントエンドを代わりに使用できます。

GitLabとそのすべてのコンポーネントを起動、停止、または再起動するには、次のコマンドを使用します。

```shell
# Start all GitLab components
sudo gitlab-ctl start

# Stop all GitLab components
sudo gitlab-ctl stop

# Restart all GitLab components
sudo gitlab-ctl restart

# Restart all GitLab components except given services ... (e.g. gitaly, redis)
sudo gitlab-ctl restart-except gitaly redis
```

シングルコアサーバーでは、PumaとSidekiqを再起動するのに最大1分かかる場合があることに注意してください。Pumaが再び起動するまで、GitLabインスタンスは502エラーを表示します。

個々のコンポーネントを起動、停止、または再起動することもできます。

```shell
sudo gitlab-ctl restart sidekiq
```

Pumaは、ほぼゼロダウンタイムの再読み込みをサポートしています。これらは次のようにトリガーできます:

```shell
sudo gitlab-ctl hup puma
```

`hup`コマンドが完了するまで待つ必要があります。これには時間がかかる場合があります。完了するまで、ノードをプールから外し、これが実行されるノード上のサービスを再起動しないでください。Pumaの再読み込みを使用して、Rubyランタイムを更新することもできません。

Pumaには、アプリケーションの動作を制御するための次のシグナルがあります:

| シグナル   | Puma                                                                |
| -------- | ------                                                              |
| `HUP`    | ログの再オープンを定義するか、プロセスを停止して再起動を強制します      |
| `INT`    | リクエスト処理を正常に停止します                                |
| `USR1`   | 設定を再読み込みせずに、段階的にワーカーを再起動し、ローリング再起動します |
| `USR2`   | ワーカーを再起動して、設定を再読み込みします                                   |
| `QUIT`   | メインプロセスを終了します                                               |

Pumaの場合、`gitlab-ctl hup puma`は、`SIGINT`および`SIGTERM`（プロセスが再起動しない場合）シグナルのシーケンスを送信します。Pumaは、`SIGINT`を受信するとすぐに、新しい接続の受け入れを停止します。実行中のすべてのリクエストを完了します。次に、`runit`はサービスを再起動します。

## Rakeタスクの実行 {#invoking-rake-tasks}

GitLab Rakeタスクを実行するには、`gitlab-rake`を使用します。例: 

```shell
sudo gitlab-rake gitlab:check
```

`git`ユーザーの場合は、`sudo`を省略します。

従来のGitLabインストールとは異なり、ユーザーまたは`RAILS_ENV`環境変数を変更する必要はありません。これは、`gitlab-rake`ラッパースクリプトによって処理されます。

## Railsコンソールセッションを開始する {#starting-a-rails-console-session}

詳細については、[Railsコンソール](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)を参照してください。

## PostgreSQLスーパーユーザー`psql`セッションの開始 {#starting-a-postgresql-superuser-psql-session}

にバンドルされているPostgreSQLサービスへのスーパーユーザーアクセスが必要な場合は、`gitlab-psql`コマンドを使用できます。これは、通常の`psql`コマンドと同じ引数を取ります。

```shell
# Superuser psql access to GitLab's database
sudo gitlab-psql -d gitlabhq_production
```

これは、`gitlab-ctl reconfigure`を少なくとも1回実行した後にのみ機能します。`gitlab-psql`コマンドは、リモートPostgreSQLサーバーへの接続、またはローカルの非LinuxパッケージのPostgreSQLサーバーへの接続には使用できません。

### GeoトラッキングデータベースでのPostgreSQLスーパーユーザー`psql`セッションの開始 {#starting-a-postgresql-superuser-psql-session-in-geo-tracking-database}

前のコマンドと同様に、にバンドルされているGeoトラッキングデータベース（`geo-postgresql`）へのスーパーユーザーアクセスが必要な場合は、`gitlab-geo-psql`を使用できます。これは、通常の`psql`コマンドと同じ引数を取ります。高可用性については、必要な引数の詳細について、[Checking Configuration（設定の確認）](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)を参照してください。

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

## コンテナレジストリのガベージコレクション {#container-registry-garbage-collection}

コンテナレジストリは、かなりの量のディスク容量を使用する可能性があります。未使用のレイヤーをクリアするために、レジストリには、[ガベージコレクションコマンド](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-garbage-collection)が含まれています。

## GitLabへのログインからユーザーを制限する {#restrict-users-from-logging-into-gitlab}

GitLabへのログインからユーザーを一時的に制限する必要がある場合は、`sudo gitlab-ctl deploy-page up`を使用できます。ユーザーがGitLab URLにアクセスすると、任意の`Deploy in progress`ページが表示されます。

ページを削除するには、`sudo gitlab-ctl deploy-page down`を実行するだけです。`sudo gitlab-ctl deploy-page status`を使用して、デプロイページのステータスを確認することもできます。

ちなみに、GitLabへのログインを制限し、プロジェクトへの変更を制限する場合は、[プロジェクトを読み取り専用に設定](https://docs.gitlab.com/administration/troubleshooting/gitlab_rails_cheat_sheet/#make-a-project-read-only-can-only-be-done-in-the-console)してから、`Deploy in progress`ページを起動できます。

## シークレットファイルのローテーション {#rotate-the-secrets-file}

セキュリティ上の目的で必要な場合は、`/etc/gitlab/gitlab-secrets.json`シークレットファイルをローテーションできます。このファイル内:

- `gitlab_rails`シークレットは、データベース暗号化キーが含まれているため、ローテーションしないでください。このシークレットをローテーションすると、[が失われた場合](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)と同じ動作になります。
- 他のすべてのシークレットをローテーションできます。

GitLab環境に複数のノードがある場合は、Railsノードの1つを選択して、初期手順を実行します。

シークレットをローテーションするには:

1. データベースの値が[復号化できることを確認する](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)で、表示された復号化エラーをメモするか、続行する前に解決します。

1. （推奨）`gitlab_rails`の現在のシークレットを抽出します。後で必要になるため、出力を保存します:

   ```shell
   sudo grep "secret_key_base\|db_key_base\|otp_key_base\|encrypted_settings_key_base\|openid_connect_signing_key\|active_record_encryption_primary_key\|active_record_encryption_deterministic_key\|active_record_encryption_key_derivation_salt" /etc/gitlab/gitlab-secrets.json
   ```

1. 現在のシークレットファイルを別の場所に移動します:

   ```shell
   sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
   ```

1. [GitLabを再設定します](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。次に、GitLabは新しいシークレット値で新しい`/etc/gitlab/gitlab-secrets.json`ファイルを生成します。

1. `gitlab_rails`の以前のシークレットを抽出した場合は、新しい`/etc/gitlab/gitlab-secrets.json`ファイルを編集し、`gitlab_rails`のキー/バリューペアを、以前に取得した以前のシークレット出力に置き換えます。

1. シークレットファイルに加えられた変更が適用されるように、再度[GitLabを再設定する](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。

1. すべてのサービスが新しいシークレットを使用していることを確認するために、[GitLabを再起動](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)します。

1. GitLab環境に複数のノードがある場合は、他のすべてのノードにシークレットをコピーする必要があります:

   1. 他のすべてのノードで、現在のシークレットファイルを別の場所に移動します:

      ```shell
      sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
      ```

   1. Railsノードから他のすべてのGitLabノードに新しい`/etc/gitlab/gitlab-secrets.json`ファイルをコピーします。

   1. 他のすべてのノードで、各ノードで[GitLabを再設定します](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。

   1. 他のすべてのノードで、各ノードで[GitLabを再起動](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)して、すべてのサービスが新しいシークレットを使用していることを確認します。

   1. すべてのノードで、シークレットが一致することを確認するために、`/etc/gitlab/gitlab-secrets.json`ファイルでチェックサムの一致を実行します:

      ```shell
      sudo md5sum /etc/gitlab/gitlab-secrets.json
      ```

1. [データベースの値が復号化できることを確認する](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)。出力は、以前の実行と一致する必要があります。

1. GitLabが期待どおりに動作していることを確認します。問題がなければ、古いシークレットを安全に削除できます。

## 非推奨 {#deprecations}

将来のGitLabバージョンで削除されるフラグのOmnibus設定を確認するには、`sudo gitlab-ctl check-config`を実行します。

このコマンドは、次の引数をサポートしています:

- `--version <Version>`: 設定をチェックする対象のターゲットGitLabバージョン。
- `--no-fail`: 非推奨/削除が見つかった場合でも、失敗コードで終了しないようにします。

GitLabをアップグレードすると、この設定チェックが自動的に実行されます。アップグレード中にこのチェックをスキップする場合は、`/etc/gitlab/skip-fail-config-check`にファイルを作成します。
