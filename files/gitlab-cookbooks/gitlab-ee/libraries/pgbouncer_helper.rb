class PgbouncerHelper < BaseHelper
  attr_reader :node

  def database_config(database)
    settings = node['gitlab']['pgbouncer']['databases'][database].to_hash
    # The recipe uses user and password for the auth_user option and the pg_auth file
    settings['auth_user'] = settings.delete('user') if settings.key?('user')
    settings.delete('password') if settings.key?('password')
    settings.map do |setting, value|
      "#{setting}=#{value}"
    end.join(' ').chomp
  end

  def pgbouncer_admin_config
    user = node['postgresql']['pgbouncer_user']
    port = node['gitlab']['pgbouncer']['listen_port']
    unix_socket_dir = node['gitlab']['pgbouncer']['data_directory']
    "user=#{user} dbname=pgbouncer sslmode=disable port=#{port} host=#{unix_socket_dir}"
  end

  def pg_auth_users
    results = node['gitlab']['pgbouncer']['users'].to_hash
    node['gitlab']['pgbouncer']['databases'].each do |_db, settings|
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
    # As part of https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2078 services are
    # being split to their own dedicated cookbooks, and attributes are being moved from
    # node['gitlab'][service_name] to node[service_name]. Until they've been moved, we
    # need to check both.

    if node['gitlab'].key?(db)
      node['gitlab'][db]['enable'] &&
        !node['gitlab'][db]['pgbouncer_user'].nil? &&
        !node['gitlab'][db]['pgbouncer_user_password'].nil?
    else
      # User info for Patroni are stored under `postgresql` key
      info_key = db == 'patroni' ? 'postgresql' : db

      node[db]['enable'] &&
        !node[info_key]['pgbouncer_user'].nil? &&
        !node[info_key]['pgbouncer_user_password'].nil?
    end
  end

  def public_attributes
    {
      'gitlab' => {
        'pgbouncer' => node['gitlab']['pgbouncer'].select do |key, value|
          %w(databases_ini databases_json listen_addr listen_port).include?(key)
        end
      }
    }
  end

  def running?
    OmnibusHelper.new(node).service_up?('pgbouncer')
  end
end
