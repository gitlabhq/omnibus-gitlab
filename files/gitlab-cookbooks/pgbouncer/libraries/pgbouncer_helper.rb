class PgbouncerHelper < BaseHelper
  attr_reader :node

  def database_config(database)
    settings = node['pgbouncer']['databases'][database].to_hash
    # The recipe uses user and password for the auth_user option and the pg_auth file
    settings['auth_user'] = settings.delete('user') if settings.key?('user')
    settings.delete('password') if settings.key?('password')
    settings.map do |setting, value|
      "#{setting}=#{value}"
    end.join(' ').chomp
  end

  def pgbouncer_admin_config
    user = node['postgresql']['pgbouncer_user']
    port = node['pgbouncer']['listen_port']
    unix_socket_dir = node['pgbouncer']['data_directory']
    "user=#{user} dbname=pgbouncer sslmode=disable port=#{port} host=#{unix_socket_dir}"
  end

  def pg_auth_users
    results = node['pgbouncer']['users'].to_hash
    node['pgbouncer']['databases'].each do |_db, settings|
      results[settings['user']] = { 'password' => settings['password'] }
      results[settings['user']]['auth_type'] = settings['auth_type'] if settings.key?('auth_type')
    end
    results
  end

  ##
  # Returns the auth_type prefix for the password field in the pgbouncer auth_file
  # https://www.pgbouncer.org/config.html#section-users
  #
  # +type+ - The auth_type that is being used
  #
  # Returns the proper prefix for the chosen auth_type, or nil by default.
  # This allows types such as plain or trust to be used.
  def pg_auth_type_prefix(type)
    case type.downcase
    when 'md5'
      'md5'
    when 'scram-sha-256'
      'SCRAM-SHA-256$'
    end
  end

  def create_pgbouncer_user?(db)
    node_attribute_key = SettingsDSL::Utils.sanitized_key(db)
    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.

    if node['gitlab'].key?(node_attribute_key)
      node['gitlab'][node_attribute_key]['enable'] &&
        !node['gitlab'][node_attribute_key]['pgbouncer_user'].nil? &&
        !node['gitlab'][node_attribute_key]['pgbouncer_user_password'].nil?
    else
      # User info for Patroni are stored under `postgresql` key
      info_key = node_attribute_key == 'patroni' ? 'postgresql' : node_attribute_key

      node[node_attribute_key]['enable'] &&
        !node[info_key]['pgbouncer_user'].nil? &&
        !node[info_key]['pgbouncer_user_password'].nil?
    end
  end

  def public_attributes
    {
      'pgbouncer' => node['pgbouncer'].select do |key, value|
        %w(databases_ini databases_json listen_addr listen_port).include?(key)
      end
    }
  end

  def running?
    OmnibusHelper.new(node).service_up?('pgbouncer')
  end
end
