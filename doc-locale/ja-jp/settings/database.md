---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: データベース設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、PostgreSQLデータベース管理システムのみをサポートしています。

したがって、Linuxパッケージインストールで使用するデータベースサーバーには、次の2つのオプションがあります:

- Linuxパッケージインストールに含まれる、パッケージ化されたPostgreSQLデータベースサーバーを使用します（設定は不要、推奨）。
- [パッケージ化されていないPostgreSQLデータベースサーバー](#using-a-non-packaged-postgresql-database-management-server)を使用します。

## Linuxパッケージに同梱されているPostgreSQLデータベースサービスの使用 {#using-the-postgresql-database-service-shipped-with-the-linux-package}

### 再構成およびPostgreSQLの再起動 {#reconfigure-and-postgresql-restarts}

Linuxパッケージインストールでは通常、そのサービスの設定が`gitlab.rb`ファイルで変更された場合、再構成時にサービスが再起動されます。PostgreSQLは、一部の設定がリロード（HUP）で有効になる一方、PostgreSQLの再起動が必要になる点で独特です。管理者はPostgreSQLが再起動されるタイミングを正確に制御したいことが多いため、Linuxパッケージインストールは、再構成時にPostgreSQLを再起動ではなくリロードするように設定されています。つまり、再起動が必要なPostgreSQLの設定を変更した場合は、再構成後にPostgreSQLを手動で再起動する必要があります。

[GitLab設定テンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)は、PostgreSQLのどの設定に再起動が必要で、どの設定にリロードのみが必要かを識別します。また、データベースに対してクエリを実行して、個々の設定に再起動が必要かどうかを判断することもできます。`sudo gitlab-psql`でデータベースコンソールを開始し、次のクエリの`<setting name>`を変更する設定に置き換えます:

```sql
SELECT name,setting FROM pg_settings WHERE context = 'postmaster' AND name = '<setting name>';
```

設定の変更に再起動が必要な場合、クエリは、実行中のPostgreSQLデータベースインスタンス内の設定の名前と現在の値を返します。

#### PostgreSQLのバージョン変更時の自動再起動 {#automatic-restart-when-the-postgresql-version-changes}

デフォルトでは、Linuxパッケージインストールは、[アップストリームドキュメント](https://www.postgresql.org/docs/16/upgrading.html)で推奨されているように、基盤となるバージョンが変更されると、PostgreSQLを自動的に再起動します。この動作は、`postgresql`および`geo-postgresql`で使用可能な`auto_restart_on_version_change`設定を使用して制御できます。

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

{{< alert type="note" >}}

[必要なライブラリのロードに関連するもの](#could-not-load-library-plpgsqlso)のようなエラーを回避するために、基盤となるバージョンが変更されたら、PostgreSQLを再起動することを強くお勧めします。

{{< /alert >}}

### SSLの設定 {#configuring-ssl}

Linuxパッケージインストールは、PostgreSQLサーバーでSSLを自動的に有効にしますが、デフォルトでは暗号化された接続と暗号化されていない接続の両方を受け入れます。SSLを強制するには、`pg_hba.conf`で`hostssl`設定を使用する必要があります。詳細については、[`pg_hba.conf`ドキュメント](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html)を参照してください。

SSLサポートは、次のファイルに依存します:

- データベースの公開SSL証明書（`server.crt`）。
- SSL証明書に対応する秘密キー（`server.key`）。
- サーバーの証明書を検証するルート証明書バンドル（`root.crt`）。デフォルトでは、Linuxパッケージインストールは、`/opt/gitlab/embedded/ssl/certs/cacert.pem`に埋め込まれた証明書バンドルを使用します。これは、自己署名証明書には必要ありません。

10年間の自己署名証明書と秘密キーは、使用するためにLinuxパッケージインストールによって生成されます。CA署名証明書を使用するか、これを独自の自己署名証明書に置き換える場合は、次の手順に従ってください。

これらのファイルの場所は設定可能ですが、秘密キーは`gitlab-psql`ユーザーが読み取り可能である必要があります。Linuxパッケージインストールはファイルのアクセス許可を管理しますが、パスがカスタマイズされている場合は、`gitlab-psql`がファイルが配置されているディレクトリにアクセスできることを確認する必要があります。

詳細については、[PostgreSQLドキュメント](https://www.postgresql.org/docs/16/ssl-tcp.html)を参照してください。

`server.crt`と`server.key`は、GitLabへのアクセスに使用されるデフォルトのSSL証明書とは異なる場合があることに注意してください。たとえば、データベースの外部ホスト名が`database.example.com`で、外部GitLabホスト名が`gitlab.example.com`であるとします。`*.example.com`のワイルドカード証明書か、2つの異なるSSL証明書のいずれかが必要になります。

`ssl_cert_file`、`ssl_key_file`、および`ssl_ca_file`ファイルは、証明書、キー、およびバンドルを検索するためにファイルシステム上のどこにPostgreSQLを指示します。これらの変更は`postgresql.conf`に適用されます。ディレクティブ`internal_certificate`と`internal_key`は、これらのファイルの内容を入力するために使用されます。コンテンツは、次の例に示すように、直接追加することも、ファイルからロードすることもできます。

これらのファイルを入手したら、SSLを有効にします:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   postgresql['ssl_cert_file'] = '/custom/path/to/server.crt'
   postgresql['ssl_key_file'] = '/custom/path/to/server.key'
   postgresql['ssl_ca_file'] = '/custom/path/to/bundle.pem'
   postgresql['internal_certificate'] = File.read('/custom/path/to/server.crt')
   postgresql['internal_key'] = File.read('/custom/path/to/server.key')
   ```

   相対パスは、PostgreSQLデータベースのデータディレクトリ（デフォルトでは`/var/opt/gitlab/postgresql/data`）にルート化されます。

1. [GitLabを再構成](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、設定の変更を適用します。

1. 変更を有効にするには、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQLの起動に失敗した場合は、詳細についてログ（たとえば、`/var/log/gitlab/postgresql/current`）を確認してください。

#### SSLを要求する {#require-ssl}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [GitLabを再構成](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、設定の変更を適用します。

#### SSLの無効化 {#disabling-ssl}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   postgresql['ssl'] = 'off'
   ```

1. [GitLabを再構成](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、設定の変更を適用します。

1. 変更を有効にするには、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

   PostgreSQLの起動に失敗した場合は、詳細についてログ（たとえば、`/var/log/gitlab/postgresql/current`）を確認してください。

#### SSLが使用されていることの検証 {#verifying-that-ssl-is-being-used}

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

1. `ssl`列の`t`にリストされている行が有効になっています。
1. `clientdn`に値がある行は、`cert`認証方式を使用しています

#### SSLクライアント認証の設定 {#configure-ssl-client-authentication}

クライアントSSL証明書を使用して、データベースサーバーに対して認証できます。証明書の作成は、`omnibus-gitlab`のスコープ外です。ただし、既存のSSL証明書管理ソリューションをお持ちのユーザーは、これを使用できます。

##### データベースサーバーの設定 {#configure-the-database-server}

1. サーバーの証明書とキーを作成します。共通名はサーバーのDNS名と一致する必要があります
1. サーバー証明書、キー、およびCAファイルをPostgreSQLデータベースサーバーにコピーし、アクセス許可が正しいことを確認します
   1. 証明書は、データベースユーザー（デフォルト: `gitlab-psql`）が所有している必要があります
   1. キーファイルはデータベースユーザーが所有している必要があり、そのアクセス許可は`0400`である必要があります
   1. CAファイルはデータベースユーザーが所有している必要があり、そのアクセス許可は`0400`である必要があります

   {{< alert type="note" >}}

   これらのファイルにファイル名`server.crt`または`server.key`を使用しないでください。これらのファイル名は、`omnibus-gitlab`の内部使用のために予約されています。

   {{< /alert >}}

1. 次のものが`gitlab.rb`に設定されていることを確認します:

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

   `listen_address`を、クライアントがデータベースへの接続に使用するサーバーのIPアドレスとして設定します。`cert_auth_addresses`に、IPアドレスのリストと、データベースへの接続が許可されているデータベースとユーザーが含まれていることを確認します。`cert_auth_addresses`のキーを指定するときにCIDR表記を使用して、IPアドレス範囲を組み込むことができます。

1. `gitlab-ctl reconfigure`を実行し、新しい設定を有効にするには`gitlab-ctl restart postgresql`を実行します。

#### Railsクライアントの設定 {#configure-the-rails-client}

Railsクライアントがサーバーに接続するには、`commonName`が`gitlab`に設定された証明書とキーが必要になります。これは、データベースサーバーの`ssl_ca_file`で指定されたCAファイルで信頼されている認証局によって署名されています。

1. `gitlab.rb`を設定します

   ```ruby
   gitlab_rails['db_host'] = 'IP_ADDRESS_OR_HOSTNAME_OF_DATABASE_SERVER'
   gitlab_rails['db_sslcert'] = 'PATH_TO_CERTIFICATE_FILE'
   gitlab_rails['db_sslkey'] = 'PATH_TO_KEY_FILE'
   gitlab_rails['db_rootcert'] = 'PATH_TO_CA_FILE'
   ```

1. Railsクライアントが新しい設定を使用するように`gitlab-ctl reconfigure`を実行します
1. [SSLが使用されていることの検証](#verifying-that-ssl-is-being-used)の手順に従って、認証が機能していることを確認します。

### TCP/IPでリッスンするようにパッケージ化されたPostgreSQLサーバーを設定する {#configure-packaged-postgresql-server-to-listen-on-tcpip}

パッケージ化されたPostgreSQLサーバーは、TCP/IP接続をリッスンするように設定できます。ただし、重要でない一部のスクリプトはUNIXソケットを想定しており、誤動作する可能性があります。

データベースサービスにTCP/IPを使用するように設定するには、`gitlab.rb`の`postgresql`セクションと`gitlab_rails`セクションの両方に変更を加えます。

#### PostgreSQLブロックの設定 {#configure-postgresql-block}

次の設定は、`postgresql`ブロックで影響を受けます:

- `listen_address`: PostgreSQLがリッスンするアドレスを制御します。
- `port`: PostgreSQLがリッスンするポートを制御します。デフォルトは`5432`です。
- `md5_auth_cidr_addresses`: パスワードによる認証後、サーバーへの接続が許可されるCIDRアドレスブロックのリスト。
- `trust_auth_cidr_addresses`: あらゆる種類の認証なしで、サーバーへの接続が許可されるCIDRアドレスブロックのリスト。この設定は、GitLab RailsやSidekiqなど、接続を必要とするノードからの接続を許可するようにのみ設定する必要があります。これには、同じノードにデプロイされた場合、またはPostgres  Exporter（`127.0.0.1/32`）などのコンポーネントからのローカル接続が含まれます。
- `sql_user`: MD5認証に予想されるユーザー名を制御します。これはデフォルトで`gitlab`になり、必須の設定ではありません。
- `sql_user_password`: PostgreSQLがMD5認証に受け入れるパスワードを設定します。

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

1. GitLabを再構成し、PostrgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

ネットワーク経由で接続するクライアントまたはGitLabサービスは、PostgreSQLサーバーへの接続時に、ユーザー名の`sql_user`の値と設定に提供されたパスワードを提供する必要があります。また、`md5_auth_cidr_addresses`に提供されるネットワークブロックに含まれている必要があります

#### GitLab Railsブロックの設定 {#configure-gitlab-rails-block}

ネットワーク経由でPostgreSQLデータベースに接続するように`gitlab-rails`アプリケーションを設定するには、いくつかの設定を設定する必要があります:

- `db_host`: データベースサーバーのIPアドレスに設定する必要があります。これがPostgreSQLサービスと同じインスタンス上にある場合は、`127.0.0.1`にすることができ、パスワード認証は必要ありません。
- `db_port`: 接続するPostgreSQLサーバーのポートを設定します。`db_host`が設定されている場合は、設定する必要があります。
- `db_username`: PostgreSQLへの接続に使用するユーザー名を設定します。これはデフォルトで`gitlab`になります。
- `db_password`: TCP/IP経由でPostgreSQLに接続する場合、および上記の設定の`postgresql['md5_auth_cidr_addresses']`ブロック内のインスタンスから提供する必要があります。これは、`127.0.0.1`に接続していて、`postgresql['trust_auth_cidr_addresses']`にそれを含めるように設定している場合は必要ありません。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['db_host'] = '127.0.0.1'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "securesqlpassword"
   ```

1. GitLabを再構成し、PostrgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

#### サービスの適用と再起動 {#apply-and-restart-services}

以前の変更を加えた後、管理者は`gitlab-ctl reconfigure`を実行する必要があります。TCPでリッスンしていないサービスに関して問題が発生した場合は、`gitlab-ctl restart postgresql`を使用してサービスを直接再起動してみてください。

Linuxパッケージ（`gitlab-psql`など）に含まれる一部のスクリプトは、PostgreSQLへの接続がUNIXソケット経由で処理されることを想定しており、正しく機能しない場合があります。UNIXソケットを無効にせずにTCP/IPを有効にすることができます。

他のクライアントからのアクセスをテストするには、次を実行します:

```shell
sudo gitlab-rails dbconsole --database main
```

### PostgreSQLWAL（Write Ahead Log）アーカイブの有効化 {#enabling-postgresql-wal-write-ahead-log-archiving}

デフォルトでは、パッケージ化されたPostgreSQLのWALアーカイブは有効になっていません。WALアーカイブを有効にする場合は、次の点を考慮してください:

- WALレベルは「replica」以上である必要があります（9.6+オプションは`minimal`、`replica`、または`logical`です）
- WALレベルを上げると、通常操作で消費されるストレージの量が増加します

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

1. 変更を有効にするには、[GitLabを再設定します](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。これにより、データベースが再起動されます。

### PostgreSQLデータを別のディレクトリに保存する {#store-postgresql-data-in-a-different-directory}

デフォルトでは、すべて`/var/opt/gitlab/postgresql`の下に保存され、`postgresql['dir']`属性によって制御されます。

内容は次のとおりです:

- データベースソケットは`/var/opt/gitlab/postgresql/.s.PGSQL.5432`になります。これは`postgresql['unix_socket_directory']`によって制御されます。
- `gitlab-psql`システムユーザーには、その`HOME`ディレクトリがこれに設定されます。これは`postgresql['home']`によって制御されます。
- 実際のデータは`/var/opt/gitlab/postgresql/data`に保存されます。

PostgreSQLデータの場所を変更するには

{{< alert type="warning" >}}

既存のデータベースがある場合は、最初にデータを新しい場所に移動する必要があります。

{{< /alert >}}

{{< alert type="warning" >}}

これは侵入的な操作です。既存のインストール{{< /alert >}}でダウンタイムなしで実行することはできません

1. 既存のインストールの場合、GitLabを停止します: `gitlab-ctl stop`。
1. `postgresql['dir']`を目的の場所に更新します。
1. `gitlab-ctl reconfigure`を実行します。
1. GitLab `gitlab-ctl start`を起動します。

### パッケージ化されたPostgreSQLサーバーのアップグレード {#upgrade-packaged-postgresql-server}

{{< alert type="note" >}}

GitLabによって管理されるPatroniクラスター（PostgreSQL HA）がある場合は、代わりに次のドキュメントを使用してください:

- [PatroniクラスターでのPostgreSQLのメジャーバージョンのアップグレード](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)
- [PatroniクラスターでのPostgreSQLのほぼゼロダウンタイムアップグレード](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)

{{< /alert >}}

Linuxパッケージには、`gitlab-ctl pg-upgrade`コマンドが用意されており、パッケージ化されたPostgreSQLサーバーを（パッケージに含まれている場合）より新しいバージョンに更新します。これにより、特に[オプトアウト](#opt-out-of-automatic-postgresql-upgrades)しない限り、パッケージのアップグレード中にPostgreSQLが[デフォルト](https://docs.gitlab.com/administration/package_information/postgresql_versions/)で出荷されるバージョンに更新されます。

GitLabを新しいバージョンにアップグレードする前に、Linuxパッケージの[バージョン固有の変更](https://docs.gitlab.com/update/#version-specific-upgrading-instructions)を参照して、次のいずれかを確認してください:

- データベースのバージョンが変更された場合。
- アップグレードが正当化される場合。

{{< alert type="warning" >}}

アップグレードする前に、コマンドを実行する前にこのセクションを完全に読んでおくことが重要です。単一ノードインストールの場合、このアップグレードではダウンタイムが必要です。データベースはアップグレードの実行中は停止する必要があるためです。時間の長さは、データベースのサイズによって異なります。

{{< /alert >}}

{{< alert type="note" >}}

アップグレード中に問題が発生した場合は、詳細な説明を添えて[`omnibus-gitlab`イシュートラッカー](https://gitlab.com/gitlab-org/omnibus-gitlab)でイシューを提起してください。

{{< /alert >}}

PostgreSQLのバージョンをアップグレードするには、次のことを確認してください:

- 現在のバージョンのPostgreSQLをサポートする最新バージョンのGitLabを実行しています。
- 最近アップグレードした場合は、続行する前に`sudo gitlab-ctl reconfigure`が正常に実行されていること。
- データベースの2つのコピーに十分なディスク容量がある。_十分な空き容量がない場合は、アップグレードを試みないでください。_

  - `sudo du -sh /var/opt/gitlab/postgresql/data`（またはデータベースパスを更新します）を使用して、データベースのサイズを確認します。
  - `sudo df -h`を使用して使用可能なスペースを確認します。データベースが存在するパーティションに十分なスペースがない場合は、`--tmp-dir $DIR`引数をコマンドに渡します。アップグレードタスクには、利用可能なディスク容量チェックが含まれており、要件が満たされない場合はアップグレードを中止します。

上記のチェックリストが満たされていることを確認したら、アップグレードに進むことができます:

```shell
sudo gitlab-ctl pg-upgrade
```

特定のPostgreSQLバージョンにアップグレードするには、`-V`フラグを使用してバージョンを追加します。たとえば、PostgreSQL 16にアップグレードするには:

```shell
sudo gitlab-ctl pg-upgrade -V 16
```

{{< alert type="note" >}}

`pg-upgrade`は引数を取ることができます。たとえば、基になるコマンドの実行にタイムアウトを設定できます（`--timeout=1d2h3m4s5ms`）。完全なリストを表示するには、`gitlab-ctl pg-upgrade -h`を実行します。

{{< /alert >}}

`gitlab-ctl pg-upgrade`は、次のステップを実行します:

1. データベースが既知の良好な状態であることを確認します。
1. 十分な空きディスク容量があるかどうかを確認し、ない場合は中止します。`--skip-disk-check`フラグを付加すると、これをスキップできます。
1. 既存のデータベースと不要なサービスをすべてシャットダウンし、GitLabがデプロイページをデプロイできるようにします。
1. PostgreSQLの`/opt/gitlab/embedded/bin/`内のシンボリックリンクを、データベースの新しいバージョンを指すように変更します。
1. 既存のデータベースと一致するロケールを持つ、新しい空のデータベースを含む新しいディレクトリを作成します。
1. `pg_upgrade`ツールを使用して、古いデータベースから新しいデータベースにデータをコピーします。
1. 古いデータベースを移動します。
1. 新しいデータベースを期待される場所に移動します。
1. `sudo gitlab-ctl reconfigure`を呼び出して、必要な設定変更を行い、新しいデータベースサーバーを起動します。
1. `ANALYZE`を実行してデータベース統計を生成します。
1. 残りのサービスを開始し、デプロイページを削除します。
1. このプロセス中にエラーが検出された場合は、古いバージョンのデータベースに戻ります。

アップグレードが完了したら、すべてが期待どおりに動作していることを確認してください。

`ANALYZE`ステップの実行中に出力にエラーが発生した場合、データベース統計が生成されるまで、アップグレードは引き続き動作しますが、データベースのパフォーマンスが低下します。`gitlab-psql`を使用して、`ANALYZE`を手動で実行する必要があるかどうかを判断します:

```shell
sudo gitlab-psql -c "SELECT relname, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL AND last_autoanalyze IS NULL;"
```

上記のクエリで行が返された場合は、手動で`ANALYZE`を実行できます:

```shell
sudo gitlab-psql -c 'SET statement_timeout = 0; ANALYZE VERBOSE;'
```

`ANALYZE`コマンドの実行時間は、データベースのサイズによって大きく異なる場合があります。この操作の進行状況を監視するには、別のコンソールセッションで次のクエリを定期的に実行します。`tables_remaining`列は徐々に`0`に達するはずです:

```shell
sudo gitlab-psql -c "
SELECT
    COUNT(*) AS total_tables,
    SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
FROM pg_stat_user_tables;
"
```

GitLabインスタンスが正しく実行されていることを確認したら、古いデータベースファイルをクリーンアップできます:

```shell
sudo rm -rf /var/opt/gitlab/postgresql/data.<old_version>
sudo rm -f /var/opt/gitlab/postgresql-version.old
```

さまざまなGitLabバージョンに同梱されているPostgreSQLバージョンの詳細は、[Linuxパッケージ](https://docs.gitlab.com/administration/package_information/postgresql_versions/)に同梱されているPostgreSQLバージョンにあります。

#### PostgreSQLの自動アップグレードをオプトアウト {#opt-out-of-automatic-postgresql-upgrades}

GitLabパッケージのアップグレード中にPostgreSQLの自動アップグレードをオプトアウトするには、次を実行します:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

Dockerイメージを使用している場合は、`GITLAB_SKIP_PG_UPGRADE`環境変数を`true`に設定すると、自動アップグレードを無効にできます。

### パッケージ化されたPostgreSQLサーバーを前のバージョンに戻す {#revert-packaged-postgresql-server-to-the-previous-version}

{{< alert type="warning" >}}

この操作により、現在のデータベース（データを含む）が、前回のアップグレード前の状態に戻ります。パッケージ化されたPostgreSQLデータベースをロールバックする前に、バックアップを必ず作成してください。

{{< /alert >}}

以前のバージョンのLinuxパッケージは、複数のバージョンのPostgreSQLをバンドルしています。これらのバージョンのいずれかを使用している場合は、`gitlab-ctl revert-pg-upgrade`コマンドを使用して、Linuxパッケージでサポートされている以前のPostgreSQLバージョンにロールバックできます。このコマンドは、ターゲットバージョンを指定するための`-V`フラグもサポートしています。たとえば、PostgreSQLバージョン14にロールバックするには、次のようにします:

```shell
gitlab-ctl revert-pg-upgrade -V 14
```

ターゲットバージョンが指定されていない場合、コマンドは利用可能な場合は`/var/opt/gitlab/postgresql-version.old`内のバージョンを使用します。それ以外の場合は、GitLabに同梱されているデフォルトのバージョンにフォールバックします。

1つのPostgreSQLバージョンのみを同梱するLinuxパッケージのバージョンを使用している場合は、PostgreSQLバージョンをロールバックできません。これらのLinuxパッケージのバージョンでは、以前のPostgreSQLバージョンを使用するには、GitLabを以前のバージョンにロールバックする必要があります。

### 複数のデータベース接続の設定 {#configuring-multiple-database-connections}

{{< history >}}

- `gitlab:db:decomposition:connection_status` Rakeタスクは、GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111927)されました。

{{< /history >}}

GitLab 16.0では、GitLabはデフォルトで、同じPostgreSQLデータベースを指す2つのデータベース接続を使用するようになっています。

GitLab 16.0にアップグレードする前に、使用可能な接続の50%以上が未使用として表示されるように、PostgreSQLの`max_connections`設定が十分に高いことを確認してください。たとえば、`max_connections`が100に設定されていて、75個の接続が使用されている場合は、アップグレード後に使用中の接続が2倍の150になるため、アップグレードする前に`max_connections`を少なくとも150に増やす必要があります。

これは、次のRakeタスクを実行して確認できます:

```shell
sudo gitlab-rake gitlab:db:decomposition:connection_status
```

Rakeタスクで`max_connections`が十分に高いことが示されている場合は、アップグレードに進むことができます。

## パッケージ化されていないPostgreSQLデータベース管理サーバーの使用 {#using-a-non-packaged-postgresql-database-management-server}

デフォルトでは、GitLabはLinuxパッケージに含まれているPostgreSQLサーバーを使用するように設定されています。PostgreSQLの外部インスタンスを使用するように再設定することもできます。

{{< alert type="warning" >}}

パッケージ化されていないPostgreSQLサーバーを使用している場合は、[データベース要件](https://docs.gitlab.com/install/requirements/#postgresql)に従ってPostgreSQLがセットアップされていることを確認する必要があります。

{{< /alert >}}

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

   - `/etc/gitlab/gitlab.rb`にはプレーンテキストのパスワードが含まれているため、ファイル権限`0600`が必要です。
   - PostgreSQLでは、[複数のアドレス](https://www.postgresql.org/docs/11/runtime-config-connection.html)でのリスニングが可能です

     `gitlab_rails['db_host']`に複数のアドレスをコンマ区切りで使用する場合、リストの最初のアドレスが接続に使用されます。

1. 変更を有効にするには、[GitLabを再設定します](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)。

1. [データベースのシード](#seed-the-database-fresh-installs-only)。

1. オプション。[コンテナレジストリメタデータデータベースを有効にします](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)。

### パッケージ化されていないPostgreSQLのUNIXソケット設定 {#unix-socket-configuration-for-non-packaged-postgresql}

GitLabにバンドルされているものではなく、システムのPostgreSQLサーバー（GitLabと同じシステムにインストールされている）を使用する場合は、UNIXソケットを使用することでこれを行うことができます:

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

1. 変更を有効にするには、GitLabを再設定します:

   ```ruby
   sudo gitlab-ctl-reconfigure
   ```

### SSLの設定 {#configuring-ssl-1}

#### SSLを要求する {#require-ssl-1}

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['db_sslmode'] = 'require'
   ```

1. [GitLabを再構成](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、設定の変更を適用します。

#### CAバンドルに対してSSLを要求し、サーバー証明書を検証します {#require-ssl-and-verify-server-certificate-against-ca-bundle}

PostgreSQLは、スプーフィングを防ぐために、SSLを要求し、CAバンドルに対してサーバー証明書を検証するように設定できます。`gitlab_rails['db_sslrootcert']`で指定されたCAバンドルには、ルート証明書と中間証明書の両方が含まれている必要があります。

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['db_sslmode'] = "verify-full"
   gitlab_rails['db_sslrootcert'] = "<full_path_to_your_ca-bundle.pem>"
   ```

   PostgreSQLサーバーにAmazon RDSを使用している場合は、`gitlab_rails['db_sslrootcert']`の[結合されたCAバンドル](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem)をダウンロードして使用してください。これに関する詳細については、AWSの[SSL/TLSを使用したDBインスタンスへの接続の暗号化](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)に関する記事をご覧ください。

1. [GitLabを再構成](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)して、設定の変更を適用します。

### パッケージ化されていないPostgreSQLデータベースのバックアップと復元 {#backup-and-restore-a-non-packaged-postgresql-database}

[バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)コマンドと[復元](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)コマンドを使用すると、GitLabはパッケージ化された`pg_dump`コマンドを使用してデータベースバックアップファイルを作成し、パッケージ化された`psql`コマンドを使用してバックアップを復元しようとします。これは、それらが正しいバージョンである場合にのみ機能します。パッケージ化された`pg_dump`と`psql`のバージョンを確認します:

```shell
/opt/gitlab/embedded/bin/pg_dump --version
/opt/gitlab/embedded/bin/psql --version
```

これらのバージョンがパッケージ化されていない外部PostgreSQLと異なる場合は、[バックアップコマンド](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)を実行しようとすると、次のエラー出力が発生する可能性があります。

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 12.6
pg_dump: error: aborting because of server version mismatch
```

この例では、エラーはGitLab 14.1で、[default shipped PostgreSQL version](https://docs.gitlab.com/administration/package_information/postgresql_versions/)の12.6ではなくPostgreSQLバージョン13.3を使用している場合に発生します。

この場合、データベースバージョンに一致するツールをインストールし、以下の手順に従う必要があります。PostgreSQLクライアントツールをインストールする方法は複数あります。オプションについては、<https://www.postgresql.org/download/>を参照してください。

正しい`psql`および`pg_dump`ツールがシステムで使用可能になったら、これらの手順に従い、新しいツールをインストールした場所への正しいパスを使用します:

1. パッケージ化されていないバージョンへのシンボリックリンクを追加します:

   ```shell
   ln -s /path/to/new/pg_dump /path/to/new/psql /opt/gitlab/bin/
   ```

1. バージョンを確認します:

   ```shell
   /opt/gitlab/bin/pg_dump --version
   /opt/gitlab/bin/psql --version
   ```

   これらは、パッケージ化されていない外部PostgreSQLと同じである必要があります。

この操作が完了したら、[バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)コマンドと[復元](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)コマンドの両方を実行して、バックアップと復元のタスクが正しい実行可能ファイルを使用していることを確認します。

### パッケージ化されていないPostgreSQLデータベースのアップグレード {#upgrade-a-non-packaged-postgresql-database}

データベース（Puma、Sidekiq）に接続されているすべてのプロセスを停止した後、外部データベースをアップグレードできます:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
```

アップグレードに進む前に、以下に注意してください:

- GitLabのリリースとPostgreSQLバージョンの間の互換性を確認してください:
  - [最小PostgreSQLバージョン](https://docs.gitlab.com/install/requirements/#postgresql)の要件を導入したGitLabバージョンについて読んでください。
  - [Linuxパッケージに同梱](https://docs.gitlab.com/administration/package_information/postgresql_versions/)されているPostgreSQLバージョンの重要な変更について読んでください: Linuxパッケージは、同梱されているPostgreSQLの主要なリリースとの互換性についてテストされています。
- GitLabのバックアップまたは復元を使用する場合は、同じバージョンのGitLabを維持する必要があります。それ以降のGitLabバージョンにもアップグレードする場合は、最初にPostgreSQLをアップグレードしてください。
- [バックアップコマンドと復元コマンド](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-command)を使用して、データベースをバックアップおよび復元して、それ以降のバージョンのPostgreSQLに復元できます。
- `postgresql['version']`で指定されたPostgreSQLバージョンがそのLinuxパッケージのリリースに同梱されていない場合、どのクライアントバイナリ（PostgreSQLのバックアップ/復元のバイナリなど）がアクティブであるかを判断する決め手になるのは、[互換性テーブル内のデフォルトのバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)です。

次の例は、PostgreSQL 14を実行しているデータベースホストからPostgreSQL 16を実行している別のデータベースホストにアップグレードし、ダウンタイムが発生することを示しています:

1. [データベース要件](https://docs.gitlab.com/install/requirements/#postgresql)に従ってセットアップされた、新しいPostgreSQL 16データベースサーバーをスピンアップします。

1. GitLab Railsインスタンスで、互換性のある`pg_dump`および`pg_restore`のバージョンが使用されていることを確認します。GitLabの設定を修正するには、`/etc/gitlab/gitlab.rb`を編集し、`postgresql['version']`の値を指定します:

   ```ruby
   postgresql['version'] = 16
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLabを停止します（この手順によりダウンタイムが発生することに注意してください）:

   ```shell
   sudo gitlab-ctl stop
   ```

{{< alert type="warning" >}}

バックアップコマンドでは、インストールでPgBouncerを使用している場合、[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

{{< /alert >}}

1. バックアップRakeタスクをSKIPオプションを使用して実行し、データベースのみをバックアップします。バックアップファイル名をメモしておきます。後で復元するために使用します。

   ```shell
   sudo gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,pages,registry
   ```

1. PostgreSQL 14データベースホストをシャットダウンします。

1. `/etc/gitlab/gitlab.rb`を編集し、PostgreSQLデータベース16ホストを指すように`gitlab_rails['db_host']`設定を更新します。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< alert type="warning" >}}

   バックアップコマンドでは、インストールでPgBouncerを使用している場合、[追加のパラメータ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

   {{< /alert >}}

1. 以前に作成したデータベースバックアップファイルを使用してデータベースを復元し、「このタスクで`authorized_keys`ファイルが再構築されます」と尋ねられたら、必ず**0**と答えてください:

   ```shell
   # Use the backup timestamp https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#backup-timestamp
   sudo gitlab-backup restore BACKUP=<backup-timestamp>
   ```

1. GitLabを起動します:

   ```shell
   sudo gitlab-ctl start
   ```

1. PostgreSQLを新しいメジャーリリースにアップグレードした後、テーブル統計を再作成して、効率的なクエリプランが選択されるようにし、データベースサーバーのCPU負荷を軽減します。

   アップグレードが`pg_upgrade`を使用して「インプレース」で行われた場合は、PostgreSQLデータベースコンソールで次のクエリを実行します:

   ```SQL
   SET statement_timeout = 0; ANALYZE VERBOSE;
   ```

   `ANALYZE`コマンドの実行時間は、データベースのサイズによって大きく異なる場合があります。この操作の進行状況を監視するには、別のPostgreSQLデータベースコンソールで次のクエリを定期的に実行します。`tables_remaining`列は徐々に`0`に達するはずです:

   ```SQL
   SELECT
     COUNT(*) AS total_tables,
     SUM(CASE WHEN last_analyze IS NULL OR last_analyze < (NOW() - INTERVAL '2 hours') THEN 1 ELSE 0 END) AS tables_remaining
   FROM pg_stat_user_tables;
   ```

   アップグレードで`pg_dump`と`pg_restore`が使用された場合は、PostgreSQLデータベースコンソールで次のクエリを実行します:

   ```SQL
   SET statement_timeout = 0; VACUUM VERBOSE ANALYZE;
   ```

### データベースのシード（新規インストールのみ） {#seed-the-database-fresh-installs-only}

{{< alert type="warning" >}}

これは破壊的なコマンドです。既存のデータベースでは実行しないでください。

{{< /alert >}}

Linuxパッケージのインストールでは、外部データベースはシードされません。スキーマをインポートし、最初の管理者エリアユーザーを作成するには、次のコマンドを実行します:

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

### パッケージ化されたPostgreSQLバージョンを固定する（新規インストールのみ） {#pin-the-packaged-postgresql-version-fresh-installs-only}

Linuxパッケージには[異なるPostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)が同梱されており、特に指定がない限り、デフォルトのバージョンが初期化されます。

デフォルト以外のバージョンでPostgreSQLを初期化するには、最初の再設定の前に、`postgresql['version']`を[パッケージ化されたPostgreSQLバージョン](https://docs.gitlab.com/administration/package_information/postgresql_versions/)のメジャーバージョンの1つに設定します。たとえば、GitLab 17.10では、`postgresql['version'] = 14`を使用して、デフォルトのPostgreSQL 16ではなく、PostgreSQL 14を使用できます。

{{< alert type="warning" >}}

最初の再設定後にLinuxパッケージにパッケージ化されたPostgreSQLを使用しているときに`postgresql['version']`を設定すると、PostgreSQLの異なるバージョンでデータディレクトリが初期化されているというエラーがスローされます。これが発生した場合は、[パッケージ化されたPostgreSQLサーバーを前のバージョンに戻す](#revert-packaged-postgresql-server-to-the-previous-version)を参照してください。

{{< /alert >}}

以前にGitLabがインストールされていた環境に新規インストールを行っていて、固定されたPostgreSQLバージョンを使用している場合は、まずPostgreSQLに関連するフォルダーがすべて削除されていること、およびインスタンスでPostgreSQLプロセスが実行されていないことを確認してください。

## プレーンテキストストレージなしで機密データ設定をGitLab Railsに提供する {#provide-sensitive-data-configuration-to-gitlab-rails-without-plain-text-storage}

詳細については、[設定ドキュメント](configuration.md#provide-the-postgresql-user-password-to-gitlab-rails)の例を参照してください。

## データベースのアプリケーション設定 {#application-settings-for-the-database}

### 自動データベース移行の無効化 {#disabling-automatic-database-migration}

データベースを共有する複数のGitLabサーバーがある場合は、再設定中に移行ステップを実行するノードの数を制限する必要があります。

`/etc/gitlab/gitlab.rb`を編集して追加します:

```ruby
# Enable or disable automatic database migrations
# on all hosts except the designated deploy node
gitlab_rails['auto_migrate'] = false
```

`/etc/gitlab/gitlab.rb`にはプレーンテキストのパスワードが含まれているため、ファイル権限`0600`が必要です。

上記の設定を保持しているホストを次に再設定すると、移行ステップは実行されません。

スキーマ関連のアップグレード後のエラーを回避するには、[デプロイノード](https://docs.gitlab.com/update/zero_downtime/)としてマークされたホストは、アップグレード中に`gitlab_rails['auto_migrate'] = true`を指定する必要があります。

### クライアント`statement_timeout`の設定 {#setting-client-statement_timeout}

Railsがタイムアウトする前にデータベーストランザクションが完了するのを待機する時間を、`gitlab_rails['db_statement_timeout']`設定で調整できるようになりました。デフォルトでは、この設定は使用されません。

`/etc/gitlab/gitlab.rb`を編集します:

```ruby
gitlab_rails['db_statement_timeout'] = 45000
```

この場合、クライアントの`statement_timeout`は45秒に設定されます。値はミリ秒で指定します。

### 接続タイムアウトの設定 {#setting-connection-timeout}

Railsがタイムアウトする前にPostgreSQL接続試行が成功するのを待機する時間を、`gitlab_rails['db_connect_timeout']`設定で調整できます。デフォルトでは、この設定は使用されません:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['db_connect_timeout'] = 5
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

この場合、クライアントの`connect_timeout`は5秒に設定されます。値は秒単位で指定されます。最小値2秒が適用されます。これを`<= 0`に設定するか、設定をまったく指定しないと、タイムアウトが無効になります。

### TCP制御の設定 {#setting-tcp-controls}

Rails PostgreSQLアダプターは、パフォーマンスを向上させるために調整できる一連のTCP接続制御を提供します。各パラメータの詳細については、[PostgreSQLのアップストリームドキュメント](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-KEEPALIVES)を参照してください。

Linuxパッケージは、これらの値にデフォルトを設定せず、代わりにPostgreSQLアダプターによって提供されるデフォルトを使用します。以下の表に記載されているパラメータを使用して`gitlab.rb`内でオーバーライドし、`gitlab-ctl reconfigure`を実行します。

| PostgreSQLのパラメータ  | `gitlab.rb`のパラメータ |
|-----------------------|-----------------------|
| `keepalives`          | `gitlab_rails['db_keepalives']` |
| `keepalives_idle`     | `gitlab_rails['db_keepalives_idle']` |
| `keepalives_interval` | `gitlab_rails['db_keepalives_interval']` |
| `keepalives_count`    | `gitlab_rails['db_keepalives_count']` |
| `tcp_user_timeout`    | `gitlab_rails['db_tcp_user_timeout']` |

## データベースの自動インデックス再作成 {#automatic-database-reindexing}

{{< alert type="warning" >}}

これは実験的な機能であり、デフォルトでは有効になっていません。

{{< /alert >}}

バックグラウンドでデータベースのインデックスを再作成します（「インデックス再作成」と呼ばれます）。これは、インデックスに蓄積された肥大化したスペースを削除し、健全で効率的なインデックスを維持するのに役立ちます。

インデックス再作成タスクは、cronjobを介して定期的に開始できます。cronジョブを設定するには、`gitlab_rails['database_reindexing']['enable']`を`true`に設定する必要があります。

マルチノード環境では、この機能フラグはアプリケーションホストでのみ有効にする必要があります。インデックス再作成プロセスはPgBouncerを通過できず、直接データベース接続が必要です。

デフォルトでは、週末（トラフィックが少ない可能性が高い時間帯）のみ、毎時cronジョブを開始します。

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

## パッケージ化されたPostgreSQLがHA/Geoクラスターにデプロイされました {#packaged-postgresql-deployed-in-an-hageo-cluster}

### GitLab HAクラスターのアップグレード {#upgrading-a-gitlab-ha-cluster}

PatroniクラスターのPostgreSQLのメジャーバージョンをアップグレードするには、[PatroniクラスターでのPostgreSQLメジャーバージョンのアップグレード](https://docs.gitlab.com/administration/postgresql/replication_and_failover/#upgrading-postgresql-major-version-in-a-patroni-cluster)を参照してください。

### HAクラスターでのアップグレードのトラブルシューティング {#troubleshooting-upgrades-in-an-ha-cluster}

HA設定にアップグレードする前に、バンドルされたPostgreSQLがノードで実行されていた場合、古いデータディレクトリが残っている可能性があります。これにより、`gitlab-ctl reconfigure`がそのノードで使用するPostgreSQLユーティリティのバージョンをダウングレードする可能性があります。これを防ぐために、ディレクトリを移動（または削除）します:

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

`gitlab-ctl repmgr standby setup MASTER_NODE_NAME`でセカンダリノードを再作成するときに次のエラーが発生した場合は、`postgresql['max_replication_slots'] = X`（`X`はDBノードの数+ 1）が`/etc/gitlab/gitlab.rb`に含まれていることを確認してください:

```shell
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geoインスタンスのアップグレード {#upgrading-a-geo-instance}

GeoはデフォルトでPostgreSQLストリーミングレプリケーションに依存するため、GitLabをアップグレードするとき、またはPostgreSQLをアップグレードするときは、以下に示すように追加の考慮事項があります。

#### Geoを使用したPostgreSQLのアップグレード時の注意点 {#caveats-when-upgrading-postgresql-with-geo}

{{< alert type="warning" >}}

Geoを使用する場合、PostgreSQLをアップグレードするには、PostgreSQLレプリケーションをGeoの**secondaries**に再初期化する必要があるため、すべてのセカンダリでダウンタイムが発生します。これは、PostgreSQLストリーミングレプリケーションの仕組みによるものです。レプリケーションを再初期化すると、プライマリデータベースからすべてのデータが再度コピーされるため、データベースのサイズと使用可能な帯域幅に応じて、時間がかかる場合があります。たとえば、転送速度が30 Mbpsで、データベースサイズが100 GBの場合、再同期には約8時間かかる可能性があります。詳細については、[PostgreSQLドキュメント](https://www.postgresql.org/docs/11/pgupgrade.html)を参照してください。

{{< /alert >}}

#### Geoを使用する場合のPostgreSQLのアップグレード方法 {#how-to-upgrade-postgresql-when-using-geo}

PostgreSQLをアップグレードするには、レプリケーションスロットの名前と、レプリケーションユーザーのパスワードが必要です。

1. Geoプライマリデータベースのノードで既存のレプリケーションスロットの名前を検索するには、次を実行します:

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

   ここに`slot_name`が見つからない場合、または出力が返されない場合、Geoのセカンダリが正常でない可能性があります。その場合は、[セカンダリが正常で、レプリケーションが機能している](https://docs.gitlab.com/administration/geo/replication/troubleshooting/common/#health-check-rake-task)ことを確認してください。

   クエリが空の場合でも、[Geoサイトの管理者エリア](https://docs.gitlab.com/administration/geo_sites/)にある`slot_name`を使用して、セカンダリデータベースを再初期化できます。

1. レプリケーションユーザーのパスワードを収集します。これは、[ステップ1でGeoを設定するときに設定されました。プライマリサイトを設定](https://docs.gitlab.com/administration/geo/setup/database/#step-1-configure-the-primary-site)。

1. オプション。[各**セカンダリ**サイトでのレプリケーションの一時停止](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)ディザスターリカバリー (DR) 機能を保護します。

1. GeoプライマリデータベースでPostgreSQLを手動でアップグレードします。Geoプライマリデータベースのデータベースノードで実行します:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   **primary database**がアップグレードを完了するのを待ってから、次の手順を開始してください。セカンダリはバックアップとして準備完了の状態を維持できます。その後、**tracking database**を**secondary database**と並行してアップグレードできます。

1. GeoセカンダリでPostgreSQLを手動でアップグレードします。Geo **secondary database**と**tracking database**で実行します:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. コマンドを使用して、Geo **secondary database**でデータベースレプリケーションを再開します:

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME --sslmode=verify-ca
   ```

   プライマリデータベースのレプリケーションユーザーのパスワードを求めるプロンプトが表示されます。上記の最初の手順で取得したスロット名で`SECONDARY_SLOT_NAME`を置き換えます。

   この操作のデフォルトのタイムアウトは30分です。タイムアウトを長くする必要がある場合は、`--backup-timeout`オプションを設定します。たとえば、`--backup-timeout=21600`は、最初のレプリケーションを完了するまでに6時間かかります。

1. `pg_hba.conf`ファイルをアップグレードするには、Geo **secondary database**で[GitLabを再設定](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation)します。これは、`replicate-geo-database`がプライマリデータベースのファイルをセカンダリにレプリケートするため必要です。

1. 手順3でレプリケーションを一時停止した場合は、[各**セカンダリ**でレプリケーションを再開](https://docs.gitlab.com/administration/geo/#pausing-and-resuming-replication)してください。

1. `puma`、`sidekiq`、および`geo-logcursor`を再起動します。

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. `https://your_primary_server/admin/geo/sites`に移動し、すべてのGeoサイトが正常であることを確認します。

## PostgreSQLデータベースへの接続 {#connecting-to-the-postgresql-database}

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

データベースの`default_transaction_isolation`設定がGitLabアプリケーションの要件に準拠していない可能性があります。PostgreSQLデータベースに接続し、`SHOW default_transaction_isolation;`を実行して、この設定を確認できます。GitLabアプリケーションは`read committed`が設定されていることを想定しています。

この`default_transaction_isolation`設定は、`postgresql.conf`ファイルで設定されています。設定を変更した後は、データベースを再起動/再読み込むする必要があります。この設定は、Linuxパッケージに含まれているパッケージ化されたPostgreSQLサーバーにデフォルトで付属しています。

### ライブラリ`plpgsql.so`を読み込むことができません {#could-not-load-library-plpgsqlso}

データベースの移行を実行中、またはPostgreSQL/Patroniのログに、次のようなエラーが表示される場合があります:

```plaintext
ERROR:  could not load library "/opt/gitlab/embedded/postgresql/12/lib/plpgsql.so": /opt/gitlab/embedded/postgresql/12/lib/plpgsql.so: undefined symbol: EnsurePortalSnapshotExists
```

このエラーは、基盤となるバージョンが変更された後、PostgreSQLを再起動しなかったために発生します。このエラーを修正するには:

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

### データベースCPU負荷が非常に高い {#database-cpu-load-very-high}

データベースのCPU負荷が非常に高い場合、[自動キャンセル冗長パイプライン設定](https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines)が原因である可能性があります。詳細については、[issue 435250](https://gitlab.com/gitlab-org/gitlab/-/issues/435250)を参照してください。

この問題を解決するには:

- データベースサーバーにより多くのCPUリソースを割り当てることができます。
- Sidekiqがオーバーロードしている場合は、プロジェクトに非常に多数のパイプラインがある場合、`ci_cancel_redundant_pipelines`キューに[より多くのSidekiqプロセスを追加](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#start-multiple-processes)する必要があるかもしれません。
- `disable_cancel_redundant_pipelines_service`機能フラグを有効にして、この設定をインスタンス全体で無効にし、CPU負荷が低下するかどうかを確認できます。これにより、すべてのプロジェクトの機能フラグが無効になり、自動的にキャンセルされなくなったパイプラインによるリソースの使用量が増加する可能性があります。

### エラー: `TypeError: can't quote Array` {#error-typeerror-cant-quote-array}

Amazon RDSを使用している場合、`gitlab::database_migrations`タスクの実行中に、`TypeError: can't quote Array`というエラーが表示されることがあります。

この[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/356307)を回避するには、PostgreSQLデータベースのRDSで[`quote_all_identifiers`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html)パラメータを無効にします。
