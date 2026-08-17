# postgresql/resources/database_access.rb
#
# Enforces Least Privileged Access on a single Omnibus-managed database by:
#   1. creating a per-database NOLOGIN "connect role" (<database>_connect),
#   2. granting it CONNECT on the database and USAGE on the relevant schemas,
#   3. granting that role to the login users that need access (plus pgbouncer,
#      the one deliberate cross-database exception), and
#   4. revoking the implicit PUBLIC CONNECT privilege.
#
# All of this only happens when `postgresql['restrict_database_access']` is
# enabled. It is a no-op on replicas (writes replicate via WAL) and while the
# database is offline/read-only.
#
# The GRANTs and the REVOKE are emitted as a single multi-statement psql `-c`
# string. psql sends it via the simple-query protocol, which PostgreSQL executes
# as one implicit transaction: a mid-string error rolls back the earlier
# statements (and, e.g., a VACUUM in such a string fails with "cannot run inside
# a transaction block"). So the grants land before PUBLIC is revoked atomically
# -- there is never a window in which a legitimate user is locked out. The
# GRANT-before-REVOKE ordering and the lockout guard below are defense in depth.
#
# Lockout guard: the REVOKE is only emitted once *every* required grantee (the
# connect users, and pgbouncer when `pgbouncer_user` is set) already exists. On a
# fresh install the `pgbouncer` role is created after database provisioning, so
# the REVOKE simply defers to a later reconfigure. On upgrades the role already
# exists, so enforcement applies in a single pass. When pgbouncer is not in use,
# the caller passes `pgbouncer_user nil` and the REVOKE is not deferred for it.

unified_mode true

property :database_name, String, name_property: true
property :connect_users, Array, default: []
property :schemas, Array, default: %w(public)
# The pgbouncer role that needs cross-database access to this database, or nil
# when pgbouncer does not pool it. When set, it is granted the connect role and
# the REVOKE waits until the role exists.
property :pgbouncer_user, [String, nil], default: nil
property :pg_helper, [PgHelper, GeoPgHelper], required: true, sensitive: true

action :enforce do
  next unless node['postgresql']['restrict_database_access']

  helper = new_resource.pg_helper
  next if helper.replica? || helper.is_offline_or_readonly? || !helper.is_ready?

  database = new_resource.database_name
  connect_role = "#{database}_connect"

  pgbouncer_role = new_resource.pgbouncer_user
  pgbouncer_role = nil if pgbouncer_role.to_s.empty?

  # Roles that should hold the connect role.
  required = new_resource.connect_users.dup
  required << pgbouncer_role if pgbouncer_role
  required.uniq!

  # Only grant to roles that currently exist, so we never issue a GRANT against a
  # missing role. Uses role_exists? (pg_roles) rather than user_exists?
  # (pg_user) so NOLOGIN roles -- e.g. a component database `owner` -- are
  # matched too.
  grantees = required.select { |role| helper.role_exists?(role) }

  # Only revoke PUBLIC once every required grantee exists, otherwise we would
  # lock out a role that has not been created yet. Derived from `grantees`
  # (which already resolved existence) to avoid a second round of psql lookups.
  # `required.any?` guards the degenerate case of no grantees at all: revoking
  # then would lock everyone out of the database with nothing to grant it back.
  revoke_ready = required.any? && grantees.length == required.length

  # Nothing useful to do: no grantee exists yet and we cannot revoke. Skip
  # rather than create a connect role that nobody can use. This converges on a
  # later reconfigure once the grantees exist.
  next if grantees.empty? && !revoke_ready

  postgresql_role connect_role do
    helper new_resource.pg_helper
    action :create
  end

  # Only grant USAGE on schemas that already exist. A GRANT against a missing
  # schema errors and rolls back the whole implicit transaction (including the
  # GRANT CONNECT and the REVOKE), so we skip it and converge on a later
  # reconfigure once the schema exists. `public` -- the only schema the current
  # callers pass -- always exists.
  existing_schemas = new_resource.schemas.select { |schema| helper.schema_exists?(schema, database) }
  missing_schemas = new_resource.schemas - existing_schemas

  statements = []
  statements << %(GRANT CONNECT ON DATABASE \\"#{database}\\" TO \\"#{connect_role}\\";)
  existing_schemas.each do |schema|
    statements << %(GRANT USAGE ON SCHEMA \\"#{schema}\\" TO \\"#{connect_role}\\";)
  end
  grantees.each do |role|
    statements << %(GRANT \\"#{connect_role}\\" TO \\"#{role}\\";)
  end
  statements << %(REVOKE CONNECT ON DATABASE \\"#{database}\\" FROM PUBLIC;) if revoke_ready

  # This query is intentionally run on every reconfigure rather than guarded by
  # a not_if. Every statement is idempotent in PostgreSQL, and a terminal-state
  # guard would be fragile: it could not distinguish the deferred phases (grant
  # now, revoke later) and would skip granting the connect role to any grantee
  # added in a later release. This mirrors the other unconditional
  # postgresql_query resources in these cookbooks (e.g. the registry backup
  # grants).
  postgresql_query "restrict database access for #{database}" do
    db_name database
    query statements.join(' ')
    helper new_resource.pg_helper
    action :run
  end

  unless missing_schemas.empty?
    log "defer schema USAGE grants on #{database}" do
      message "Schema(s) #{missing_schemas.join(', ')} do not exist in " \
              "#{database} yet; deferring their USAGE grant to the connect " \
              "role until the next reconfigure to avoid a transaction rollback."
      level :info
    end
  end

  unless revoke_ready
    log "defer revoke of PUBLIC CONNECT on #{database}" do
      message "Not all roles required to access #{database} exist yet " \
              "(#{required.join(', ')}); deferring REVOKE CONNECT FROM PUBLIC " \
              "until the next reconfigure to avoid locking out a service."
      level :info
    end
  end
end
