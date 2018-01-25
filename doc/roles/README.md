# Omnibus GitLab High Availability Roles

>**Notes:**
>- Introduced in GitLab EE 10.1.0
>- The majority of these roles will only work on an [Enterprise Edition](https://about.gitlab.com/products/) installation of GitLab.

Omnibus GitLab includes various software components/services to support running GitLab in
a high availability configuration. By default, some of these supporting services
are disabled, and Omnibus GitLab is configured to run as a single node installation.
Each service can be enabled or disabled using configuration settings in `/etc/gitlab/gitlab.rb`,
but the introduction of `roles` allows you to easily enable a group of services,
and provides better default configuration based on the high availability roles you
have enabled.

## Not specifying any Roles (the default configuration)

When you don't configure GitLab with any roles, GitLab enables the default services for
a single node install. These include things like PostgreSQL, Redis, Unicorn, Sidekiq,
Gitaly, GitLab Workhorse, Nginx, etc.

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

### GitLab App Role

- **application_role**

  The GitLab App role is used to easily configure an instance where only GitLab is running. Redis, Postgres, and Consul services are disabled by default.

### Redis Server Roles

Documentation on the use of the Redis Roles can be found in [Configuring Redis HA](https://docs.gitlab.com/ee/administration/high_availability/redis.html#configuring-redis-ha)

- **redis_sentinel_role**

  Enables the sentinel service on the machine,

  *By default, enables no other services.*
- **redis_master_role**

  Enables the redis service and monitoring, and allows configuring the master password

  *By default, enables no other services.*
- **redis_slave_role**

  Enables the redis service and monitoring

  *By default, enables no other services.*

### GitLab Geo Roles

The GitLab Geo roles are used when setting up the database replication for GitLab
Geo. See the [Geo Database Documentation](https://docs.gitlab.com/ee/gitlab-geo/database.html)
for configuration steps.

- **geo_primary_role**

  Prepares the database for replication and configures the application as a Geo Primary.

  *By default, enables all of GitLab's standard single node services. (Nginx, Unicorn, Redis, Sidekiq, etc)*
- **geo_secondary_role**

  Configures the secondary database for incoming replication and flags the
  application as a Geo Secondary

  *By default, enables all of GitLab's default single node services. (Nginx, Unicorn, Redis, Sidekiq, etc)*

### Postgres Roles

Documentation on the usage of the Postgres Roles can be found in [Configuring Postgres HA](https://docs.gitlab.com/ee/administration/high_availability/database.html#configure-using-omnibus-for-high-availability)

- **postgres_role**

  Enables the postgresql, repmgr, and consul services on the machine

  *By default, enables no other services.*
- **pgbouncer_role**

  Enables the pgbouncer and consul services on the machine

  *By default, enables no other services.*
- **consul_role**

  Enables the consul service on the machine

  *By default, enables no other services.*
