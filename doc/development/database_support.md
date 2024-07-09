---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Database support

This document provides details and examples on how to implement database support
for an Omnibus GitLab component. The [architecture blueprint](../architecture/multiple_database_support/index.md)
provides the design and definitions.

1. [Level 1](#level-1)
1. [Level 2](#level-2)
   1. [Examples](#examples)
      1. [Example 1: Registry database objects](#example-1-registry-database-objects)
      1. [Example 2: Registry database migrations](#example-2-registry-database-migrations)
      1. [Example 3: Use database objects and migrations of Registry](#example-3-use-database-objects-and-migrations-of-registry)
      1. [Example 4: Parametrized database objects resource for Rails](#example-4-parameterized-database-objects-resource-for-rails)
1. [Level 3](#level-3)
1. [Level 4](#level-4)
1. [Considerations](#considerations)
1. [Bridge the gap](#bridge-the-gap)
   1. [Reorganize the existing database operations](#reorganize-the-existing-database-operations)
   1. [Support dedicated PgBouncer user for databases](#support-dedicated-pgbouncer-user-for-databases)
   1. [Delay the population of PgBouncer database configuration](#delay-the-population-of-pgbouncer-database-configuration)
   1. [Configurable Consul watch for databases](#configurable-consul-watch-for-databases)
   1. [Helper class for general database migration requirements](#helper-class-for-general-database-migration-requirements)

## Level 1

1. Add the new database-related configuration attributes to `gitlab.rb`. Do
   not forget to update `gitlab.rb.template`.
1. Update the Chef recipe to consume the configuration attributes. At this
   level, the requirement is to pass down the attributes to the component,
   generally its through configuration files or command-line arguments.

For example in `registry` cookbook:

- `registry['database']` attribute is added to `gitlab.rb` (see [`attributes/default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/565f7a73f721fa40efc936dfd735b849986ce0ac/files/gitlab-cookbooks/registry/attributes/default.rb#L39)).
- The configuration template uses the attribute to configure registry (see [`templates/default/registry-config.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/565f7a73f721fa40efc936dfd735b849986ce0ac/files/gitlab-cookbooks/registry/templates/default/registry-config.yml.erb#L47)).

## Level 2

1. Add dependency to `postgresql` and `pgbouncer` cookbooks. Use `depends` in
   `metadata.rb`. This ensures that requirements are met and their Chef custom
   resources are available to the cookbook.

1. Create a `database_objects` custom resource in `resources/` directory of the
   cookbook with the default `nothing` action (a no-op action) and a `create`
   action. The `create` action can leverage the existing `postgresql` custom
   resources to set up the required database objects for the component.

   See:
   - `postgresql_user`
   - `postgresql_database`
   - `postgresql_schema`
   - `postgresql_extension`
   - `postgresql_query`

   A `database_objects` resource of must create _all_ of the required database
   objects for a component. It must not assume that another cookbook creates
   some of the objects that it needs.

1. Create a `database_migrations` custom resource in `resources/` directory of
   the cookbook with the default `nothing` action (a no-op action) and a `run`
   action. The `run` action executes the commands
   for database migrations of the component.

   When the migration runs, it can safely assume that all of the required
   database objects are available. Therefore this resource depends on successful
   `create` action of `database_objects` resource.

1. In the `default` recipe of the cookbook, use a `database_objects` resource
   that notifies a `database_migrations` resources to `run`. The migrations
   should be able to run `immediately` after the preparation of database objects
   but a component may choose not to use the immediate trigger.

### Examples

All of the following code blocks are provided as examples. You may need
to make adjustments to ensure that they meet your requirements.

#### Example 1: Registry database objects

The following example shows a `database_objects` resource in the `registry`
cookbook defined in `registry/resources/database_objects.rb`.

Notice how it uses custom resources from the `postgresql` cookbook to create
the required database objects.

```ruby
# registry/resources/database_objects.rb

unified_mode true

property :pg_helper, [GeoPgHelper, PgHelper], required: true, sensitive: true

default_action :nothing

action :nothing do
end

action :create do
  host = node['registry']['database']['host']
  port = node['registry']['database']['port']
  database_name = node['registry']['database']['database_name']
  username = node['registry']['database']['username']
  password = node['registry']['database']['password']

  postgresql_user username do
    password "md5#{password}" unless password.nil?

    action :create
  end

  postgresql_database database_name do
    database_socket host
    database_port port
    owner username
    helper new_resource.pg_helper

    action :create
  end

  postgresql_extension 'btree_gist' do
    database database_name

    action :enable
  end
end
```

#### Example 2: Registry database migrations

The following example shows a `database_migrations` resource in the `registry`
cookbook defined in `registry/resources/database_objects.rb`.
Notice how the resource accepts additional parameters. Parameters help
support different migration scenarios, for example separation of pre-deployment
or post-deployment migrations. It also uses [`MigrationHelper`](#helper-class-for-general-database-migration-requirements)
to decide whether to run a migration or not.

```ruby
# registry/resources/database_migrations.rb

unified_mode true

property :name, name_property: true
property :direction, Symbol, default: :up
property :dry_run, [true, false], default: false
property :force, [true, false], default: false
property :limit, [Integer, nil], default: nil
property :skip_post_deployment, [true, false], default: false

default_action :nothing

action :nothing do
end

action :run do
  # MigrationHelper is not implemented. It contains general-purpose helper
  # methods for managing migrations, for example if a specific component
  # migrations can run or not.
  #
  # See: "Helper class for general database migration requirements"
  migration_helper = MigrationHelper.new(node)

  account_helper = AccountHelper.new(node)
  logfiles_helper = LogfilesHelper.new(node)
  logging_settings = logfiles_helper.logging_settings('registry')  

  bash_hide_env "migrate registry database: #{new_resource.name}" do
    code <<-EOH
    set -e

    LOG_FILE="#{logging_settings[:log_directory]}/db-migrations-$(date +%Y-%m-%d-%H-%M-%S).log"

    umask 077
    /opt/gitlab/embedded/bin/registry \
      #{new_resource.direction} \
      #{"--dry-run" if new_resource.dry_run} \
      #{"--limit #{new_resource.limit}" unless new_resource.limit.nil?} \
      ... \
      #{working_dir}/config.yml \
      2>& 1 | tee ${LOG_FILE}

    STATUS=${PIPESTATUS[0]}

    chown #{account_helper.gitlab_user}:#{account_helper.gitlab_group} ${LOG_FILE}

    exit $STATUS
    EOH

    not_if { migration_helper.run_migration?('registry') }
  end
end
```

#### Example 3: Use database objects and migrations of Registry

The resources defined in the previous examples are used in
`registry/recipes/enable.rb` recipe.

See how `only_if` and `not_if` guards are used to decide when to create the
database objects or run the migrations. Also, pay attention to the way that
`notifies` is used to show the dependency of the migrations on the successful
creation of database objects.

```ruby
# registry/recipes/enable.rb

# ...

pg_helper = PgHelper.new(node)

registry_database_objects 'default' do
  pg_helper pg_helper
  action :create
  only_if { node['registry']['database']['enable'] }
  not_if { pg_helper.replica? }
  notifies :create, 'registry_database_migrations[up]', :immediately if pg_helper.is_ready?
end

registry_database_migrations 'up' do
  direction :up
  only_if { node['registry']['database']['enable'] }
  not_if { pg_helper.replica? }  
end

# ...
```

#### Example 4: Parameterized database objects resource for Rails

The following example shows how a single implementation of the database objects
for Rails application can satisfy the requirements of the decomposed database model.

In this example the _logical_ database is passed as the _resource name_ and is
used to lookup settings of each database from the configuration. The settings
are passed to `postgresql` custom resources. This is particularly useful when
the majority of implementation of can be reused to replace two or more resources.

```ruby
# gitlab/resources/database_objects.rb

unified_mode true

property :pg_helper, [GeoPgHelper, PgHelper], required: true, sensitive: true

default_action :nothing

action :nothing do
end

action :create do
  global_database_settings = {
    # ...
    port: node['postgresql']['port']
    host: node['gitlab']['gitlab_rails']['db_host']
    # ...
  }
  database_settings = node['gitlab']['gitlab_rails']['databases'][new_resource.resource_name]

  database_settings = global_database_settings.merge(database_settings) unless database_settings.nil?

  username = database_settings[:username]
  password = database_settings[:password]
  database_name = database_settings[:database_name]
  host = database_settings[:host]
  port = database_settings[:port]

  postgresql_user username do
    password "md5#{password}" unless password.nil?

    action :create
  end

  postgresql_database database_name do
    database_socket host
    database_port port
    owner username
    helper new_resource.pg_helper

    action :create
  end

  postgresql_extension 'btree_gist' do
    database database_name

    action :enable
  end
end
```

And this is how it is used in `gitlab/recipes/default.rb`:

```ruby
gitlabe_database_objects 'main' do
  pg_helper pg_helper

  action :create
  only_if { node['gitlab']['gitlab_rails']['databases']['main']['enable'] ... }
end

gitlabe_database_objects 'ci' do
  pg_helper pg_helper

  action :create
  only_if { node['gitlab']['gitlab_rails']['databases']['ci']['enable'] ... }
end
```

## Level 3

1. Add a new attribute for PgBouncer user. Make sure that this attribute is
   mapped to the existing `pgbouncer['databases']` setting and can consume it.
   This attribute is used to create a dedicated PgBouncer user for the component
   as opposed to reusing the existing Rails user, the same as what Praefect
   currently does.

   NOTE **Note:**
   It is very important that we do not introduce any breaking changes to
   `gitlab.rb`. The current user settings must work without any change.

1. Use `pgbouncer_user` custom resource from `pgbouncer` cookbook to create the
   dedicated PgBouncer user for the component. Use the attribute that is
   described in the previous step.

## Level 4

1. Add a new attribute for the component to specify the name of the Consul
   service of the database cluster. This is either the name of the scope of the
   Patroni cluster (when automatic service registry for Patroni, i.e. `patroni['register_service']`,
   is enabled) or the name of the Consul service that is configured manually
   without Omnibus GitLab.

1. Use `database_watch` custom resource<sup>([Needs Implementation](#configurable-consul-watch-for-databases))</sup>
   to define a new Consul watch for the database cluster service. It notifies
   PgBouncer to update the logical database endpoint when the leader of the
   cluster changes. Pass the name of the Consul service, logical database, and
   any other PgBouncer options as parameters to the watch.

_All_ `database_watch` _resources must be placed in the_ `consul` _cookbook_. As
opposed to the previous levels, this is the only place where database-related
resources are concentrated in one cookbook, `consul`, and not managed in
the same cookbooks as their associated components.

The reason for this exception is that the watches run on the PgBouncer nodes,
where `pgbouncer_role` is used. All components, except PgBouncer and Consul,
are disabled. Note that this is in line with existing user configuration since
it is [the recommended configuration for PgBouncer node](https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#configure-pgbouncer-nodes).
We don't want to introduce any breaking changes into `gitlab.rb`.

## Considerations

- _No other resource should be involved with database setup_.

- All custom resources _must be idempotent_. For example they must not fail
  when an object already exist even though they are created or ran in another
  cookbook. Instead they must be able to update the current state of the
  database objects, configuration, or migrations based on the new user inputs.

- In HA mode, given that multiple physical nodes are involved, Omnibus GitLab
  may encounter certain limitations to provide full automation of the
  configuration. This is an acceptable limitation.

## Bridge the gap

Currently not all of the custom resources or helper classes are available. Even
if they are, they may require some adjustments to meet the specified requirements.
Here are some examples.

### Reorganize the existing database operations

This model requires some adjustments in `postgresql`, `patroni`, and `gitlab`
cookbooks. For example `database_objects` that is defined in `gitlab` cookbook
must be used in the same cookbook and its usage must be removed from `postgresql`
and `patroni` cookbooks.

The database service cookbooks (`postgresql` and `patroni`) should not deal with
database objects and migrations and must delegate them to the application
cookbooks (e.g. `gitlab`, `registry`, and `praefect`). However, to support this,
custom resources of `postgresql` cookbook must be able to work on any node.
Currently they assume they run on the PostgreSQL node and use the UNIX socket to
connect to the database server. This assumption forces to place all database
operations in one cookbook.

The same is true for `pgbouncer` cookbook. Currently the only PgBouncer user is
created in the `users` recipe of this cookbook. This can change as well to allow
each component cookbook to create its own PgBouncer users.

### Support dedicated PgBouncer user for databases

The current `pgbouncer` cookbook [_mostly_ supports multiple databases](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#configure-a-new-pgbouncer-database-with-pool_mode--session).

The `pgbouncer` cookbook only creates PgBouncer users for the main Rails database. This
is why non-Rails applications connect with the same PgBouncer user created for Rails.

We can currently set up PgBouncer support for decomposed Rails databases sharing
the same user. But for Praefect or Registry, we need additional work to create
dedicated PgBouncer users.

NOTE **Note:**
A shared user does not mean connection settings for each database must
be the same. It only means that multiple databases use the same user for
PgBouncer connection.

### Delay the population of PgBouncer database configuration

The implementation of `gitlab-ctl pgb-notify` supports multiple
databases. It is generic enough that, as long as the PgBouncer users are created,
it can update `databases.ini` from the `databases.json` file.

However, when PgBouncer users are pulled into individual cookbooks, the initial
`databases.ini` that is created or updated in `gitlab-ctl reconfigure` may not
be valid because it references PgBouncer users that are not created yet.
We should be able to fix this by delaying the action on Chef resource that calls
`gitlab-ctl pgb-notify`.

### Configurable Consul watch for databases

Consul cluster can be shared between multiple Patroni clusters (using different
scopes, such as `patroni['scope']`), but updating PgBouncer configuration is still
problematic because the Consul watch scripts are not fully configurable.

The current implementation has several limitations:

1. Omnibus GitLab uses `postgresql` service that is [explicitly defined](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/consul/recipes/enable_service_postgresql.rb)
   in `consul` cookbook. This service, that is currently being used to notify
   PgBouncer, is a leftover of the transition from RepMgr to Patroni. It must
   be replaced with the Consul service that [Patroni registers](https://patroni.readthedocs.io/en/latest/yaml_configuration.html#consul).
   When `patroni['register_service']` is enabled Patroni registers a Consul
   service with `patroni['scope']` parameter and the tag `master`, `primary`,
   `replica`, or `standby-leader` depending on the node's role.

1. The current [failover script](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/consul/templates/default/watcher_scripts/failover_pgbouncer.erb)
   is associated to a Consul watch for `postgresql` service and is not capable
   of handling multiple databases because [database name can not be changed](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/a9c14f6cfcc9fe0d9e98da7d04f43c5772d5f768/files/gitlab-cookbooks/consul/libraries/watch_helper.rb#L50).

We need to extend the current Omnibus GitLab capability to use Consul watches to
track Patroni services, find cluster leaders, and notify PgBouncer with a
parameterized failover script.

In order to do this we implement `database_watch` custom resource in `consul`
cookbook. It defines a database-specific Consul watch for database a cluster
service and passes the required information to a parameterized failover script
to notify PgBouncer. The key attributes of this resource are:

1. The service name, that specifies which database cluster must be watched.
   It could be the scope of the Patroni cluster when `patroni['register_service']`
   is enabled or a Consul service name when it is manually configured.

1. The database name that specifies which logical databases should be
   reconfigured when the database cluster leader changes.

### Helper class for general database migration requirements

`MigrationHelper`<sup>(Needs implementation)</sup> implements general
requirements of database migrations, including the central switch for enabling
or disabling auto-migrations. It can also provides the mapping between the
existing and new configuration attributes.
