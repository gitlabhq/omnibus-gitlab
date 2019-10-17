module GeoPostgresql
  class << self
    def parse_variables
      Gitlab['geo_postgresql']['fdw_external_user'] ||=
        Gitlab['gitlab_rails']['db_username'] || node['gitlab']['gitlab-rails']['db_username']

      Gitlab['geo_postgresql']['fdw_external_password'] ||=
        Gitlab['gitlab_rails']['db_password'] || node['gitlab']['gitlab-rails']['db_password']

      postgresql_dir = Gitlab['geo_postgresql']['dir'] || node['gitlab']['geo-postgresql']['dir']

      Gitlab['geo_postgresql']['unix_socket_directory'] ||= postgresql_dir

      Gitlab['geo_postgresql']['home'] ||= postgresql_dir

      Gitlab['geo_postgresql']['data_dir'] ||= "#{postgresql_dir}/data"
    end

    def node
      Gitlab[:node]
    end
  end
end
