---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 高可用性ロール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージには、高可用性構成でGitLabを実行するためのさまざまなソフトウェアコンポーネント/サービスが含まれています。デフォルトでは、これらのサポートサービスの一部は無効になっており、GitLabは単一ノードインストールとして実行するように構成されています。各サービスは、`/etc/gitlab/gitlab.rb`の設定を使用して有効または無効にできますが、`roles`を導入することで、サービスのグループを簡単に有効にでき、有効にした高可用性ロールに基づいて、より適切なデフォルトの設定が提供されます。

## ロールを指定しない場合（デフォルトの設定） {#not-specifying-any-roles-the-default-configuration}

ロールを設定せずにGitLabを設定すると、GitLabは単一ノードインストールのデフォルトサービスを有効にします。これには、PostgreSQL、Redis、Puma、Sidekiq、Gitaly、GitLab Workhorse、NGINXなどが含まれます。

これらは、`/etc/gitlab/gitlab.rb`の設定で個別に有効/無効にすることもできます。

## ロールの指定 {#specifying-roles}

ロールは`/etc/gitlab/gitlab.rb`の配列として渡されます

複数のロールを指定する例:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
```

単一のロールを指定する例:

```ruby
roles ['geo_primary_role']
```

## ロール {#roles}

以下のロールの大部分は、[GitLab Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)、つまり`gitlab-ee` Linuxパッケージでのみ機能します。各ロールの横に記載されています。

### GitLabアプリのロール {#gitlab-app-role}

- `application_role`（`gitlab-ce`/`gitlab-ee`）

  GitLabアプリのロールは、GitLabのみが実行されているインスタンスを設定するために使用されます。Redis、PostgreSQL、およびConsulサービスは、デフォルトで無効になっています。

### Redisサーバーのロール {#redis-server-roles}

Redisロールの使用に関するドキュメントは、[Configuring Redis for Scaling](https://docs.gitlab.com/administration/redis/)にあります

- `redis_sentinel_role`（`gitlab-ee`）

  マシン上でセンチネルサービスを有効にします。

  *デフォルトでは、他のサービスは有効になりません。*

- `redis_master_role`（`gitlab-ee`）

  Redisサービスとモニタリングを有効にし、マスターパスワードの設定を許可します

  *デフォルトでは、他のサービスは有効になりません。*

- `redis_replica_role`（`gitlab-ee`）

  Redisサービスとモニタリングを有効にします

  *デフォルトでは、他のサービスは有効になりません。*

### GitLab Geoロール {#gitlab-geo-roles}

GitLab Geoロールは、GitLab Geoサイトの設定に使用されます。設定手順については、[Geo Setup Documentation](https://docs.gitlab.com/administration/geo/setup/)を参照してください。

- `geo_primary_role`（`gitlab-ee`）

  このロール:

  - ストリーミングレプリケーションのリーダーとして、単一ノードPostgreSQLデータベースを設定します。
  - Geoセカンダリサイトへのストリーミングレプリケーションのダウンタイムが必要になるため、PostgreSQLの自動アップグレードを防止します。
  - NGINX、Puma、Redis、Sidekiqなど、すべての単一ノードGitLabサービスを有効にします。サービスを分離する場合は、`/etc/gitlab/gitlab.rb`で不要なサービスを明示的に無効にする必要があります。したがって、このロールはGeoプライマリサイトの単一ノードPostgreSQLでのみ役立ちます。
  - GeoプライマリサイトでPostgreSQLクラスタリングをセットアップするために使用することはできません。代わりに、[Geoマルチノードデータベースレプリケーション](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)を参照してください。

  *デフォルトでは、NGINX、Puma、Redis、Sidekiqなどの標準単一ノードGitLabサービスが有効になります。*

- `geo_secondary_role`（`gitlab-ee`）

  - 受信レプリケーションのために、セカンダリの読み取り専用レプリカデータベースを設定します。
  - GeoトラッキングデータベースへのRails接続を設定します。
  - Geoトラッキングデータベース`geo-postgresql`を有効にします。
  - Geoログカーソル`geo-logcursor`を有効にします。
  - 再構成中に読み取り専用レプリカデータベースでの自動データベース移行を無効にします。
  - 他のサービスのためにメモリを節約するために、Pumaワーカーの数を減らします。
  - `gitlab_rails['enable'] = true`を設定します。

  このロールは、単一ノードで実行されているGeoセカンダリサイトで使用することを目的としています。複数のノードを持つGeoサイトでこのロールを使用する場合は、不要なサービスを`/etc/gitlab/gitlab.rb`で明示的に無効にする必要があります。[複数のノード用のGeo](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)をセットアップする

  このロールは、GeoセカンダリサイトでPostgreSQLクラスタリングをセットアップするために使用しないでください。代わりに、[Geoマルチノードデータベースレプリケーション](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)を参照してください。

  *デフォルトでは、すべてのGitLabデフォルト単一ノードサービスが有効になります。（NGINX、Puma、Redis、Sidekiqなど）*

### モニタリングロール {#monitoring-roles}

モニタリングロールは、インストールのモニタリングを設定するために使用されます。詳細については、[モニタリングのドキュメント](https://docs.gitlab.com/administration/monitoring/prometheus/)を参照してください。

- `monitoring_role`（`gitlab-ce`/`gitlab-ee`）

  メトリクスを収集し、ダッシュボードを提供するための中央モニタリングサーバーを設定します。

  PrometheusとAlertmanagerを有効にします。

### PostgreSQLロール {#postgresql-roles}

PostgreSQLロールの使用方法に関するドキュメントは、[Configuring PostgreSQL for Scaling](https://docs.gitlab.com/administration/postgresql/)にあります

- `postgres_role`（`gitlab-ce`/`gitlab-ee`）

  マシン上でPostgreSQLサービスを有効にします

  *デフォルトでは、他のサービスは有効になりません。*

- `patroni_role`（`gitlab-ee`）

  マシン上でPostgreSQL、Patroni、Consulサービスを有効にします

  *デフォルトでは、他のサービスは有効になりません。*

- `pgbouncer_role`（`gitlab-ee`）

  マシン上でPgBouncerとConsulサービスを有効にします

  *デフォルトでは、他のサービスは有効になりません。*

- `consul_role`（`gitlab-ee`）

  マシン上でConsulサービスを有効にします

  *デフォルトでは、他のサービスは有効になりません。*

### GitLab Pagesロール {#gitlab-pages-roles}

GitLab Pagesロールは、GitLab Pagesを設定するために使用されます。詳細については、[GitLab Pages管理ドキュメント](https://docs.gitlab.com/administration/pages/)を参照してください

- `pages_role`（`gitlab-ce`/`gitlab-ee`）

  GitLab Pagesインスタンスを使用してサーバーを設定します。

  *デフォルトでは、他のサービスは有効になりません。*

### Sidekiqロール {#sidekiq-roles}

Sidekiqロールは、Sidekiqを設定するために使用されます。詳細については、[Sidekiq管理ドキュメント](https://docs.gitlab.com/administration/sidekiq/)を参照してください

- `sidekiq_role`（`gitlab-ce`/`gitlab-ee`）

  Sidekiqサービスを使用してサーバーを設定します。

  *デフォルトでは、他のサービスは有効になりません。*

### Spamcheckロール {#spamcheck-roles}

Spamcheckロールは、Spamcheckサービスを設定するために使用されます。詳細については、[Spamcheckドキュメント](https://docs.gitlab.com/administration/reporting/spamcheck/)を参照してください

- `spamcheck_role`（`gitlab-ee`）

  Spamcheckおよびスパム分類子サービスを使用してサーバーを設定します。

  *デフォルトでは、他のサービスは有効になりません。*

### Gitalyロール {#gitaly-roles}

Gitalyロールは、Gitalyサービスを設定するために使用されます。詳細については、[Gitalyドキュメント](https://docs.gitlab.com/administration/gitaly/)を参照してください

- `gitaly_role`（`gitlab-ce`/`gitlab-ee`）

  Gitalyサービスを使用してサーバーを設定します。

  *デフォルトでは、他のサービスは有効になりません。*
