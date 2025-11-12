---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セルフコンパイルインストールをLinuxパッケージに変換する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

セルフコンパイルインストール方式でGitLabをインストールした場合、インスタンスをLinuxパッケージのインスタンスに変換できます。

セルフコンパイルインストールを変換する場合:

- GitLabのまったく同じバージョンに変換する必要があります。
- [`/etc/gitlab/gitlab.rb`で設定を構成する](../settings/configuration.md)必要があります。これは、`gitlab.yml`、`puma.rb`、`smtp_settings.rb`などのファイルの設定が失われるためです。

{{< alert type="warning" >}}

セルフコンパイルインストールからの変換は、GitLabではテストされていません。

{{< /alert >}}

セルフコンパイルインストールをLinuxパッケージに変換するには:

1. 現在のセルフコンパイルインストールからバックアップを作成します:

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

1. すべての設定がLinuxパッケージの`/etc/gitlab/gitlab.rb`に保存されているため、新しいインストールを再構成する必要があります。個々の設定は、`gitlab.yml`、`puma.rb`、`smtp_settings.rb`などのセルフコンパイルインストールファイルから手動で移行する必要があります。使用可能なすべてのオプションについては、[`gitlab.rb`テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)を参照してください。
1. 古いセルフコンパイルインストールから新しいLinuxパッケージにシークレットをコピーします:
   1. Railsに関連するシークレットを復元します。`db_key_base`、`secret_key_base`、`otp_key_base`、`encrypted_settings_key_base`、`openid_connect_signing_key`、および`active_record_encryption`の値を、`/home/git/gitlab/config/secrets.yml`（セルフコンパイルインストール）から`/etc/gitlab/gitlab-secrets.json`（Linuxパッケージ）の同等のキーにコピーします。
   1. `/home/git/gitlab-shell/.gitlab_shell_secret`（セルフコンパイルインストール）の内容を`secret_token`の`/etc/gitlab/gitlab-secrets.json`（Linuxパッケージ）にコピーします。次のような内容になります:

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

1. 変更を反映させるには、GitLabを再構成してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `/home/git/gitlab-shell/.gitlab_shell_secret`を移行した場合は、[Gitalyを再起動](https://gitlab.com/gitlab-org/gitaly/-/issues/3837)する必要があります:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

## 外部PostgreSQLインストールをバックアップを使用してLinuxパッケージに変換します {#convert-an-external-postgresql-to-a-linux-package-installation-by-using-a-backup}

[外部PostgreSQLインストール](https://docs.gitlab.com/administration/postgresql/external/)をバックアップを使用してLinuxパッケージのPostgreSQLインストールに変換できます。これを行う場合は、同じGitLabのバージョンを使用する必要があります。

外部PostgreSQLインストールをバックアップを使用してLinuxパッケージのPostgreSQLインストールに変換するには:

1. [非Linuxパッケージインストールからバックアップを作成](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)
1. [Linuxパッケージインストールでバックアップを復元する](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)。
1. `check`タスクを実行します:

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. `No such file or directory @ realpath_rec - /home/git`のようなエラーが表示された場合は、次を実行します:

   ```shell
   find . -lname /home/git/gitlab-shell/hooks -exec sh -c 'ln -snf /opt/gitlab/embedded/service/gitlab-shell/hooks $0' {} \;
   ```

これは、`gitlab-shell`が`/home/git`にあることを前提としています。

## 外部PostgreSQLインストールをインプレースでLinuxパッケージに変換します {#convert-an-external-postgresql-to-a-linux-package-installation-in-place}

[外部PostgreSQLインストール](https://docs.gitlab.com/administration/postgresql/external/)をインプレースでLinuxパッケージのPostgreSQLインストールに変換できます。

これらの手順は、以下を前提としています:

- UbuntuでPostgreSQLを使用している。
- 現在のGitLabのバージョンに一致するLinuxパッケージがある。
- GitLabのセルフコンパイルインストールは、すべてのデフォルトのパスとユーザーを使用します。
- Gitユーザーの既存のホームディレクトリ（`/home/git`）が`/var/opt/gitlab`に変更されます。

外部PostgreSQLインストールをインプレースでLinuxパッケージのPostgreSQLインストールに変換するには:

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

1. 構成管理システムを使用してサーバー上のGitLabを管理している場合は、GitLabとその関連サービスをそこで無効にします。
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

1. ここで、Linuxパッケージをインストールし、インストールを再構成します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl reconfigure`の実行によりGitユーザーのホームディレクトリが変更され、OpenSSHが`authorized_keys`ファイルを検出できなくなったため、キーファイルを再構築します:

   ```shell
   sudo gitlab-rake gitlab:shell:setup
   ```

   これで、以前と同じリポジトリとユーザーを使用して、GitLabサーバーへのHTTPおよびSSHアクセスが可能になります。

1. GitLabWebインターフェースにログインできる場合は、サーバーを再起動して、古いサービスがLinuxパッケージのインストールを妨げないようにしてください。
1. LDAPなどの特別な機能を使用している場合は、`gitlab.rb`に設定を入力する必要があります。詳細については、[設定に関するドキュメント](../settings/_index.md)を参照してください。
