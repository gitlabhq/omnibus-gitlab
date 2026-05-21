---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: データベース設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabがサポートするデータベース管理システムは、PostgreSQLのみです。

したがって、Linuxパッケージインストールで使用するデータベースサーバーには、次の2つのオプションがあります:

- Linuxパッケージに同梱されているパッケージ版PostgreSQLサーバー（設定不要、推奨）。
- [外部PostgreSQLサーバー](#using-a-non-packaged-postgresql-database-management-server)。

## Linuxパッケージに同梱されているPostgreSQLデータベースサービスを使用する {#using-the-postgresql-database-service-shipped-with-the-linux-package}

### 再設定とPostgreSQLの再起動 {#reconfigure-and-postgresql-restarts}

Linuxパッケージインストールでは通常、`gitlab.rb`ファイルでそのサービスの設定が変更されている場合、再設定の実行時にそのサービスを再起動します。PostgreSQLには、一部の設定はリロード（HUP）で反映される一方で、それ以外の設定はPostgreSQLの再起動が必要になるという特性があります。また、管理者はPostgreSQLの再起動のタイミングを厳密に制御したいことが多いため、Linuxパッケージインストールでは、再設定時にPostgreSQLを再起動ではなくリロードするよう設定されています。そのため、再起動が必要なPostgreSQLの設定を変更した場合は、再設定後にPostgreSQLを手動で再起動する必要があります。

[GitLab設定テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)では、PostgreSQLの設定ごとに、再起動が必要なものとリロードのみで反映されるものが区別されています。また、個別の設定については、データベースにクエリを実行することで、再起動が必要かどうかを確認できます。`sudo gitlab-psql`でデータベースコンソールを起動し、次のクエリの`<setting name>`を変更対象の設定名に置き換えて実行します:

```sql
SELECT name,setting FROM pg_settings WHERE context = 'postmaster' AND name = '<setting name>';
```

設定の変更に再起動が必要な場合、このクエリは、実行中のPostgreSQLデータベースインスタンスにおける設定名と、その設定の現在の値を返します。

#### PostgreSQLのバージョン変更時の自動再起動 {#automatic-restart-when-the-postgresql-version-changes}

デフォルトでは、Linuxパッケージインストールは、[アップストリームドキュメント](https://www.postgresql.org/docs/17/upgrading.html)で推奨されているように、基盤となるバージョンが変更されると、PostgreSQLを自動的に再起動します。この動作は、`postgresql`および`geo-postgresql`で利用可能な`auto_restart_on_version_change`設定を使用して制御できます。

PostgreSQLのバージョン変更時に自動再起動を無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   # For PostgreSQL/Patroni
   postgresql['auto_restart_on_version_change'] = false

   # For Geo PostgreSQL
   geo_postgresql['auto_restart_on_version_change'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 基盤となるバージョンが変更されたときにPostgreSQLを再起動することを強くお勧めします。これにより、[必要なライブラリの読み込みに関するエラー](#could-not-load-library-plpgsqlso)のようなエラーを回避できます。

### SSLを設定する {#configuring-ssl}

Linuxパッケージインストールは、PostgreSQLサーバーでSSLを自動的に有効にしますが、デフォルトでは暗号化された接続と暗号化されていない接続の両方を受け入れます。SSLを強制するには、`pg_hba.conf`で`hostssl`設定を使用する必要があります。詳細については、[`pg_hba.conf`ドキュメント](https://www.postgresql.org/docs/17/auth-pg-hba-conf.html)を参照してください。

SSLを利用するには、次のファイルが必要です:

- データベースの公開SSL証明書（`server.crt`）。
- 上記のSSL証明書に対応する秘密キー（`server.key`）。
- サーバーの証明書を検証するルート証明書バンドル（`root.crt`）。デフォルトでは、Linuxパッケージインストールは、`/opt/gitlab/embedded/ssl/certs/cacert.pem`に埋め込まれた証明書バンドルを使用します。これは、自己署名証明書には必要ありません。

利用に備えて、10年有効な自己署名証明書と秘密キーがLinuxパッケージインストールによって生成されます。CA署名証明書を使用したい場合、またはこれを独自の自己署名証明書に置き換えたい場合は、次の手順に従ってください。

これらのファイルの場所は設定で変更できますが、秘密キーは`gitlab-psql`ユーザーが読み取れる必要があります。Linuxパッケージインストールはファイル権限を管理しますが、パスをカスタマイズした場合は、`gitlab-psql`がファイルが配置されているディレクトリにアクセスできることを確認する必要があります。

詳細については、[PostgreSQLドキュメント](https://www.postgresql.org/docs/17/ssl-tcp.html)を参照してください。

`server.crt`と`server.key`は、GitLabへのアクセスに使用されるデフォルトのSSL証明書とは異なる場合があることに注意してください。たとえば、データベースの外部ホスト名が`database.example.com`で、GitLabの外部ホスト名が`gitlab.example.com`であるとします。この場合は、`*.example.com`のワイルドカード証明書、または2枚の別々のSSL証明書が必要になります。

`ssl_cert_file`、`ssl_key_file`、`ssl_ca_file`ファイルは、証明書、キー、バンドルをファイルシステム上のどこから読み込むかをPostgreSQLに指示します。これらの変更は`postgresql.conf`に適用されます。ディレクティブ`internal_certificate`と`internal_key`は、これらのファイルの内容を入力するために使用されます。内容は、次の例に示すように、直接追加することもファイルから読み込むこともできます。

これらのファイルを用意したら、SSLを有効にします:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   postgresql['ssl_cert_file'] = '/custom/path/to/server.crt'
   postgresql['ssl_key_file'] = '/custom/path/to/server.key'
   postgresql['ssl_ca_file'] = '/custom/path/to/bundle.pem'
   postgresql['internal_certificate'] = File.read('/custom/path/to/server.crt')
   postgresql['internal_key'] = File.read('/custom/path/to/server.key')
   ```

   相対パスは、PostgreSQLのデータディレクトリ（デフォルトでは`/var/opt/gitlab/postgresql/data`）を基準として解決されます。

1. 設定の変更を適用するため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. 変更を反映するため、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQLの起動に失敗した場合は、ログ（例: `/var/log/gitlab/postgresql/current`）で詳細を確認してください。

#### SSLを要求する {#require-ssl}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. 設定の変更を適用するため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。

#### SSLを無効化する {#disabling-ssl}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   postgresql['ssl'] = 'off'
   ```

1. 設定の変更を適用するため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. 変更を反映するため、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQLの起動に失敗した場合は、ログ（例: `/var/log/gitlab/postgresql/current`）で詳細を確認してください。

#### SSLが使用されていることを検証する {#verifying-that-ssl-is-being-used}

クライアントがSSLを使用しているかどうかを判断するには、次を実行します:

```shell
sudo gitlab-rails dbconsole --database main
```

起動時に、次のようなバナーが表示されます:

```plaintext
psql (13.14)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: on)
Type "help" for help.
```

クライアントがSSLを使用しているかどうかを判断するには、次のSQLクエリを発行します:

```sql
SELECT * FROM pg_stat_ssl;
```

例: 

```plaintext
gitlabhq_production=> select * from pg_stat_ssl;
 pid  | ssl | version |         cipher         | bits | compression |  clientdn
------+-----+---------+------------------------+------+-------------+------------
  384 | f   |         |                        |      |             |
  386 | f   |         |                        |      |             |
  998 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  933 | f   |         |                        |      |             |
 1003 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1016 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1022 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1211 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1214 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1213 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1215 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
 1252 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           |
 1280 | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 |  256 | f           | /CN=gitlab
  382 | f   |         |                        |      |             |
  381 | f   |         |                        |      |             |
  383 | f   |         |                        |      |             |
(16 rows)
```

1. `ssl`列に`t`が表示されている行はSSLが有効です。
1. `clientdn`に値が表示されている行は`cert`認証方法を使用しています。

#### SSLクライアント認証を設定する {#configure-ssl-client-authentication}

クライアントSSL証明書を使って、データベースサーバーに対するクライアント認証を行うことができます。証明書の作成は、`omnibus-gitlab`の機能には含まれません。ただし、既存のSSL証明書管理ソリューションをお持ちの場合は、それを使用できます。

##### データベースサーバーを設定する {#configure-the-database-server}

1. サーバーの証明書とキーを作成します。このとき、証明書の共通名はサーバーのDNS名と一致している必要があります
1. サーバー証明書、キー、CAファイルをPostgreSQLサーバーにコピーし、権限が正しいことを確認します
   1. 証明書はデータベースユーザー（デフォルト: `gitlab-psql`）が所有する必要があります
   1. キーファイルはデータベースユーザーが所有する必要があり、権限は`0400`に設定します
   1. CAファイルはデータベースユーザーが所有する必要があり、権限は`0400`に設定します

   > [!note]
   > これらのファイルには、ファイル名`server.crt`または`server.key`を使用しないでください。これらのファイル名は、`omnibus-gitlab`の内部使用のために予約されています。

1. `gitlab.rb`に次の設定があることを確認します:

   ```ruby
   postgresql['ssl_cert_file'] = 'PATH_TO_CERTIFICATE'
   postgresql['ssl_key_file'] = 'PATH_TO_KEY_FILE'
   postgresql['ssl_ca_file'] = 'PATH_TO_CA_FILE'
   postgresql['listen_address'] = 'IP_ADDRESS'
   postgresql['cert_auth_addresses'] = {
     'IP_ADDRESS' => {
       'database' => 'gitlabhq_production',
       'user' => 'gitlab'
     }
   }
   ```

   `listen_address`は、クライアントがデータベースへの接続に使用するサーバーのIPアドレスとして設定します。`cert_auth_addresses`に、データベースへの接続を許可するIPアドレスと、それに対応するデータベースおよびユーザーが含まれていることを確認します。`cert_auth_addresses`のキーを指定する際にはCIDR表記を使用して、IPアドレス範囲を組み込むことができます。

1. 新しい設定を反映するには、`gitlab-ctl reconfigure`を実行し、続いて`gitlab-ctl restart postgresql`を実行します。

#### Railsクライアントを設定する {#configure-the-rails-client}

Railsクライアントがサーバーに接続するには、`commonName`が`gitlab`に設定された証明書とキーが必要です。さらに、データベースサーバー側で`ssl_ca_file`に指定されたCAファイルで信頼されている認証局によって署名されている必要があります。

1. `gitlab.rb`を設定します

   ```ruby
   gitlab_rails['db_host'] = 'IP_ADDRESS_OR_HOSTNAME_OF_DATABASE_SERVER'
   gitlab_rails['db_sslcert'] = 'PATH_TO_CERTIFICATE_FILE'
   gitlab_rails['db_sslkey'] = 'PATH_TO_KEY_FILE'
   gitlab_rails['db_rootcert'] = 'PATH_TO_CA_FILE'
   ```

1. Railsクライアントが新しい設定を使用できるようにするには、`gitlab-ctl reconfigure`を実行します
1. [SSLが使用されていることを検証する](#verifying-that-ssl-is-being-used)の手順に従って、認証が機能していることを確認します。

### TCP/IPでリッスンするようにパッケージ版PostgreSQLサーバーを設定する {#configure-packaged-postgresql-server-to-listen-on-tcpip}

パッケージ版PostgreSQLサーバーは、TCP/IP接続をリッスンするように設定できます。ただし、重要でない一部のスクリプトはUNIXソケットを想定しており、誤動作する可能性があります。

データベースサービスでTCP/IPを使用するように設定するには、`gitlab.rb`の`postgresql`セクションと`gitlab_rails`セクションの両方に変更を加えます。

#### PostgreSQLブロックを設定する {#configure-postgresql-block}

`postgresql`ブロックでは、次の設定が影響を受けます:

- `listen_address`: PostgreSQLがリッスンするアドレスを制御します。
- `port`: PostgreSQLがリッスンするポートを制御します。デフォルトは`5432`です。
- `md5_auth_cidr_addresses`: パスワードで認証した後、サーバーへの接続が許可されるCIDRアドレスブロックのリスト。
- `trust_auth_cidr_addresses`: いかなる種類の認証も行わずに、サーバーへの接続が許可されるCIDRアドレスブロックのリスト。この設定は、GitLab RailsやSidekiqなど、接続を必要とするノードからの接続のみを許可する目的で設定する必要があります。これには、同じノードにデプロイされた場合のローカル接続や、Postgres Exporter（`127.0.0.1/32`）などのコンポーネントからのローカル接続が含まれます。
- `sql_user`: MD5認証で想定されるユーザー名を制御します。デフォルトは`gitlab`で、必須の設定ではありません。
- `sql_user_password`: PostgreSQLがMD5認証で受け入れるパスワードを設定します。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432
   postgresql['md5_auth_cidr_addresses'] = %w()
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/24)
   postgresql['sql_user'] = "gitlab"

   ##! SQL_USER_PASSWORD_HASH can be generated using the command `gitlab-ctl pg-password-md5 'gitlab'`,
   ##! where 'gitlab' (single-quoted to avoid shell interpolation) is the name of the SQL user that connects to GitLab.
   ##! You will be prompted for a password which other clients will use to authenticate with database, such as `securesqlpassword` in the below section.
   postgresql['sql_user_password'] = "SQL_USER_PASSWORD_HASH"

   # force ssl on all connections defined in trust_auth_cidr_addresses and md5_auth_cidr_addresses
   postgresql['hostssl'] = true
   ```

1. GitLabを再設定し、PostrgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

ネットワーク経由で接続するクライアントまたはGitLabサービスは、PostgreSQLサーバーへの接続時に、ユーザー名には`sql_user`の値、パスワードには設定で指定した値を提供する必要があります。また、これらのクライアントやサービスは、`md5_auth_cidr_addresses`に指定したネットワークブロックに含まれている必要があります

#### GitLab Railsブロックを設定する {#configure-gitlab-rails-block}

ネットワーク経由でPostgreSQLデータベースに接続するように`gitlab-rails`アプリケーションを設定するには、以下を設定する必要があります:

- `db_host`: データベースサーバーのIPアドレスを設定します。これがPostgreSQLサービスと同じインスタンス上にある場合は、`127.0.0.1`にすることができ、パスワード認証は必要ありません。
- `db_port`: 接続先PostgreSQLサーバーのポートを設定します。`db_host`を設定する場合は、このポートも必ず設定してください。
- `db_username`: PostgreSQLへの接続に使用するユーザー名を設定します。デフォルトは`gitlab`です。
- `db_password`: TCP/IP経由でPostgreSQLに接続し、かつ上記設定の`postgresql['md5_auth_cidr_addresses']`ブロックに含まれるインスタンスから接続する場合は必須です。一方、`127.0.0.1`に接続し、かつ`postgresql['trust_auth_cidr_addresses']`にそれを含めるように設定している場合には、指定は不要です。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "securesqlpassword"
   ```

1. GitLabを再設定し、PostrgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

#### サービスを適用して再起動する {#apply-and-restart-services}

前述の変更を加えた後、管理者は`gitlab-ctl reconfigure`を実行する必要があります。サービスがTCPでリッスンしていないなどの問題が発生した場合は、`gitlab-ctl restart postgresql`を使用してサービスを直接再起動してみてください。

Linuxパッケージに含まれる一部のスクリプト（`gitlab-psql`など）は、PostgreSQLへの接続がUNIXソケット経由で処理されることを想定しているため、正しく機能しない場合があります。UNIXソケットを無効にせずにTCP/IPを有効にすることができます。

他のクライアントからのアクセスをテストするには、次を実行します:

```shell
sudo gitlab-rails dbconsole --database main
```

### PostgreSQL WAL（Write Ahead Log）アーカイブを有効にする {#enabling-postgresql-wal-write-ahead-log-archiving}

デフォルトでは、パッケージ版PostgreSQLのWALアーカイブは有効になっていません。WALアーカイブを有効にする場合は、次の点を考慮してください:

- WALレベルは「replica」以上である必要があります（9.6以降のオプションは`minimal`、`replica`、`logical`です）
- WALレベルを上げると、通常の運用で消費されるストレージの量が増加します

WALアーカイブを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Replication settings
   postgresql['sql_replication_user'] = "gitlab_replicator"
   postgresql['wal_level'] = "replica"
       ...
       ...
   # Backup/Archive settings
   postgresql['archive_mode'] = "on"
   postgresql['archive_command'] = "/your/wal/archiver/here"
   postgresql['archive_timeout'] = "60"
   ```

1. 変更を有効にするため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。これにより、データベースが再起動されます。

### PostgreSQLデータを別のディレクトリに保存する {#store-postgresql-data-in-a-different-directory}

デフォルトでは、すべてのPostgreSQL関連データは`/var/opt/gitlab/postgresql`配下に保存され、この保存先は`postgresql['dir']`属性によって制御されます。

このディレクトリには次のものが含まれます:

- データベースソケットは`/var/opt/gitlab/postgresql/.s.PGSQL.5432`になります。これは`postgresql['unix_socket_directory']`によって制御されます。
- `gitlab-psql`システムユーザーの`HOME`ディレクトリは、ここに設定されます。これは`postgresql['home']`によって制御されます。
- 実際のデータは`/var/opt/gitlab/postgresql/data`に保存されます。

PostgreSQLデータの場所を変更するには

既存のデータベースがある場合は、最初にデータを新しい場所に移動する必要があります。

> [!warning]
> これは侵害的な操作です。既存のインストール環境では、ダウンタイムなしでは実行できません。

1. 既存のインストールの場合、GitLabを停止します: `gitlab-ctl stop`。
1. `postgresql['dir']`を目的の場所に更新します。
1. `gitlab-ctl reconfigure`を実行します。
1. GitLabを起動します: `gitlab-ctl start`。

### パッケージ版PostgreSQLサーバーをアップグレードする {#upgrade-packaged-postgresql-server}

GitLab管理下のPatroniクラスター（PostgreSQL HA）を使用している場合は、代わりに次のドキュメントを参照してください:

- [PatroniクラスターでPostgreSQLのメジャーバージョンをアップグレードする](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)
- [PatroniクラスターでPostgreSQLをほぼゼロダウンタイムでアップグレードする](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)

Linuxパッケージには、`gitlab-ctl pg-upgrade`コマンドが用意されています。パッケージに新しいバージョンが含まれている場合、このコマンドでパッケージ版PostgreSQLサーバーを更新できます。このコマンドは、明示的に[オプトアウト](#opt-out-of-automatic-postgresql-upgrades)していない限り、パッケージのアップグレード中にPostgreSQLを[同梱されているデフォルトのバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)に更新します。

GitLabを新しいバージョンにアップグレードする前に、Linuxパッケージの[バージョン固有の変更](https://docs.gitlab.com/update/#version-specific-upgrading-instructions)を参照し、次のいずれかに該当するかどうかを確認してください:

- データベースのバージョンが変更されるタイミング。
- アップグレードが推奨される時期。

コマンドを実行する前に、このセクションを最後までお読みいただくことが重要です。単一ノードインストールの場合、このアップグレードにはダウンタイムが必要です。アップグレードの実行中はデータベースを停止しておく必要があるためです。所要時間はデータベースのサイズによって異なります。

> [!note]
> アップグレード中に問題が発生した場合は、[`omnibus-gitlab`イシュートラッカー](https://gitlab.com/gitlab-org/omnibus-gitlab)に詳細を添えてイシューを提出してください。

PostgreSQLのバージョンをアップグレードする前に、次のことを確認してください:

- 現在のバージョンのPostgreSQLをサポートする、最新バージョンのGitLabを実行していること。
- 最近アップグレードした場合は、先に進む前に`sudo gitlab-ctl reconfigure`を正常に実行済みであること。
- データベースのコピーを2つ作成できるだけの十分なディスク容量があること。_十分な空き容量がない場合は、アップグレードを試みないでください。_

  - `sudo du -sh /var/opt/gitlab/postgresql/data`（必要に応じてデータベースパスを変更してください）を使用して、データベースのサイズを確認します。
  - `sudo df -h`を使用して空き容量を確認します。データベースが存在するパーティションに十分な空き容量がない場合は、コマンドに`--tmp-dir $DIR`引数を渡します。アップグレードタスクには利用可能なディスク容量のチェックが含まれており、要件を満たしていない場合はアップグレードを中止します。
    - カスタム一時ディレクトリを使用する場合は、正しいユーザーおよびグループの所有権があることを確認してください。`ls -la /var/opt/gitlab/postgresql/data`を実行してオーナーとグループを確認し、`sudo chown <user>:<group> $DIR`で一時ディレクトリに同じ所有権を設定します。デフォルトのインストールの場合、オーナーは`gitlab-psql`、コマンドは`sudo chown gitlab-psql:gitlab-psql $DIR`です。

上記のチェックリストを満たしていることを確認したら、アップグレードに進むことができます:

```shell
sudo gitlab-ctl pg-upgrade
```

特定のPostgreSQLバージョンにアップグレードするには、`-V`フラグを使用してバージョンを指定します。たとえば、PostgreSQL 16にアップグレードするには:

```shell
sudo gitlab-ctl pg-upgrade -V 16
```

> [!note]
> `pg-upgrade`は引数を取ることができます。たとえば、基盤となるコマンドの実行タイムアウトを`--timeout=1d2h3m4s5ms`で設定できます。完全なリストを表示するには、`gitlab-ctl pg-upgrade -h`を実行します。

`gitlab-ctl pg-upgrade`は、次のステップを実行します:

1. データベースが既知の良好な状態であることを確認します。
1. 十分な空きディスク容量があるかどうかを確認し、ない場合は中止します。`--skip-disk-check`フラグを付加すると、このチェックをスキップできます。
1. 既存のデータベースと不要なサービスをすべてシャットダウンし、GitLabのデプロイページを有効にして表示させます。
1. `/opt/gitlab/embedded/bin/`にあるPostgreSQL用のシンボリックリンクを、データベースの新しいバージョンを指すように変更します。
1. 既存のデータベースと同じロケール設定で、新しい空のデータベースを含む新しいディレクトリを作成します。
1. `pg_upgrade`ツールを使用して、古いデータベースから新しいデータベースにデータをコピーします。
1. 古いデータベースを退避させます。
1. 新しいデータベースを所定の場所に移動します。
1. `sudo gitlab-ctl reconfigure`を呼び出して必要な設定変更を行い、新しいデータベースサーバーを起動します。
1. `ANALYZE`を実行してデータベース統計を生成します。
1. 残りのサービスを起動し、デプロイページを削除します。
1. このプロセス中にエラーが検出された場合は、自動的に旧バージョンのデータベースに戻ります。

アップグレードが完了したら、すべてが期待どおりに動作していることを確認してください。

`ANALYZE`ステップの実行中に出力にエラーが発生した場合でもアップグレードは引き続き動作しますが、データベース統計が生成されるまでデータベースのパフォーマンスが低下します。`gitlab-psql`を使用して、`ANALYZE`を手動で実行する必要があるかどうかを判断します:

```shell
sudo gitlab-psql -c "SELECT relname, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL AND last_autoanalyze IS NULL;"
```

上記のクエリで行が返された場合は、手動で`ANALYZE`を実行できます:

```shell
sudo gitlab-psql -c 'SET statement_timeout = 0; ANALYZE VERBOSE;'
```

`ANALYZE`コマンドの実行時間は、データベースのサイズによって大きく変動します。この操作の進行状況を監視するには、別のコンソールセッションで次のクエリを定期的に実行します。`tables_remaining`列は徐々に`0`に近づいていくはずです:

```shell
sudo gitlab-psql -c "
SELECT
    COUNT(*) AS total_tables,
    SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
FROM pg_stat_user_tables;
"
```

GitLabインスタンスが正しく動作していることを確認したら、古いデータベースファイルをクリーンアップします:

```shell
sudo rm -rf /var/opt/gitlab/postgresql/data.<old_version>
sudo rm -f /var/opt/gitlab/postgresql-version.old
```

さまざまなGitLabバージョンに同梱されているPostgreSQLバージョンの詳細については、[Linuxパッケージに同梱されているPostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)を参照してください。

#### PostgreSQLの自動アップグレードをオプトアウトする {#opt-out-of-automatic-postgresql-upgrades}

GitLabパッケージのアップグレード時にPostgreSQLの自動アップグレードをオプトアウトするには、次を実行します:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Dockerイメージを使用している場合は、環境変数`GITLAB_SKIP_PG_UPGRADE`を`true`に設定することで、自動アップグレードを無効にできます。

### パッケージ版PostgreSQLサーバーを前のバージョンに戻す {#revert-packaged-postgresql-server-to-the-previous-version}

> [!warning]
> この操作は、現在のデータベースとそのデータを含む全体を、最終アップグレード前の状態に戻します。パッケージ版PostgreSQLデータベースのリバートを試みる前に、必ずバックアップを作成してください。

旧バージョンのLinuxパッケージは、複数のバージョンのPostgreSQLをバンドルしています。これらのバージョンのいずれかを使用している場合は、`gitlab-ctl revert-pg-upgrade`コマンドを使用して、Linuxパッケージでサポートされている以前のPostgreSQLバージョンにリバートできます。このコマンドは、対象バージョンを指定する`-V`フラグもサポートしています。たとえば、PostgreSQLバージョン14にリバートするには:

```shell
gitlab-ctl revert-pg-upgrade -V 14
```

対象バージョンが指定されていない場合、利用可能な場合は`/var/opt/gitlab/postgresql-version.old`に記録されたバージョンを使用します。利用できない場合は、GitLabに同梱されているデフォルトのバージョンにフォールバックします。

LinuxパッケージのバージョンがPostgreSQLの1つのバージョンしか同梱していない場合は、PostgreSQLのバージョンをリバートすることはできません。これらのLinuxパッケージのバージョンでは、以前のPostgreSQLバージョンを使用するには、GitLab自体を以前のバージョンにロールバックする必要があります。

### 複数のデータベース接続を設定する {#configuring-multiple-database-connections}

{{< history >}}

- `gitlab:db:decomposition:connection_status` Rakeタスクは、GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111927)されました。

{{< /history >}}

GitLab 16.0では、GitLabはデフォルトで、同じPostgreSQLデータベースを指す2つのデータベース接続を使用するようになっています。

GitLab 16.0にアップグレードする前に、PostgreSQLの`max_connections`設定が十分に高く、利用可能な接続の50%超が未使用として表示されることを確認してください。たとえば、`max_connections`が100に設定されていて、使用中の接続数が75である場合は、アップグレード後に使用中の接続数が2倍の150になるため、アップグレード前に`max_connections`を少なくとも150に増やす必要があります。

これは、次のRakeタスクを実行して確認できます:

```shell
sudo gitlab-rake gitlab:db:decomposition:connection_status
```

Rakeタスクが`max_connections`は十分に高いと示した場合は、アップグレードに進むことができます。

## パッケージ版ではないPostgreSQLデータベース管理サーバーを使用する {#using-a-non-packaged-postgresql-database-management-server}

デフォルトでは、GitLabはLinuxパッケージに含まれているPostgreSQLサーバーを使用するように設定されています。PostgreSQLの外部インスタンスを使用するように再設定することもできます。

> [!warning]
> Linuxパッケージに同梱されていないPostgreSQLサーバーを使用している場合は、[データベース要件](https://docs.gitlab.com/install/requirements/#postgresql)に従ってPostgreSQLが設定されていることを確認する必要があります。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = 'USERNAME'
   gitlab_rails['db_password'] = 'PASSWORD'
   ```

   これらの行の先頭にある`#`コメント文字を削除することを忘れないでください。

   注意:

   - `/etc/gitlab/gitlab.rb`には平文のパスワードが含まれているため、ファイル権限は`0600`にする必要があります。
   - PostgreSQLは、[複数のアドレス](https://www.postgresql.org/docs/11/runtime-config-connection.html)でリッスンできます。

     `gitlab_rails['db_host']`に複数のアドレスをカンマ区切りで指定した場合、リストの先頭のアドレスが接続に使用されます。

1. 変更を有効にするため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。
1. [データベースをシードします](#seed-the-database-fresh-installs-only)。
1. オプション。[コンテナレジストリのメタデータデータベースを有効にします](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)。

### パッケージ版ではないPostgreSQLのUNIXソケット設定 {#unix-socket-configuration-for-non-packaged-postgresql}

GitLabにバンドルされているものではなく、（GitLabと同じシステムにインストールされている）システムのPostgreSQLサーバーを使用する場合は、UNIXソケットを使用して設定できます:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Disable the built-in Postgres
   postgresql['enable'] = false

   # Fill in the connection details for database.yml
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'utf8'
   # The path where the socket lives
   gitlab_rails['db_host'] = '/var/run/postgresql/'
   ```

1. 変更を反映するためにGitLabを再設定します:

   ```ruby
   sudo gitlab-ctl-reconfigure
   ```

### SSLを設定する {#configuring-ssl-1}

#### SSLを要求する {#require-ssl-1}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. 設定の変更を適用するため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。

#### SSLを必須にし、CAバンドルに対してサーバー証明書を検証する {#require-ssl-and-verify-server-certificate-against-ca-bundle}

PostgreSQLは、スプーフィングを防ぐためにSSLを必須にし、CAバンドルに対してサーバー証明書を検証するように設定できます。`gitlab_rails['db_sslrootcert']`で指定するCAバンドルには、ルート証明書と中間証明書の両方が含まれている必要があります。

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   gitlab_rails['db_sslmode'] = "verify-full"
   gitlab_rails['db_sslrootcert'] = "<full_path_to_your_ca-bundle.pem>"
   ```

   PostgreSQLサーバーにAmazon RDSを使用している場合は、`gitlab_rails['db_sslrootcert']`には[結合済みのCAバンドル](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem)をダウンロードして使用していることを確認してください。これに関する詳細については、AWSの[SSL/TLSを使用したDBインスタンスへの接続の暗号化](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)に関する記事をご覧ください。

1. 設定の変更を適用するため、[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。

### パッケージ版ではないPostgreSQLデータベースをバックアップおよび復元する {#backup-and-restore-a-non-packaged-postgresql-database}

[バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)コマンドと[復元](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)コマンドを使用すると、GitLabはパッケージ版の`pg_dump`コマンドを使用してデータベースバックアップファイルを作成し、パッケージ版の`psql`コマンドを使用してバックアップを復元しようとします。これは、それらが正しいバージョンである場合にのみ機能します。パッケージ版の`pg_dump`と`psql`のバージョンを確認します:

```shell
/opt/gitlab/embedded/bin/pg_dump --version
/opt/gitlab/embedded/bin/psql --version
```

これらのバージョンが、パッケージ版ではない外部PostgreSQLのバージョンと異なる場合は、[バックアップコマンド](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)を実行を試みた際に、次のエラー出力が発生することがあります。

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 12.6
pg_dump: error: aborting because of server version mismatch
```

この例では、[デフォルトで同梱されているPostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)12.6ではなく、PostgreSQLバージョン13.3を使用している場合に、GitLab 14.1でエラーが発生しています。

この場合、データベースのバージョンに一致するツールをインストールし、次の手順に従う必要があります。PostgreSQLのクライアントツールをインストールする方法は複数あります。オプションについては、<https://www.postgresql.org/download/>を参照してください。

システム上で正しい`psql`および`pg_dump`ツールが利用可能になったら、インストールした新しいツールの場所への正しいパスを使用して、次の手順を実行します:

1. パッケージ版ではないバージョンへのシンボリックリンクを追加します:

   ```shell
   ln -s /path/to/new/pg_dump /path/to/new/psql /opt/gitlab/bin/
   ```

1. バージョンを確認します:

   ```shell
   /opt/gitlab/bin/pg_dump --version
   /opt/gitlab/bin/psql --version
   ```

   これで、パッケージ版ではない外部PostgreSQLと同じバージョンになっているはずです。

この操作が完了したら、[バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)コマンドと[復元](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)コマンドの両方を実行して、バックアップと復元のタスクが正しい実行可能ファイルを使用していることを確認します。

### パッケージ版ではないPostgreSQLデータベースをアップグレードする {#upgrade-a-non-packaged-postgresql-database}

データベース（Puma、Sidekiq）に接続しているすべてのプロセスを停止した後、外部データベースをアップグレードできます:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
```

アップグレードに進む前に、次の点に注意してください:

- GitLabリリースとPostgreSQLバージョン間の互換性を確認してください:
  - どのGitLabバージョンから[PostgreSQLの最小バージョン](https://docs.gitlab.com/install/requirements/#postgresql)の要件を導入されたのかを確認してください。
  - [Linuxパッケージに同梱](https://docs.gitlab.com/administration/package_information/postgresql_versions/)されるPostgreSQLバージョンの重要な変更点について確認してください: Linuxパッケージは、同梱しているPostgreSQLのメジャーリリースとの互換性がテストされています。
- GitLabのバックアップまたは復元を使用する場合、GitLabのバージョンは同じままにしておく必要があります。GitLabも後続のバージョンにアップグレードする予定がある場合は、先にPostgreSQLをアップグレードしてください。
- [バックアップおよび復元コマンド](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)は、より新しいバージョンのPostgreSQLにデータベースをバックアップおよび復元する場合に使用できます。
- `postgresql['version']`で、そのLinuxパッケージのリリースには同梱されていないPostgreSQLバージョンが指定されている場合、[互換性テーブルにあるデフォルトのバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)によって、どのクライアントバイナリ（PostgreSQLのバックアップ/復元用のバイナリなど）が有効になるかが決まります。

次の例は、PostgreSQL 16を実行しているデータベースホストからPostgreSQL 17を実行している別のデータベースホストへのアップグレードを示しており、ダウンタイムが発生します:

1. [データベース要件](https://docs.gitlab.com/install/requirements/#postgresql)に従って設定された新しいPostgreSQL 17 PostgreSQLデータベースサーバーを起動します。
1. GitLab Railsインスタンスで、互換性のあるバージョンの`pg_dump`と`pg_restore`が使用されていることを確認します。GitLabの設定を修正するには、`/etc/gitlab/gitlab.rb`を編集し、`postgresql['version']`の値を指定します:

   ```ruby
   postgresql['version'] = 17
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLabを停止します（この手順によりダウンタイムが発生することに注意してください）:

   ```shell
   sudo gitlab-ctl stop
   ```

> [!warning]
> インストールでPgBouncerを使用している場合、バックアップコマンドには[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

1. SKIPオプションを使用してバックアップRakeタスクを実行し、データベースのみをバックアップします。バックアップのファイル名をメモしておきます。後で復元に使用します。

   ```shell
   sudo gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,pages,registry
   ```

1. PostgreSQL 16 PostgreSQLデータベースホストをシャットダウンします。
1. `/etc/gitlab/gitlab.rb`を編集し、`gitlab_rails['db_host']`設定をPostgreSQL 17 PostgreSQLデータベースホストを指すように更新します。
1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   > [!warning]
   > インストールでPgBouncerを使用している場合、バックアップコマンドには[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

1. 以前に作成したデータベースバックアップファイルを使用してデータベースを復元します。「This task will now rebuild the `authorized_keys` file」と尋ねられたら、必ず**no**と答えてください:

   ```shell
   # Use the backup timestamp https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-timestamp
   sudo gitlab-backup restore BACKUP=<backup-timestamp>
   ```

1. GitLabを起動します:

   ```shell
   sudo gitlab-ctl start
   ```

1. PostgreSQLを新しいメジャーリリースにアップグレードした後は、効率的なクエリプランが選択され、データベースサーバーのCPU負荷を軽減できるように、テーブル統計を再作成します。

   アップグレードが`pg_upgrade`を使用した「インプレース」方式で行われた場合は、PostgreSQLデータベースコンソールで次のクエリを実行します:

   ```sql
   SET statement_timeout = 0; ANALYZE VERBOSE;
   ```

   `ANALYZE`コマンドの実行時間は、データベースのサイズによって大きく変動します。この操作の進行状況を監視するには、別のPostgreSQLデータベースコンソールで次のクエリを定期的に実行します。`tables_remaining`列は徐々に`0`に近づいていくはずです:

   ```sql
   SELECT
     COUNT(*) AS total_tables,
     SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
   FROM pg_stat_user_tables;
   ```

   アップグレードで`pg_dump`と`pg_restore`を使用した場合は、PostgreSQLデータベースコンソールで次のクエリを実行します:

   ```sql
   SET statement_timeout = 0; VACUUM VERBOSE ANALYZE;
   ```

### データベースをシードする（新規インストール時のみ） {#seed-the-database-fresh-installs-only}

> [!warning]
> これは破壊的なコマンドです。既存のデータベースでは実行しないでください。

Linuxパッケージによるインストールでは、外部データベースへのシードは行われません。スキーマをインポートし、最初の管理者ユーザーを作成するには、次のコマンドを実行します:

```shell
# Remove 'sudo' if you are the 'git' user
sudo gitlab-rake gitlab:setup
```

デフォルトの`root`ユーザーのパスワードを指定する場合は、上記の`gitlab:setup`コマンドを実行する前に、`/etc/gitlab/gitlab.rb`の`initial_root_password`設定を指定します:

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

共有GitLab Runnerの最初の登録トークンを指定する場合は、`gitlab:setup`コマンドを実行する前に、`/etc/gitlab/gitlab.rb`の`initial_shared_runners_registration_token`設定を指定します:

```ruby
gitlab_rails['initial_shared_runners_registration_token'] = 'token'
```

### パッケージ版PostgreSQLバージョンを固定する（新規インストール時のみ） {#pin-the-packaged-postgresql-version-fresh-installs-only}

Linuxパッケージには[異なるPostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)が同梱されており、特に指定がない限り、デフォルトのバージョンが初期化されます。

デフォルト以外のバージョンでPostgreSQLを初期化するには、初回の再設定を実行する前に、`postgresql['version']`を[パッケージ版PostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)のいずれかのメジャーバージョンに設定します。たとえば、GitLab 18.11では、デフォルトのPostgreSQL 17ではなく、`postgresql['version'] = 16`を使用してPostgreSQL 16を使用できます。

> [!warning]
> Linuxパッケージに同梱されているPostgreSQLを使用している場合、最初の再設定後に`postgresql['version']`を設定すると、データディレクトリが異なるPostgreSQLのバージョンで初期化されたことに関するエラーが発生します。このエラーが発生した場合は、[パッケージ版PostgreSQLサーバーを前のバージョンに戻す](#revert-packaged-postgresql-server-to-the-previous-version)を参照してください。

以前にGitLabがインストールされていた環境に新規インストールを行い、かつPostgreSQLバージョンを固定して使用する場合は、まずPostgreSQLに関連するフォルダーがすべて削除されていること、およびそのインスタンスでPostgreSQLプロセスが実行されていないことを確認してください。

## 機密データの設定を平文で保存せずにGitLab Railsに提供する {#provide-sensitive-data-configuration-to-gitlab-rails-without-plain-text-storage}

詳細については、[設定ドキュメント](configuration.md#provide-the-postgresql-user-password-to-gitlab-rails)に記載された例を参照してください。

## データベースのアプリケーション設定 {#application-settings-for-the-database}

### 自動データベースマイグレーションを無効にする {#disabling-automatic-database-migration}

複数のGitLabサーバーでデータベースを共有している場合、再設定時にマイグレーション手順を実行するノード数を制限したいことがあります。

`/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します:

```ruby
# Enable or disable automatic database migrations
# on all hosts except the designated deploy node
gitlab_rails['auto_migrate'] = false
```

`/etc/gitlab/gitlab.rb`には平文のパスワードが含まれているため、ファイル権限は`0600`にする必要があります。

次回、上記の設定を保持しているホストで再設定を行うと、マイグレーション手順は実行されません。

スキーマ関連のアップグレード後のエラーを回避するため、アップグレード中は[デプロイノード](https://docs.gitlab.com/update/zero_downtime/)として指定されたホストで`gitlab_rails['auto_migrate'] = true`になっている必要があります。

### クライアントの`statement_timeout`を設定する {#setting-client-statement_timeout}

Railsがデータベーストランザクションの完了を待機し、タイムアウトするまでの時間は、`gitlab_rails['db_statement_timeout']`設定で調整できるようになりました。デフォルトでは、この設定は使用されません。

`/etc/gitlab/gitlab.rb`を編集します:

```ruby
gitlab_rails['db_statement_timeout'] = 45000
```

この場合、クライアントの`statement_timeout`は45秒に設定されます。値はミリ秒単位で指定します。

### 接続タイムアウトを設定する {#setting-connection-timeout}

RailsがPostgreSQLへの接続試行の成功を待機し、タイムアウトするまでの時間は、`gitlab_rails['db_connect_timeout']`設定で調整できます。デフォルトでは、この設定は使用されません:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['db_connect_timeout'] = 5
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

この場合、クライアントの`connect_timeout`は5秒に設定されます。値は秒単位で指定します。最小値は2秒です。これを`<= 0`に設定する、または設定自体を指定しない場合は、タイムアウトが無効になります。

### TCP制御を設定する {#setting-tcp-controls}

Rails PostgreSQLアダプターは、パフォーマンスを向上させるために調整できる一連のTCP接続制御を提供します。各パラメータの詳細については、[PostgreSQLのアップストリームドキュメント](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-KEEPALIVES)を参照してください。

Linuxパッケージでは、これらの値のデフォルトは設定されておらず、PostgreSQLアダプターのデフォルトが使用されます。以下の表に記載されているパラメータを使用して`gitlab.rb`でオーバーライドし、`gitlab-ctl reconfigure`を実行します。

| PostgreSQLのパラメータ  | `gitlab.rb`のパラメータ |
|-----------------------|-----------------------|
| `keepalives`          | `gitlab_rails['db_keepalives']` |
| `keepalives_idle`     | `gitlab_rails['db_keepalives_idle']` |
| `keepalives_interval` | `gitlab_rails['db_keepalives_interval']` |
| `keepalives_count`    | `gitlab_rails['db_keepalives_count']` |
| `tcp_user_timeout`    | `gitlab_rails['db_tcp_user_timeout']` |

## データベースの自動インデックス再作成 {#automatic-database-reindexing}

> [!warning]
> これはデフォルトで有効になっていない実験的な機能です。

バックグラウンドでデータベースのインデックスを再作成します（「インデックス再作成」と呼ばれます）。これは、インデックスに蓄積して肥大化した不要領域を削除し、インデックスを健全かつ効率的に維持するのに役立ちます。

インデックス再作成タスクは、cronjobを介して定期的に開始できます。cronジョブを設定するには、`gitlab_rails['database_reindexing']['enable']`を`true`に設定する必要があります。

マルチノード環境では、この機能はアプリケーションホストでのみ有効にしてください。インデックス再作成プロセスはPgBouncer経由では実行できず、データベースへの直接接続が必要です。

デフォルトでは、週末（トラフィックが少ない可能性が高い時間帯）に限り、毎時cronジョブを開始します。

スケジュールを変更するには、次の設定を調整します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```shell
   gitlab_rails['database_reindexing']['hour'] = '*'
   gitlab_rails['database_reindexing']['minute'] = 0
   gitlab_rails['database_reindexing']['month'] = '*'
   gitlab_rails['database_reindexing']['day_of_month'] = '*'
   gitlab_rails['database_reindexing']['day_of_week'] = '0,6'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Helmチャートのインスタンスがある場合は、代わりに[Toolboxチャート](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configure-periodic-database-reindexing)でデータベースの再インデックスCronJobを有効にできます。

## HA/Geoクラスターにデプロイされたパッケージ版PostgreSQL {#packaged-postgresql-deployed-in-an-hageo-cluster}

### GitLab HAクラスターをアップグレードする {#upgrading-a-gitlab-ha-cluster}

PatroniクラスターでPostgreSQLのバージョンをアップグレードするには、[PatroniクラスターでPostgreSQLのメジャーバージョンをアップグレードする](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)を参照してください。

### HAクラスターでのアップグレードのトラブルシューティング {#troubleshooting-upgrades-in-an-ha-cluster}

HA構成にアップグレードする前に、いずれかの時点でバンドルされたPostgreSQLがノード上で稼働していた場合、古いデータディレクトリが残っていることがあります。これにより、そのノードで`gitlab-ctl reconfigure`を実行すると、そのノードで使用されるPostgreSQLユーティリティのバージョンがダウングレードされてしまいます。これを防ぐために、ディレクトリを移動（または削除）します:

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

`gitlab-ctl repmgr standby setup MASTER_NODE_NAME`を使用してセカンダリノードを再作成する際に次のエラーが発生した場合は、`/etc/gitlab/gitlab.rb`に`postgresql['max_replication_slots'] = X`（`X`はDBノードの数+ 1）を含めていることを確認してください:

```shell
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geoインスタンスをアップグレードする {#upgrading-a-geo-instance}

GeoはデフォルトでPostgreSQLストリーミングレプリケーションに依存しているため、GitLabをアップグレードするとき、またはPostgreSQLをアップグレードするときは、以下に示すように追加の考慮事項があります。

#### Geo環境でPostgreSQLをアップグレードする際の注意事項 {#caveats-when-upgrading-postgresql-with-geo}

> [!warning]
> Geoを使用している場合、PostgreSQLのアップグレードにはすべてのセカンダリでダウンタイムが必要です。これは、Geo **secondaries**へのPostgreSQLレプリケーションを再初期化する必要があるためです。これは、PostgreSQLストリーミングレプリケーションの仕組みによるものです。レプリケーションを再初期化すると、プライマリからすべてのデータが再度コピーされるため、主にデータベースのサイズと利用可能な帯域幅によっては長い時間がかかる場合があります。たとえば、転送速度が30 Mbpsでデータベースサイズが100 GBの場合、再同期には約8時間かかる可能性があります。詳細については、[PostgreSQLドキュメント](https://www.postgresql.org/docs/11/pgupgrade.html)を参照してください。

#### Geo使用時にPostgreSQLをアップグレードする方法 {#how-to-upgrade-postgresql-when-using-geo}

PostgreSQLをアップグレードするには、レプリケーションスロット名と、レプリケーションユーザーのパスワードが必要です。

1. Geoプライマリのデータベースノードで既存のレプリケーションスロット名を確認するには、次を実行します:

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

   ここで`slot_name`が見つからない、または出力が返されない場合は、Geoセカンダリが正常ではない可能性があります。その場合は、[セカンダリが正常で、レプリケーションが機能している](https://docs.gitlab.com/administration/geo/replication/troubleshooting/common/#health-check-rake-task)ことを確認してください。

   クエリ結果が空であっても、[Geoサイトの管理者エリア](https://docs.gitlab.com/administration/geo_sites/)で見つかった`slot_name`を使用して、セカンダリデータベースの再初期化を試すことができます。

1. レプリケーションユーザーのパスワードを収集します。これは、[ステップ1のプライマリサイトを設定する](https://docs.gitlab.com/administration/geo/setup/database/#step-1-configure-the-primary-site)でGeoをセットアップする際に設定しました。

1. オプション。[各**セカンダリ**サイトでレプリケーションを一時停止](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)し、ディザスターリカバリー（DR）機能を保護します。

1. GeoプライマリでPostgreSQLを手動でアップグレードします。Geoプライマリのデータベースノードで次を実行します:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   **プライマリデータベース**のアップグレードが完了するまで待ってから、次の手順を開始してください。そうすることで、セカンダリをバックアップとして利用可能な状態に維持できます。その後、**トラッキングデータベース**は**セカンダリデータベース**と並行してアップグレードできます。

1. GeoセカンダリでPostgreSQLを手動でアップグレードします。Geo**セカンダリデータベース**と**トラッキングデータベース**で次を実行します:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. 次のコマンドを使用して、Geo**セカンダリデータベース**でデータベースレプリケーションを再開します:

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME --sslmode=verify-ca
   ```

   プライマリのレプリケーションユーザーのパスワード入力を求めるプロンプトが表示されます。`SECONDARY_SLOT_NAME`は、上記の最初の手順で取得したスロット名に置き換えます。

   この操作のデフォルトのタイムアウトは30分です。タイムアウトを延長する必要がある場合は、`--backup-timeout`オプションを設定します。たとえば、`--backup-timeout=21600`と指定すると、初回レプリケーションの完了までに6時間の猶予が与えられます。

1. Geo**セカンダリデータベース**で[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、`pg_hba.conf`ファイルを更新します。`replicate-geo-database`がプライマリのファイルをセカンダリにレプリケートするため、これが必要です。

1. 手順3でレプリケーションを一時停止した場合は、[各**セカンダリ**でレプリケーションを再開](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)します。

1. `puma`、`sidekiq`、`geo-logcursor`を再起動します。

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. `https://your_primary_server/admin/geo/sites`に移動し、すべてのGeoサイトが正常であることを確認します。

## PostgreSQLデータベースに接続する {#connecting-to-the-postgresql-database}

PostgreSQLデータベースに接続する必要がある場合は、アプリケーションユーザーとして接続できます:

```shell
sudo gitlab-rails dbconsole --database main
```

## トラブルシューティング {#troubleshooting}

### `default_transaction_isolation`を`read committed`に設定する {#set-default_transaction_isolation-into-read-committed}

`production/sidekiq`ログに次のようなエラーが表示される場合:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

データベースの`default_transaction_isolation`設定がGitLabアプリケーションの要件に準拠していない可能性があります。PostgreSQLデータベースに接続し、`SHOW default_transaction_isolation;`を実行して、この設定を確認できます。GitLabアプリケーションは`read committed`が設定されていることを前提としています。

この`default_transaction_isolation`設定は、`postgresql.conf`ファイルで設定します。設定を変更した後は、データベースの再起動/再読み込みが必要です。この設定は、Linuxパッケージに含まれているパッケージ版PostgreSQLサーバーではデフォルトで設定されています。

### `plpgsql.so`ライブラリを読み込めない {#could-not-load-library-plpgsqlso}

データベースマイグレーションの実行中、またはPostgreSQL/Patroniのログに、次のようなエラーが表示される場合があります:

```plaintext
ERROR:  could not load library "/opt/gitlab/embedded/postgresql/12/lib/plpgsql.so": /opt/gitlab/embedded/postgresql/12/lib/plpgsql.so: undefined symbol: EnsurePortalSnapshotExists
```

このエラーは、基盤となるバージョンが変更された後、PostgreSQLを再起動していないことが原因で発生します。このエラーを修正するには:

1. 次のいずれかのコマンドを実行します:

   ```shell
   # For PostgreSQL
   sudo gitlab-ctl restart postgresql

   # For Patroni
   sudo gitlab-ctl restart patroni

   # For Geo PostgreSQL
   sudo gitlab-ctl restart geo-postgresql
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### データベースのCPU負荷が非常に高い {#database-cpu-load-very-high}

データベースのCPU負荷が非常に高い場合、[自動キャンセル冗長パイプライン設定](https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines)が原因である可能性があります。詳細については、[イシュー435250](https://gitlab.com/gitlab-org/gitlab/-/issues/435250)を参照してください。

この問題を回避するには:

- データベースサーバーにより多くのCPUリソースを割り当てることができます。
- Sidekiqがオーバーロード状態になっている場合、プロジェクトに非常に多くのパイプラインがあるときは、`ci_cancel_redundant_pipelines`キュー用に[Sidekiqプロセスをさらに追加](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#start-multiple-processes)する必要があるかもしれません。
- `disable_cancel_redundant_pipelines_service`機能フラグを有効にして、この設定をインスタンス全体で無効にし、CPU負荷が低下するかどうかを確認できます。これにより、すべてのプロジェクトでこの機能が無効になります。また、自動的にキャンセルされなくなったパイプラインによってリソース使用量が増加する可能性があります。

### エラー: `TypeError: can't quote Array` {#error-typeerror-cant-quote-array}

Amazon RDSを使用している場合、`gitlab::database_migrations`タスクの実行中に、`TypeError: can't quote Array`というエラーが表示されることがあります。

この[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/356307)を回避するには、PostgreSQLデータベースのRDSで[`quote_all_identifiers`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html)パラメータを無効にします。
