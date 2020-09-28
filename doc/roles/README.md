---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Omnibus GitLab High Availability Roles

> Introduced in GitLab EE 10.1.0

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

  The GitLab App role is used to easily configure an instance where only GitLab is running. Redis, PostgreSQL, and Consul services are disabled by default.

### Redis Server Roles

Documentation on the use of the Redis Roles can be found in [Configuring Redis Cluster](https://docs.gitlab.com/ee/administration/high_availability/redis.html#configuring-redis-ha)

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

The GitLab Geo roles are used when setting up the database replication for GitLab
Geo. See the [Geo Database Documentation](https://docs.gitlab.com/ee/gitlab-geo/database.html)
for configuration steps.

- **geo_primary_role** (`gitlab-ee`)

  Prepares the database for replication and configures the application as a Geo Primary.

  *By default, enables all of GitLab's standard single node services. (NGINX, Puma, Redis, Sidekiq, etc)*

- **geo_secondary_role** (`gitlab-ee`)

  Configures the secondary database for incoming replication and flags the
  application as a Geo Secondary

  *By default, enables all of GitLab's default single node services. (NGINX, Puma, Redis, Sidekiq, etc)*

### Monitoring Roles

Monitoring roles are used to setup monitoring of HA installs. Additional documentation is available in the HA [Monitoring documentation](https://docs.gitlab.com/ee/administration/high_availability/monitoring_node.html).

- **monitoring_role** (`gitlab-ce`/`gitlab-ee`)

  Configures a central monitoring server to collect metrics and provide dashboards.

  Enables Prometheus, Alertmanager, and Grafana.

### PostgreSQL Roles

Documentation on the usage of the PostgreSQL Roles can be found in [Configuring PostgreSQL multi-node](https://docs.gitlab.com/ee/administration/high_availability/database.html#configure-using-omnibus-for-high-availability)

- **postgres_role** (`gitlab-ce`/`gitlab-ee`)

  Enables the PostgreSQL, repmgr, and Consul services on the machine

  *By default, enables no other services.*

- **pgbouncer_role** (`gitlab-ee`)

  Enables the PgBouncer and Consul services on the machine

  *By default, enables no other services.*

- **consul_role** (`gitlab-ee`)

  Enables the Consul service on the machine

  *By default, enables no other services.*
