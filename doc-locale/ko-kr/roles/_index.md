---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 고가용성 역할
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Linux 패키지에는 GitLab을 고가용성 구성으로 실행하기 위해 다양한 소프트웨어 구성요소/서비스가 포함되어 있습니다. 기본적으로 이러한 지원 서비스 중 일부는 비활성화되며, GitLab은 단일 노드 설치로 실행되도록 구성됩니다. 각 서비스는 `/etc/gitlab/gitlab.rb`의 구성 설정을 사용하여 활성화하거나 비활성화할 수 있지만, `roles`의 도입으로 서비스 그룹을 쉽게 활성화할 수 있으며, 활성화한 고가용성 역할을 기반으로 더 나은 기본 구성을 제공합니다.

## 역할을 지정하지 않음(기본 구성) {#not-specifying-any-roles-the-default-configuration}

GitLab을 어떤 역할로 구성하지 않으면 GitLab은 단일 노드 설치를 위한 기본 서비스를 활성화합니다. 여기에는 PostgreSQL, Redis, Puma, Sidekiq, Gitaly, GitLab Workhorse, NGINX 등과 같은 항목이 포함됩니다.

이러한 항목들은 여전히 `/etc/gitlab/gitlab.rb`의 설정으로 개별적으로 활성화/비활성화할 수 있습니다.

## 역할 지정 {#specifying-roles}

역할은 `/etc/gitlab/gitlab.rb`에서 배열로 전달됩니다.

여러 역할을 지정하는 예:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
```

단일 역할을 지정하는 예:

```ruby
roles ['geo_primary_role']
```

## 역할 {#roles}

다음 역할의 대부분은 [GitLab Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)에서만 작동하며, `gitlab-ee` Linux 패키지를 의미합니다. 각 역할 옆에 표시됩니다.

### GitLab App 역할 {#gitlab-app-role}

- `application_role` (`gitlab-ce`/`gitlab-ee`)

  GitLab App 역할은 GitLab만 실행되는 인스턴스를 구성하는 데 사용됩니다. Redis, PostgreSQL 및 Consul 서비스는 기본적으로 비활성화됩니다.

### Redis 서버 역할 {#redis-server-roles}

Redis 역할 사용에 대한 설명서는 [Redis를 위한 확장 구성](https://docs.gitlab.com/administration/redis/)에서 찾을 수 있습니다.

- `redis_sentinel_role` (`gitlab-ee`)

  머신에서 sentinel 서비스를 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

- `redis_master_role` (`gitlab-ee`)

  Redis 서비스와 모니터링을 활성화하고 마스터 암호 구성을 허용합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

- `redis_replica_role` (`gitlab-ee`)

  Redis 서비스와 모니터링을 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

### GitLab Geo 역할 {#gitlab-geo-roles}

GitLab Geo 역할은 GitLab Geo 사이트의 구성에 사용됩니다. 구성 단계는 [Geo 설정 설명서](https://docs.gitlab.com/administration/geo/setup/)를 참조하세요.

- `geo_primary_role` (`gitlab-ee`)

  이 역할:

  - 단일 노드 PostgreSQL 데이터베이스를 스트리밍 복제의 리더로 구성합니다.
  - Geo 보조 사이트로의 스트리밍 복제 중단 시간이 필요하므로 PostgreSQL의 자동 업그레이드를 방지합니다.
  - NGINX, Puma, Redis 및 Sidekiq를 포함한 모든 단일 노드 GitLab 서비스를 활성화합니다. 서비스를 분리하는 경우 `/etc/gitlab/gitlab.rb`에서 원하지 않는 서비스를 명시적으로 비활성화해야 합니다. 따라서 이 역할은 Geo 주 사이트의 단일 노드 PostgreSQL에서만 유용합니다.
  - Geo 주 사이트에서 PostgreSQL 클러스터를 설정하는 데 사용할 수 없습니다. 대신 [Geo 다중 노드 데이터베이스 복제](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)를 참조하세요.

  기본적으로 NGINX, Puma, Redis 및 Sidekiq를 포함한 표준 단일 노드 GitLab 서비스를 활성화합니다.

- `geo_secondary_role` (`gitlab-ee`)

  - 들어오는 복제를 위한 보조 읽기 전용 복제본 데이터베이스를 구성합니다.
  - Geo 추적 데이터베이스에 대한 Rails 연결을 구성합니다.
  - Geo 추적 데이터베이스 `geo-postgresql`를 활성화합니다.
  - Geo Log Cursor `geo-logcursor`를 활성화합니다.
  - 재구성 중에 읽기 전용 복제본 데이터베이스에서 자동 데이터베이스 마이그레이션을 비활성화합니다.
  - 다른 서비스를 위해 메모리를 절약하기 위해 Puma 작업자 수를 줄입니다.
  - `gitlab_rails['enable'] = true`을 설정합니다.

  이 역할은 단일 노드에서 실행되는 Geo 보조 사이트에서 사용하기 위한 것입니다. 여러 노드가 있는 Geo 사이트에서 이 역할을 사용하는 경우 `/etc/gitlab/gitlab.rb`에서 원하지 않는 서비스를 명시적으로 비활성화해야 합니다. [여러 노드를 위한 Geo](https://docs.gitlab.com/administration/geo/replication/multiple_servers/)를 참조하세요.

  이 역할은 Geo 보조 사이트에서 PostgreSQL 클러스터를 설정하는 데 사용하면 안 됩니다. 대신 [Geo 다중 노드 데이터베이스 복제](https://docs.gitlab.com/administration/geo/setup/database/#multi-node-database-replication)를 참조하세요.

  기본적으로 NGINX, Puma, Redis 및 Sidekiq를 포함한 모든 GitLab 기본 단일 노드 서비스를 활성화합니다.

### 모니터링 역할 {#monitoring-roles}

모니터링 역할은 설치 모니터링을 설정하는 데 사용됩니다. 추가 정보는 [모니터링 설명서](https://docs.gitlab.com/administration/monitoring/prometheus/)를 참조하세요.

- `monitoring_role` (`gitlab-ce`/`gitlab-ee`)

  메트릭을 수집하고 대시보드를 제공하는 중앙 모니터링 서버를 구성합니다.

  Prometheus 및 Alertmanager를 활성화합니다.

### PostgreSQL 역할 {#postgresql-roles}

PostgreSQL 역할의 사용에 대한 설명서는 [확장을 위한 PostgreSQL 구성](https://docs.gitlab.com/administration/postgresql/)에서 찾을 수 있습니다.

- `postgres_role` (`gitlab-ce`/`gitlab-ee`)

  머신에서 PostgreSQL 서비스를 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

- `patroni_role` (`gitlab-ee`)

  머신에서 PostgreSQL, Patroni 및 Consul 서비스를 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

- `pgbouncer_role` (`gitlab-ee`)

  머신에서 PgBouncer 및 Consul 서비스를 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

- `consul_role` (`gitlab-ee`)

  머신에서 Consul 서비스를 활성화합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

### GitLab Pages 역할 {#gitlab-pages-roles}

GitLab Pages 역할은 GitLab Pages를 설정하고 구성하는 데 사용됩니다. 추가 정보는 [GitLab Pages 관리 설명서](https://docs.gitlab.com/administration/pages/)를 참조하세요.

- `pages_role` (`gitlab-ce`/`gitlab-ee`)

  GitLab Pages 인스턴스를 사용하여 서버를 구성합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

### Sidekiq 역할 {#sidekiq-roles}

Sidekiq 역할은 Sidekiq를 설정하고 구성하는 데 사용됩니다. 추가 정보는 [Sidekiq 관리 설명서](https://docs.gitlab.com/administration/sidekiq/)를 참조하세요.

- `sidekiq_role` (`gitlab-ce`/`gitlab-ee`)

  Sidekiq 서비스를 사용하여 서버를 구성합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*

### Gitaly 역할 {#gitaly-roles}

Gitaly 역할은 Gitaly 서비스를 설정하고 구성하는 데 사용됩니다. 추가 정보는 [Gitaly 설명서](https://docs.gitlab.com/administration/gitaly/)를 참조하세요.

- `gitaly_role` (`gitlab-ce`/`gitlab-ee`)

  Gitaly 서비스를 사용하여 서버를 구성합니다.

  *기본적으로 다른 서비스는 활성화되지 않습니다.*
