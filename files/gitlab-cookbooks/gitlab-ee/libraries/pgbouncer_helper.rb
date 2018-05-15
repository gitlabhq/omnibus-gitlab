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
    user = node['gitlab']['postgresql']['pgbouncer_user']
    port = node['gitlab']['pgbouncer']['listen_port']
    unix_socket_dir = node['gitlab']['pgbouncer']['data_directory']
    "user=#{user} dbname=pgbouncer sslmode=disable port=#{port} host=#{unix_socket_dir}"
  end

  def pg_auth_users
    results = node['gitlab']['pgbouncer']['users'].to_hash
    node['gitlab']['pgbouncer']['databases'].each do |_db, settings|
      results[settings['user']] = { 'password' => settings['password'] }
    end
    results
  end

  def create_pgbouncer_user?(db)
    node['gitlab'][db]['enable'] &&
      !node['gitlab'][db]['pgbouncer_user'].nil? &&
      !node['gitlab'][db]['pgbouncer_user_password'].nil?
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
end
