---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: メンテナンスコマンド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インストール後に以下のコマンドを実行できます。

## サービスステータスの取得 {#get-service-status}

`sudo gitlab-ctl status`を実行して、各GitLabコンポーネントの現在の状態とアップタイムを確認します。

出力は次のようになります:

```plaintext
run: nginx: (pid 972) 7s; run: log: (pid 971) 7s
run: postgresql: (pid 962) 7s; run: log: (pid 959) 7s
run: redis: (pid 964) 7s; run: log: (pid 963) 7s
run: sidekiq: (pid 967) 7s; run: log: (pid 966) 7s
run: puma: (pid 961) 7s; run: log: (pid 960) 7s
```

例として、前の例の最初の行は次のように解釈できます:

- `Nginx`はプロセス名です。
- `972`はプロセスの識別子です。
- NGINXは7秒間実行されています (`7s`)。
- `log`は、先行プロセスにアタッチされている[svlogd logging process](https://manpages.ubuntu.com/manpages/noble/man8/svlogd.8.html)を示します。
- `971`はロギングプロセスの識別子です。
- ロギングプロセスは7秒間実行されています (`7s`)。

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

GitLabが再設定された後、`/var/opt/gitlab`ディレクトリの下にある自動生成されたYAML設定ファイルを参照して、適用された最新の設定を確認できます。上記の例では、`/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`の下の`gitlab-rails`の設定を確認できます。

## プロセスログの末尾表示 {#tail-process-logs}

[Linuxパッケージインストールに関するログ](../settings/logs.md)を参照してください。

## 開始と停止 {#starting-and-stopping}

Linuxパッケージがインストールおよび設定されると、サーバーには`/etc/inittab`または`/etc/init/gitlab-runsvdir.conf` Upstartリソースを介して起動時に開始されるrunitサービスディレクトリ (`runsvdir`) プロセスが実行されます。`runsvdir`プロセスを直接処理する必要はありません。代わりに`gitlab-ctl`フロントエンドを使用できます。

以下のコマンドで、GitLabとそのすべてのコンポーネントを開始、停止、または再起動できます。

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

シングルコアサーバーでは、PumaとSidekiqの再起動に最大1分かかる場合があります。Pumaが再び稼働するまで、GitLabインスタンスは502エラーを発生します。

個々のコンポーネントを開始、停止、または再起動することも可能です。

```shell
sudo gitlab-ctl restart sidekiq
```

Pumaはほぼゼロダウンタイムのリロードをサポートしています。これらは次のようにトリガーできます:

```shell
sudo gitlab-ctl hup puma
```

`hup`コマンドが完了するまで待つ必要があります。これには時間がかかる場合があります。プールからノードを外し、これが完了するまで、これが実行されるノード上のサービスを再起動しないでください。また、Pumaのリロードを使用してRubyランタイムを更新することはできません。

Pumaはアプリケーションの動作を制御するために以下のシグナルを持っています:

| シグナル   | Puma                                                                |
| -------- | ------                                                              |
| `HUP`    | 定義されたログファイルを再度開くか、強制再起動のためにプロセスを停止します。      |
| `INT`    | リクエスト処理を正常に停止します。                                |
| `USR1`   | ワーカーを段階的に再起動し、設定のリロードなしでローリング再起動を行います。 |
| `USR2`   | ワーカーを再起動し、設定をリロードします。                                   |
| `QUIT`   | メインプロセスを終了します。                                               |

Pumaの場合、`gitlab-ctl hup puma`は`SIGINT`と`SIGTERM` (プロセスが再起動しない場合) のシグナルシーケンスを送信します。`SIGINT`を受信するとすぐに、Pumaは新しい接続の受け入れを停止します。すべての実行中のリクエストを完了します。その後、`runit`がサービスを再起動します。

## Rakeタスクの実行 {#invoking-rake-tasks}

GitLab Rakeタスクを実行するには、`gitlab-rake`を使用します。例: 

```shell
sudo gitlab-rake gitlab:check
```

`git`ユーザーの場合は、`sudo`を省略してください。

従来のGitLabインストールとは異なり、ユーザーや`RAILS_ENV`環境変数を変更する必要はありません。`gitlab-rake`ラッパースクリプトがこれを処理します。

## Railsコンソールセッションを開始する {#starting-a-rails-console-session}

詳細については、[Railsコンソール](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)を参照してください。

## PostgreSQLスーパーユーザー`psql`セッションの開始 {#starting-a-postgresql-superuser-psql-session}

バンドルされたPostgreSQLサービスへのスーパーユーザーアクセスが必要な場合は、`gitlab-psql`コマンドを使用できます。通常の`psql`コマンドと同じ引数を受け取ります。

```shell
# Superuser psql access to GitLab's database
sudo gitlab-psql -d gitlabhq_production
```

これは、`gitlab-ctl reconfigure`を少なくとも1回実行した後にのみ機能します。`gitlab-psql`コマンドは、リモートPostgreSQLサーバーへの接続、またはローカルの非LinuxパッケージPostgreSQLサーバーへの接続には使用できません。

### GeoトラッキングデータベースでのPostgreSQLスーパーユーザー`psql`セッションの開始 {#starting-a-postgresql-superuser-psql-session-in-geo-tracking-database}

前のコマンドと同様に、バンドルされたGeoトラッキングデータベース (`geo-postgresql`) へのスーパーユーザーアクセスが必要な場合は、`gitlab-geo-psql`を使用できます。通常の`psql`コマンドと同じ引数を受け取ります。HAについては、[設定の確認](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)で必要な引数の詳細を参照してください。

```shell
# Superuser psql access to GitLab's Geo tracking database
sudo gitlab-geo-psql -d gitlabhq_geo_production
```

## コンテナレジストリのガベージコレクション {#container-registry-garbage-collection}

コンテナレジストリはかなりのディスク容量を使用する可能性があります。未使用のレイヤーをクリアするために、レジストリには[ガベージコレクションコマンド](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-garbage-collection)が含まれています。

## GitLabへのユーザーログインを制限する {#restrict-users-from-logging-into-gitlab}

GitLabへのユーザーログインを一時的に制限する必要がある場合は、`sudo gitlab-ctl deploy-page up`を使用できます。ユーザーがGitLab URLにアクセスすると、任意の`Deploy in progress`ページが表示されます。

ページを削除するには、`sudo gitlab-ctl deploy-page down`を実行するだけです。また、`sudo gitlab-ctl deploy-page status`を使用してデプロイページのステータスを確認することもできます。

補足として、GitLabへのログインを制限し、プロジェクトへの変更を制限したい場合は、[プロジェクトを読み取り専用に設定](https://docs.gitlab.com/administration/read_only_gitlab/#make-the-repositories-read-only)し、その後に`Deploy in progress`ページを公開できます。

## シークレットファイルのローテーション {#rotate-the-secrets-file}

セキュリティ上の理由で必要な場合は、`/etc/gitlab/gitlab-secrets.json`シークレットファイルをローテーションできます。このファイルでは:

- `gitlab_rails`シークレットはデータベース暗号化キーを含むため、ローテーションしないでください。このシークレットがローテーションされた場合、[シークレットファイルが失われたとき](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)と同じ動作になります。
- その他のすべてのシークレットをローテーションできます。

GitLab環境に複数のノードがある場合は、初期手順を実行するRailsノードの1つを選択してください。

シークレットをローテーションするには:

1. [データベース値が復号化できることを確認](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)し、表示された復号化エラーをメモするか、続行する前にそれらを解決してください。

1. 推奨。`gitlab_rails`の現在のシークレットを抽出します。後で必要になるため、出力を保存してください:

   ```shell
   sudo grep "secret_key_base\|db_key_base\|otp_key_base\|encrypted_settings_key_base\|openid_connect_signing_key\|active_record_encryption_primary_key\|active_record_encryption_deterministic_key\|active_record_encryption_key_derivation_salt" /etc/gitlab/gitlab-secrets.json
   ```

1. 現在のシークレットファイルを別の場所に移動します:

   ```shell
   sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
   ```

1. [GitLabを再設定します](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。GitLabは、新しいシークレット値を持つ新しい`/etc/gitlab/gitlab-secrets.json`ファイルを生成します。

1. `gitlab_rails`の以前のシークレットを抽出した場合は、新しい`/etc/gitlab/gitlab-secrets.json`ファイルを編集し、`gitlab_rails`の下のキー/バリューペアを、以前に取得したシークレット出力に置き換えます。

1. [GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、シークレットファイルに加えられた変更を適用します。

1. [GitLabを再起動](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)して、すべてのサービスが新しいシークレットを使用していることを確認します。

1. GitLab環境に複数のノードがある場合は、シークレットを他のすべてのノードにコピーする必要があります:

   1. 他のすべてのノードで、現在のシークレットファイルを別の場所に移動します:

      ```shell
      sudo mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
      ```

   1. 新しい`/etc/gitlab/gitlab-secrets.json`ファイルをRailsノードから他のすべてのGitLabノードにコピーします。

   1. 他のすべてのノードで、各ノードで[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。

   1. 他のすべてのノードで、各ノードで[GitLabを再起動](https://docs.gitlab.com/administration/restart_gitlab/#restart-a-linux-package-installation)して、すべてのサービスが新しいシークレットを使用していることを確認します。

   1. すべてのノードで、`/etc/gitlab/gitlab-secrets.json`ファイルに対してチェックサム照合を実行し、シークレットが一致することを確認します:

      ```shell
      sudo md5sum /etc/gitlab/gitlab-secrets.json
      ```

1. [データベース値が復号化できることを確認](https://docs.gitlab.com/administration/raketasks/check/#verify-database-values-can-be-decrypted-using-the-current-secrets)します。出力は以前の実行と一致するはずです。
1. GitLabが期待どおりに動作していることを確認します。そうであれば、古いシークレットを削除しても安全です。

## `gitlab-ctl`のbash補完を有効にする {#enable-bash-completion-for-gitlab-ctl}

Linuxパッケージには、`gitlab-ctl`コマンド用のbash補完スクリプトが含まれています。これを有効にするには、Shell設定ファイルで補完スクリプトをソースします。

補完スクリプトは`/opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion`にあります。

bash補完を有効にするには:

1. 以下の行をShell設定ファイル (`.bashrc`、`.bash_profile`、または同等のもの) に追加します:

   ```shell
   source /opt/gitlab/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion
   ```

1. Shell設定をリロードします:

   ```shell
   source ~/.bashrc
   ```

有効にした後、`gitlab-ctl`コマンドでタブ補完を使用できます:

```shell
gitlab-ctl <TAB>
```

補完スクリプトには、`bash-completion`パッケージがシステムにインストールされている必要があります。インストールされていない場合は、システムのパッケージマネージャーを使用してインストールできます:

- Debian/Ubuntu: `sudo apt-get install bash-completion`
- RHEL/CentOS: `sudo yum install bash-completion`

## 非推奨 {#deprecations}

`sudo gitlab-ctl check-config`を実行して、将来のGitLabバージョンで削除されるフラグがないかOmnibus設定を確認します。

このコマンドは以下の引数をサポートしています:

- `--version <Version>`: 設定を確認したいターゲットGitLabバージョン。
- `--no-fail`: 非推奨事項/削除事項が見つかった場合でも、失敗codeで終了しないようにします。

GitLabをアップグレードすると、この設定チェックは自動的に実行されます。アップグレード中にこのチェックをスキップしたい場合は、`/etc/gitlab/skip-fail-config-check`にファイルを作成します。
