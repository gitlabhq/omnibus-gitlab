---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Omnibus GitLab High Availability Roles

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Omnibus GitLab includes various software components/services to support running GitLab in
a high availability configuration. By default, some of these supporting services
are disabled, and Omnibus GitLab is configured to run as a single node installation.
Each service can be enabled or disabled using configuration settings in `/etc/gitlab/gitlab.rb`,
but the introduction of `roles` allows you to easily enable a group of services,
and provides better default configuration based on the high availability roles you
have enabled.

## Not specifying any Roles (the default configuration)

When you don't configure GitLab with any roles, GitLab enables the default services for
a single node install. These include things like PostgreSQL, Redis, Puma, Sidekiq,
Gitaly, GitLab Workhorse, NGINX, etc.

These can still be individually enable/disabled by the settings in your `/etc/gitlab/gitlab.rb`.

## Specifying Roles

Roles are passed as an array in `/etc/gitlab/gitlab.rb`

Example specifying multiple roles:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
```

Example specifying a single role:

```ruby
roles ['geo_primary_role']
```

## Roles

The majority of the following roles will only work on a
[GitLab Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/), meaning
a `gitlab-ee` Omnibus package. It will be mentioned next to each role.

### GitLab App Role

- **application_role** (`gitlab-ce`/`gitlab-ee`)

  The GitLab App role is used to configure an instance where only GitLab is running. Redis, PostgreSQL, and Consul services are disabled by default.

### Redis Server Roles

Documentation on the use of the Redis Roles can be found in [Configuring Redis for Scaling](https://docs.gitlab.com/ee/administration/redis/index.html)

- **redis_sentinel_role** (`gitlab-ee`)

  Enables the sentinel service on the machine,

  *By default, enables no other services.*

- **redis_master_role** (`gitlab-ee`)

  Enables the Redis service and monitoring, and allows configuring the master password

  *By default, enables no other services.*

- **redis_replica_role** (`gitlab-ee`)

  Enables the Redis service and monitoring

  *By default, enables no other services.*

### GitLab Geo Roles

The GitLab Geo roles are used for configuration of GitLab Geo sites. See the
[Geo Setup Documentation](https://docs.gitlab.com/ee/administration/geo/setup/index.html)
for configuration steps.

- **geo_primary_role** (`gitlab-ee`)

  This role:

  - Configures a single-node PostgreSQL database as a leader for streaming replication.
  - Prevents automatic upgrade of PostgreSQL since it requires downtime of streaming replication to Geo secondary sites.
  - Enables all single-node GitLab services including NGINX, Puma, Redis, and Sidekiq. If you are segregating services, then you must explicitly disable unwanted services in `/etc/gitlab/gitlab.rb`. Therefore, this role is only useful on a single-node PostgreSQL in a Geo primary site.
  - Cannot be used to set up a PostgreSQL cluster in a Geo primary site. Instead, see [Geo multi-node database replication](https://docs.gitlab.com/ee/administration/geo/setup/database.html#multi-node-database-replication).

  *By default, enables standard single-node GitLab services including NGINX, Puma, Redis, and Sidekiq.*

- **geo_secondary_role** (`gitlab-ee`)

  - Configures the secondary read-only replica database for incoming
    replication.
  - Configures the Rails connection to the Geo tracking database.
  - Enables the Geo tracking database `geo-postgresql`.
  - Enables the Geo Log Cursor `geo-logcursor`.
  - Disables automatic database migrations on the read-only replica database
    during reconfigure.
  - Reduces the number of Puma workers to save memory for other services.
  - Sets `gitlab_rails['enable'] = true`.

  This role is intended to be used in a Geo secondary site running on a single
  node. If using this role in a Geo site with multiple nodes, undesired
  services will need to be explicitly disabled in `/etc/gitlab/gitlab.rb`. See
  [Geo for multiple nodes](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html).

  This role should not be used to set up a PostgreSQL cluster in a Geo secondary
  site. Instead, see [Geo multi-node database replication](https://docs.gitlab.com/ee/administration/geo/setup/database.html#multi-node-database-replication).

  *By default, enables all of the GitLab default single node services. (NGINX, Puma, Redis, Sidekiq, etc)*

### Monitoring Roles

Monitoring roles are used to set up monitoring of installations. For additional information, see the [Monitoring documentation](https://docs.gitlab.com/ee/administration/monitoring/prometheus/index.html).

- **monitoring_role** (`gitlab-ce`/`gitlab-ee`)

  Configures a central monitoring server to collect metrics and provide dashboards.

  Enables Prometheus and Alertmanager.

### PostgreSQL Roles

Documentation on the usage of the PostgreSQL Roles can be found in [Configuring PostgreSQL for Scaling](https://docs.gitlab.com/ee/administration/postgresql/index.html)

- **postgres_role** (`gitlab-ce`/`gitlab-ee`)

  Enables the PostgreSQL service on the machine

  *By default, enables no other services.*

- **patroni_role** (`gitlab-ee`)

  Enables the PostgreSQL, patroni, and Consul services on the machine

  *By default, enables no other services.*

- **pgbouncer_role** (`gitlab-ee`)

  Enables the PgBouncer and Consul services on the machine

  *By default, enables no other services.*

- **consul_role** (`gitlab-ee`)

  Enables the Consul service on the machine

  *By default, enables no other services.*

### GitLab Pages Roles

GitLab Pages roles are used to set up and configure GitLab Pages. For additional
information, see the
[GitLab Pages Administration documentation](https://docs.gitlab.com/ee/administration/pages/index.html)

- **pages_role** (`gitlab-ce`/`gitlab-ee`)

  Configures the server with a GitLab Pages instance.

  *By default, enables no other services.*

### Sidekiq Roles

Sidekiq roles are used to set up and configure Sidekiq. For additional
information, see the
[Sidekiq Administration documentation](https://docs.gitlab.com/ee/administration/sidekiq/index.html)

- **sidekiq_role** (`gitlab-ce`/`gitlab-ee`)

  Configures the server with Sidekiq service.

  *By default, enables no other services.*

### Spamcheck Roles

Spamcheck roles are used to set up and configure Spamcheck services. For additional
information, see the
[Spamcheck documentation](https://docs.gitlab.com/ee/administration/reporting/spamcheck.html)

- **spamcheck_role** (`gitlab-ee`)

  Configures the server with spamcheck and spam-classifier services.

  *By default, enables no other services.*

### Gitaly Roles

Gitaly roles are used to set up and configure Gitaly services. For additional
information, see the [Gitaly documentation](https://docs.gitlab.com/ee/administration/gitaly/)

- **gitaly_role** (`gitlab-ce`/`gitlab-ee`)

  Configures the server with Gitaly service.

  *By default, enables no other services.*
