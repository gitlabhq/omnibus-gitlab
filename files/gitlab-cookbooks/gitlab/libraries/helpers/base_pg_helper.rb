# This is a base class to be inherited by PG Helpers
require_relative 'base_helper'
require_relative '../pg_version'

class BasePgHelper < BaseHelper
  include ShellOutHelper
  attr_reader :node

  PG_HASH_PATTERN ||= /\{(.*)\}/.freeze
  PG_HASH_PAIR_SEPARATOR ||= ','.freeze
  PG_HASH_PAIR_ESCAPED_PATTERN ||= /^"|"$/.freeze
  PG_HASH_KEY_VALUE_SEPARATOR ||= '='.freeze
  PG_ESCAPED_DOUBLE_QUOTE_PATTERN ||= /\\"/.freeze
  PG_ESCAPED_BACKSLASH_PATTERN ||= /\\{2}/.freeze

  def is_running?
    omnibus_helper = OmnibusHelper.new(node)
    omnibus_helper.service_up?(service_name) || (delegated? && omnibus_helper.service_up?(delegate_service_name) && ready?)
  end

  def is_managed_and_offline?
    OmnibusHelper.new(node).is_managed_and_offline?(service_name)
  end

  def database_exists?(db_name)
    psql_cmd(["-d 'template1'",
              "-c 'select datname from pg_database' -A",
              "| grep -x #{db_name}"])
  end

  def database_empty?(db_name)
    psql_cmd(["-d '#{db_name}'",
              "-c '\\dt' -A",
              "| grep -x 'No relations found.'"])
  end

  def extension_exists?(extension_name)
    psql_cmd(["-d 'template1'",
              "-c 'select name from pg_available_extensions' -A",
              "| grep -x #{extension_name}"])
  end

  def extension_enabled?(extension_name, db_name)
    psql_cmd(["-d '#{db_name}'",
              "-c 'select extname from pg_extension' -A",
              "| grep -x #{extension_name}"])
  end

  def extension_can_be_enabled?(extension_name, db_name)
    is_running? &&
      !is_standby? &&
      extension_exists?(extension_name) &&
      database_exists?(db_name) &&
      !extension_enabled?(extension_name, db_name)
  end

  def user_exists?(db_user)
    psql_cmd(["-d 'template1'",
              "-c 'select usename from pg_user' -A",
              "|grep -x #{db_user}"])
  end

  def user_options(db_user)
    query = "SELECT usecreatedb, usesuper, userepl, usebypassrls FROM pg_shadow WHERE usename='#{db_user}'"
    values = do_shell_out(
      %(/opt/gitlab/bin/#{service_cmd} -d template1 -c "#{query}" -tA)
    ).stdout.chomp.split('|').map { |v| v == 't' }
    options = %w(CREATEDB SUPERUSER REPLICATION BYPASSRLS)
    Hash[options.zip(values)]
  end

  def user_options_set?(db_user, options)
    active_options = user_options(db_user)
    options.map(&:upcase).each do |option|
      if option =~ /^NO(.*)/
        return false if active_options[Regexp.last_match(1)]
      else
        return false unless active_options[option]
      end
    end
    true
  end

  # Check if database schema exists for specified database
  #
  # @param [Object] schema_name database schema name
  # @param [Object] db_name database name
  def schema_exists?(schema_name, db_name)
    psql_cmd(["-d '#{db_name}'",
              "-c 'select schema_name from information_schema.schemata' -A",
              "| grep -x #{schema_name}"])
  end

  # Check if database user is owner of specified schema
  #
  # You need to check if schema exists before running this
  #
  # @param [String] schema_name database schema name
  # @param [String] db_name database name
  # @param [String] owner the database user to be checked as owner
  # @return [Boolean] whether specified database user is the owner
  def schema_owner?(schema_name, db_name, owner)
    psql_cmd(["-d '#{db_name}'",
              %(-c "select schema_owner from information_schema.schemata where schema_name='#{schema_name}'" -A),
              "| grep -x #{owner}"])
  end

  # Used to compare schema with foreign schema, to determine if foreign tables
  # need to be refreshed
  def retrieve_schema_tables(schema_name, db_name)
    sql = <<~SQL
        SELECT table_name, column_name, data_type
          FROM information_schema.columns
         WHERE table_catalog = '#{db_name}'
           AND table_schema = '#{schema_name}'
           AND table_name NOT LIKE 'pg_%'
      ORDER BY table_name, column_name, data_type
    SQL

    psql_query(db_name, sql)
  end

  def fdw_server_exists?(server_name, db_name)
    psql_cmd(["-d '#{db_name}'",
              "-c 'select srvname from pg_foreign_server' -tA",
              "| grep -x #{server_name}"])
  end

  def user_hashed_password(db_user)
    db_user_safe = db_user.scan(/[a-z_][a-z0-9_-]*[$]?/).first
    psql_query('template1', "SELECT passwd FROM pg_shadow WHERE usename='#{db_user_safe}'")
  end

  def user_password_match?(db_user, db_pass)
    if db_pass.nil? || /^md5.{32}$/.match(db_pass)
      # if the password is in the MD5 hashed format or is empty, do a simple compare
      db_pass.to_s == user_hashed_password(db_user)
    else
      # if password is in plain-text, convert to MD5 format before doing comparison
      hashed = Digest::MD5.hexdigest("#{db_pass}#{db_user}")
      "md5#{hashed}" == user_hashed_password(db_user)
    end
  end

  # Parses hash type content from PostgreSQL and return a ruby hash
  #
  # @param [String] raw_content from command-line output
  # @return [Hash] hash with key and values from parsed content
  def parse_pghash(raw_content)
    parse_pghash_pairs(raw_content).each_with_object({}) do |pair, hash|
      key, value = parse_pghash_key_value(pair)
      hash[key.to_sym] = value
    end
  end

  def node_attributes
    return node['gitlab'][service_name] if node['gitlab'].key?(service_name)

    node[service_name]
  end

  def is_standby?
    # PostgreSQL <= 11 uses recovery.conf to configure a standby node.
    # PostgreSQL 12 switched to the .signal files
    %w(recovery.conf recovery.signal standby.signal).each do |standby_file|
      return true if ::File.exist?(::File.join(node_attributes['dir'], 'data', standby_file))
    end
    false
  end

  alias_method :replica?, :is_standby?

  def is_offline_or_readonly?
    !is_running? || is_standby?
  end

  # Returns an array of function names for the given database
  #
  # Uses the  `\df` PostgreSQL command to generate a list of functions and their
  # attributes, then cuts out only the function names.
  #
  # @param database [String] the name of the database
  # @return [Array] the list of functions associated with the database
  def list_functions(database)
    do_shell_out(
      %(/opt/gitlab/bin/#{service_cmd} -d #{database} -c '\\df' -tA -F, | cut -d, -f2)
    ).stdout.split("\n")
  end

  def has_function?(database, function)
    list_functions(database).include?(function)
  end

  def bootstrapped?
    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.

    return File.exist?(File.join(node['gitlab'][service_name]['data_dir'], 'PG_VERSION')) if node['gitlab'].key?(service_name)

    File.exist?(File.join(node[service_name]['data_dir'], 'PG_VERSION'))
  end

  def psql_cmd(cmd_list)
    cmd = ["/opt/gitlab/bin/#{service_cmd}", cmd_list.join(' ')].join(' ')
    success?(cmd)
  end

  # Return the results of a psql query
  # - db_name: Name of the database to query
  # - query: SQL query to run
  def psql_query(db_name, query)
    psql_query_raw(db_name, query).stdout.chomp
  end

  # Get the Mixlib::Shellout object containing the command results.
  # Allows for more fine grained error handling
  # - db_name: Name of the database to query
  # - query: SQL query to run
  def psql_query_raw(db_name, query)
    do_shell_out(
      %(/opt/gitlab/bin/#{service_cmd} -d '#{db_name}' -c "#{query}" -tA)
    )
  end

  def version
    PGVersion.parse(VersionHelper.version('/opt/gitlab/embedded/bin/psql --version').split.last)
  end

  def running_version
    PGVersion.parse(psql_query('template1', 'SHOW SERVER_VERSION'))
  end

  def database_version
    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.

    version_file = node['gitlab'].key?(service_name) ? "#{@node['gitlab'][service_name]['data_dir']}/PG_VERSION" : "#{@node[service_name]['data_dir']}/PG_VERSION"
    PGVersion.new(File.read(version_file).chomp) if File.exist?(version_file)
  end

  def pg_shadow_lookup
    <<-EOF
    CREATE OR REPLACE FUNCTION public.pg_shadow_lookup(in i_username text, out username text, out password text) RETURNS record AS $$
    BEGIN
        SELECT usename, passwd FROM pg_catalog.pg_shadow
        WHERE usename = i_username INTO username, password;
        RETURN;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    REVOKE ALL ON FUNCTION public.pg_shadow_lookup(text) FROM public, pgbouncer;
    GRANT EXECUTE ON FUNCTION public.pg_shadow_lookup(text) TO pgbouncer;
    EOF
  end

  def service_name
    raise NotImplementedError
  end

  def service_cmd
    raise NotImplementedError
  end

  def delegate_service_name
    'patroni'
  end

  def delegated?
    # When Patroni is enabled, the configuration of PostgreSQL instance must be delegated to it.
    # PostgreSQL cookbook skips some of the steps that are must be done either during or after
    # Patroni bootstraping.
    Gitlab['patroni']['enable'] && !Gitlab['repmgr']['enable']
  end

  def ready?
    psql_cmd(%w(-d template1 -c 'SELECT 1;'))
  end

  def config_dir
    Gitlab['patroni']['enable'] ? node['patroni']['data_dir'] : node['postgresql']['data_dir']
  end

  def postgresql_config
    ::File.join(config_dir, "postgresql#{Gitlab['patroni']['enable'] ? '.base' : ''}.conf")
  end

  def postgresql_runtime_config
    ::File.join(config_dir, 'runtime.conf')
  end

  def pg_hba_config
    ::File.join(config_dir, 'pg_hba.conf')
  end

  def pg_ident_config
    ::File.join(config_dir, 'pg_ident.conf')
  end

  def ssl_cert_file
    ::File.absolute_path(node['postgresql']['ssl_cert_file'], config_dir)
  end

  def ssl_key_file
    ::File.absolute_path(node['postgresql']['ssl_key_file'], config_dir)
  end

  private

  def stringify_hash_values(options)
    options.each_with_object({}) { |(k, v), hash| hash[k] = v.to_s }
  end

  def parse_pghash_pairs(raw_content)
    raw_content.gsub(PG_HASH_PATTERN) { Regexp.last_match(1) }
               .split(PG_HASH_PAIR_SEPARATOR)
  end

  def parse_pghash_key_value(pair)
    pair.gsub(PG_HASH_PAIR_ESCAPED_PATTERN, '')
        .gsub(PG_ESCAPED_DOUBLE_QUOTE_PATTERN, '"')
        .gsub(PG_ESCAPED_BACKSLASH_PATTERN, '')
        .split(PG_HASH_KEY_VALUE_SEPARATOR)
  end
end
