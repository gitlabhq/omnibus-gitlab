class PgbouncerHelper < BaseHelper
  attr_reader :node

  def database_config(database)
    settings = node['gitlab']['pgbouncer']['databases'][database].to_hash
    # The recipe uses user and passowrd for the auth_user option and the pg_auth file
    settings['auth_user'] = settings.delete('user') if settings.key?('user')
    settings.delete('password') if settings.key?('password')
    settings.map do |setting, value|
      "#{setting}=#{value}"
    end.join(' ').chomp
  end

  def pg_auth_users
    results = node['gitlab']['pgbouncer']['users'].to_hash
    node['gitlab']['pgbouncer']['databases'].each do |_db, settings|
      results[settings['user']] = { 'password' => settings['password'] }
    end
    results
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
