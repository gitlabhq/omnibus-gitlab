---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 高可用性ロール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージには、GitLabを高可用性の設定で実行をサポートするためのさまざまなソフトウェアコンポーネント/サービスが含まれています。デフォルトでは、これらのサポートサービスの一部は無効になっており、GitLabは単一ノードインストールとして実行するように設定されています。各サービスは`/etc/gitlab/gitlab.rb`の設定を使用して有効または無効にできますが、`roles`の導入により、サービスのグループを簡単に有効にできるようになり、有効にした高可用性ロールに基づいて、より優れたデフォルトの設定が提供されます。

## ロールを指定しない(デフォルト設定) {#not-specifying-any-roles-the-default-configuration}

GitLabをロールで設定しない場合、GitLabは単一ノードインストール用のデフォルトサービスを有効にします。これらには、PostgreSQL、Redis、Puma、Sidekiq、Gitaly、GitLab Workhorse、NGINXなどが含まれます。

これらは、`/etc/gitlab/gitlab.rb`内の設定によって個別に有効/無効にすることができます。

## ロールの指定 {#specifying-roles}

ロールは`/etc/gitlab/gitlab.rb`に配列として渡されます

複数のロールを指定する例:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
```

単一のロールを指定する例:

```ruby
roles ['geo_primary_role']
```

## ロール {#roles}

以下のほとんどのロールはGitLab EEでのみ動作します。これは、`gitlab-ee` Linuxパッケージを意味します。各ロールの横に記載されます。

### GitLab Appロール {#gitlab-app-role}

- `application_role` (`gitlab-ce`/`gitlab-ee`)

  GitLabアプリロールは、GitLabのみが実行されているインスタンスを設定するために使用されます。Redis、PostgreSQL、およびConsulサービスはデフォルトで無効になっています。

### Redisサーバーロール {#redis-server-roles}

Redisロールの使用に関するドキュメントは、[Configuring Redis for Scaling](https://docs.gitlab.com/administration/redis/)にあります。

- `redis_sentinel_role` (`gitlab-ee`)

  マシン上のセンチネルサービスを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

- `redis_master_role` (`gitlab-ee`)

  Redisサービスとモニタリングを有効にし、masterパスワードの設定を許可します。

  *デフォルトでは、他のサービスを有効にしません。*

- `redis_replica_role` (`gitlab-ee`)

  Redisサービスとモニタリングを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

### Geoロール {#gitlab-geo-roles}

Geoロールは、Geoサイトの設定に使用されます。設定手順については、[Geo Setup Documentation](https://docs.gitlab.com/administration/geo/setup/)を参照してください。

- `geo_primary_role` (`gitlab-ee`)

  このロールは次のとおりです:

  - 単一ノードのPostgreSQLデータベースをストリーミングレプリケーションのリーダーとして設定します。
  - PostgreSQLの自動アップグレードを防ぎます。これは、Geoサイトへのストリーミングレプリケーションにダウンタイムが必要となるためです。
  - NGINX、Puma、Redis、Sidekiqを含むすべての単一ノードGitLabサービスを有効にします。サービスを分離している場合は、`/etc/gitlab/gitlab.rb`で不要なサービスを明示的に無効にする必要があります。したがって、このロールはGeoサイト内の単一ノードPostgreSQLでのみ役立ちます。
  - Geoサイト内のPostgreSQLクラスターを設定するために使用することはできません。代わりに、[Geoマルチノードデータベースレプリケーション](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)を参照してください。

  デフォルトでは、NGINX、Puma、Redis、Sidekiqを含む標準の単一ノードGitLabサービスを有効にします。

- `geo_secondary_role` (`gitlab-ee`)

  - 受信レプリケーション用のセカンダリ読み取り専用レプリカデータベースを設定します。
  - Geo追跡データベースへのRails接続を設定します。
  - Geo追跡データベース`geo-postgresql`を有効にします。
  - Geoログカーソル`geo-logcursor`を有効にします。
  - 再設定中に読み取り専用レプリカデータベースでの自動データベース移行を無効にします。
  - 他のサービスのためにメモリを節約するために、Pumaワーカーの数を減らします。
  - `gitlab_rails['enable'] = true`を設定します。

  このロールは、単一ノードで実行されているGeoセカンダリGeoサイトで使用することを目的としています。マルチノードを持つGeoサイトでこのロールを使用する場合、不要なサービスは`/etc/gitlab/gitlab.rb`で明示的に無効にする必要があります。[複数ノードのGeo](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)を参照してください。

  このロールは、Geoサイト内のPostgreSQLクラスターを設定するために使用すべきではありません。代わりに、[Geoマルチノードデータベースレプリケーション](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)を参照してください。

  デフォルトでは、NGINX、Puma、Redis、Sidekiqを含むすべてのGitLabデフォルト単一ノードサービスを有効にします。

### モニタリングロール {#monitoring-roles}

モニタリングロールは、インストールのモニタリングを設定するために使用されます。詳細については、[モニタリングドキュメント](https://docs.gitlab.com/administration/monitoring/prometheus/)を参照してください。

- `monitoring_role` (`gitlab-ce`/`gitlab-ee`)

  メトリクスを収集し、ダッシュボードを提供する中央モニタリングサーバーを設定します。

  PrometheusとAlertmanagerを有効にします。

### PostgreSQLロール {#postgresql-roles}

PostgreSQLロールの使用に関するドキュメントは、[Configuring PostgreSQL for Scaling](https://docs.gitlab.com/administration/postgresql/)にあります。

- `postgres_role` (`gitlab-ce`/`gitlab-ee`)

  マシン上でPostgreSQLサービスを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

- `patroni_role` (`gitlab-ee`)

  マシン上でPostgreSQL、Patroni、およびConsulサービスを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

- `pgbouncer_role` (`gitlab-ee`)

  マシン上でPgBouncerおよびConsulサービスを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

- `consul_role` (`gitlab-ee`)

  マシン上でConsulサービスを有効にします。

  *デフォルトでは、他のサービスを有効にしません。*

### GitLab Pagesロール {#gitlab-pages-roles}

GitLab Pagesロールは、GitLab Pagesを設定するために使用されます。詳細については、[GitLab Pages管理ドキュメント](https://docs.gitlab.com/administration/pages/)を参照してください。

- `pages_role` (`gitlab-ce`/`gitlab-ee`)

  サーバーにGitLab Pagesインスタンスを設定します。

  *デフォルトでは、他のサービスを有効にしません。*

### Sidekiqロール {#sidekiq-roles}

Sidekiqロールは、Sidekiqを設定するために使用されます。詳細については、[Sidekiq管理ドキュメント](https://docs.gitlab.com/administration/sidekiq/)を参照してください。

- `sidekiq_role` (`gitlab-ce`/`gitlab-ee`)

  サーバーにSidekiqサービスを設定します。

  *デフォルトでは、他のサービスを有効にしません。*

### Gitalyロール {#gitaly-roles}

Gitalyロールは、Gitalyサービスを設定するために使用されます。詳細については、[Gitalyドキュメント](https://docs.gitlab.com/administration/gitaly/)を参照してください。

- `gitaly_role` (`gitlab-ce`/`gitlab-ee`)

  サーバーにGitalyサービスを設定します。

  *デフォルトでは、他のサービスを有効にしません。*
