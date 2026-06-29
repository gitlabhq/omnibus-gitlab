---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 自己コンパイルインストールをLinuxパッケージインストールに変換する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

自己コンパイルのインストール方法を使用してGitLabをインストールした場合、インスタンスをLinuxパッケージインスタンスに変換できます。

自己コンパイルインストールを変換する際:

- GitLabのまったく同じバージョンに変換する必要があります。
- `gitlab.yml`、`puma.rb`、`smtp_settings.rb`などのファイル内の設定は失われるため、[`/etc/gitlab/gitlab.rb`で設定を構成](../settings/configuration.md)する必要があります。

> [!warning]
> 自己コンパイルされたインストールからのGitLabによる変換はテストされていません。

自己コンパイルインストールをLinuxパッケージインストールに変換するには:

1. 現在の自己コンパイルインストールからバックアップを作成します:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
   ```

1. [Linuxパッケージを使用してGitLabをインストール](https://about.gitlab.com/install/)します。
1. バックアップファイルを新しいサーバーの`/var/opt/gitlab/backups/`ディレクトリにコピーします。
1. 新しいインストールでバックアップを復元する（[詳細な手順](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)）:

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=<FILE_NAME>
   ```

   復元には、データベースとGitデータのサイズに応じて数分かかります。

1. Linuxパッケージインストールではすべての設定が`/etc/gitlab/gitlab.rb`に保存されるため、新しいインストールを再構成する必要があります。個別の設定は、`gitlab.yml`、`puma.rb`、`smtp_settings.rb`などの自己コンパイルされたインストールファイルから手動で移動する必要があります。利用可能なすべてのオプションについては、[`gitlab.rb`テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を参照してください。
1. 古い自己コンパイルインストールから新しいLinuxパッケージインストールにシークレットをコピーします:
   1. Rails関連のシークレットを復元する。`/home/git/gitlab/config/secrets.yml`（自己コンパイルされたインストール）から、`db_key_base`、`secret_key_base`、`otp_key_base`、`encrypted_settings_key_base`、`openid_connect_signing_key`、および`active_record_encryption`の値を、`/etc/gitlab/gitlab-secrets.json`（Linuxパッケージインストール）内の同等のものにコピーします。
   1. `/home/git/gitlab-shell/.gitlab_shell_secret`（自己コンパイルされたインストール）の内容を、`/etc/gitlab/gitlab-secrets.json`（Linuxパッケージインストール）内の`secret_token`にコピーします。次のようになります:

       ```json
       {
         "gitlab_workhorse": {
           "secret_token": "..."
         },
         "gitlab_shell": {
           "secret_token": "..."
         },
         "gitlab_rails": {
           "secret_key_base": "...",
           "db_key_base": "...",
           "otp_key_base": "...",
           "encrypted_settings_key_base": "...",
           "openid_connect_signing_key": "...",
           "active_record_encryption_primary_key": [ "..."],
           "active_record_encryption_deterministic_key": ["..."],
           "active_record_encryption_key_derivation_salt": "...",
         }
         ...
       }
       ```

1. 変更を適用するためにGitLabを再構成します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `/home/git/gitlab-shell/.gitlab_shell_secret`を移行した場合、[Gitalyを再起動](https://gitlab.com/gitlab-org/gitaly/-/issues/3837)する必要があります:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

## 外部PostgreSQLからバックアップを使用したLinuxパッケージインストールへの変換 {#convert-an-external-postgresql-to-a-linux-package-installation-by-using-a-backup}

[外部PostgreSQLインストール](https://docs.gitlab.com/administration/postgresql/external/)を、バックアップを使用してLinuxパッケージPostgreSQLインストールに変換できます。この操作を行う際には、同じGitLabバージョンを使用する必要があります。

外部PostgreSQLインストールをバックアップを使用してLinuxパッケージPostgreSQLインストールに変換するには:

1. [非Linuxパッケージインストールからバックアップを作成](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)
1. [Linuxパッケージインストールでバックアップを復元する](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)。
1. `check`タスクを実行します:

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. `No such file or directory @ realpath_rec - /home/git`と同様のエラーが表示された場合は、以下を実行します:

   ```shell
   find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
   ```

これは、`gitlab-shell`が`/home/git`にあることを前提としています。

## 外部PostgreSQLからインプレースでのLinuxパッケージインストールへの変換 {#convert-an-external-postgresql-to-a-linux-package-installation-in-place}

[外部PostgreSQLインストール](https://docs.gitlab.com/administration/postgresql/external/)を、インプレースでLinuxパッケージPostgreSQLインストールに変換できます。

これらの手順は以下を前提としています:

- UbuntuでPostgreSQLを使用しています。
- 現在のGitLabバージョンに一致するLinuxパッケージがあります。
- 自己コンパイルインストールのGitLabは、すべてのデフォルトのパスとユーザーを使用しています。
- Gitユーザーの既存のホームディレクトリ（`/home/git`）は`/var/opt/gitlab`に変更されます。

外部PostgreSQLインストールをインプレースでLinuxパッケージPostgreSQLインストールに変換するには:

1. GitLab、Redis、およびNGINXを停止して無効にします:

   ```shell
   # Ubuntu
   sudo service gitlab stop
   sudo update-rc.d gitlab disable

   sudo service nginx stop
   sudo update-rc.d nginx disable

   sudo service redis-server stop
   sudo update-rc.d redis-server disable
   ```

1. サーバーでGitLabを管理するために構成管理システムを使用している場合は、そこでGitLabとその関連サービスを無効にします。
1. 新しいセットアップ用に`gitlab.rb`ファイルを作成します:

   ```shell
   sudo mkdir /etc/gitlab
   sudo tee -a /etc/gitlab/gitlab.rb <<'EOF'
   # Use your own GitLab URL here
   external_url 'http://gitlab.example.com'

   # We assume your repositories are in /home/git/repositories (default for source installs) and that Gitaly
   # listens on a socket at /home/git/gitlab/tmp/sockets/private/gitaly.socket
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/home/git/repositories'
       }
     ]
   }
   gitlab_rails['repositories_storages'] = {
     default: {
       gitaly_address: '/home/git/gitlab/tmp/sockets/private/gitaly.socket'
     }
   }

   # Re-use the PostgreSQL that is already running on your system
   postgresql['enable'] = false
   # This db_host setting is for Debian PostgreSQL packages
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   gitlab_rails['db_port'] = 5432
   # We assume you called the GitLab DB user 'git'
   gitlab_rails['db_username'] = 'git'
   EOF
   ```

1. 次に、Linuxパッケージをインストールし、インストールを再構成します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl reconfigure`の実行によりGitユーザーのホームディレクトリが変更され、OpenSSHが`authorized_keys`ファイルを見つけられなくなったため、キーファイルを再構築します:

   ```shell
   sudo gitlab-rake gitlab:shell:setup
   ```

   これで、以前存在していたリポジトリとユーザーで、GitLabサーバーへのHTTPおよびSSHアクセスが可能になります。

1. GitLabウェブインターフェースにログインできる場合は、古いサービスがLinuxパッケージインストールに干渉しないように、サーバーを再起動します。
1. LDAPなどの特殊機能を使用している場合は、設定を`gitlab.rb`に記述する必要があります。詳細については、[設定ドキュメント](../settings/_index.md)を参照してください。
