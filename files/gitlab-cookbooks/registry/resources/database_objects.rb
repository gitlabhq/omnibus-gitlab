# registry/resources/database_objects.rb

unified_mode true

property :pg_helper, [GeoPgHelper, PgHelper], required: true, sensitive: true

default_action :nothing

action :nothing do
end

action :create do
  host = node['postgresql']['unix_socket_directory']
  port = node['postgresql']['port']
  database_name = node['postgresql']['registry']['dbname']
  username = node['postgresql']['registry']['user']
  password = node['postgresql']['registry']['password']
  backup_username = node['postgresql']['registry']['database_backup_username']
  backup_password = node['postgresql']['registry']['database_backup_password']
  restore_username = node['postgresql']['registry']['database_restore_username']
  restore_password = node['postgresql']['registry']['database_restore_password']

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

  # NOTE(prozlach): Only create backup user and related objects when
  # credentials are defined pg_hba mapping requires password provided for
  # backup/restore users to work, hence we can rely on these checks here.
  if !backup_username.to_s.empty? && !backup_password.to_s.empty?
    # Pre-create partitions schema for registry database
    # This schema is used for table partitioning and must exist before
    # granting permissions to backup user
    postgresql_schema 'partitions' do
      database database_name
      owner username
      helper new_resource.pg_helper

      action :create
    end

    # Create backup user with minimal privileges for pg_dump
    postgresql_user backup_username do
      password "md5#{backup_password}"
      options %w[NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION]

      action :create
    end

    schemas = %w[public partitions]

    queries = schemas.flat_map do |schema|
      [
        "GRANT USAGE ON SCHEMA #{schema} TO \"#{backup_username}\";",
        "GRANT SELECT ON ALL TABLES IN SCHEMA #{schema} TO \"#{backup_username}\";",
        "GRANT SELECT ON ALL SEQUENCES IN SCHEMA #{schema} TO \"#{backup_username}\";",
        "ALTER DEFAULT PRIVILEGES FOR ROLE \"#{username}\" IN SCHEMA #{schema} GRANT SELECT ON TABLES TO \"#{backup_username}\";",
        "ALTER DEFAULT PRIVILEGES FOR ROLE \"#{username}\" IN SCHEMA #{schema} GRANT SELECT ON SEQUENCES TO \"#{backup_username}\";"
      ]
    end.join("\n")

    postgresql_query "grant registry database backup privileges to #{backup_username}" do
      db_name database_name
      query <<-EOF
        GRANT CONNECT ON DATABASE "#{database_name}" TO "#{backup_username}";
        #{queries}
      EOF
      helper new_resource.pg_helper
      action :run
    end
  end

  # Only create restore user when credentials are defined
  if !restore_username.to_s.empty? && !restore_password.to_s.empty?
    # Create restore user with superuser privileges for database restore operations
    # SUPERUSER grants all privileges automatically including:
    #   - CREATE on all databases and schemas
    #   - Ability to SET ROLE to any user (registry_user)
    #   - CREATE TRIGGER on all tables
    #   - Bypass all permission checks
    postgresql_user restore_username do
      password "md5#{restore_password}"
      options %w[SUPERUSER]

      action :create
    end
  end
end
