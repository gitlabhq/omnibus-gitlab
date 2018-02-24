module GeoPostgresql
  class << self
    def parse_variables
      Gitlab['geo_postgresql']['fdw_external_user'] ||=
        Gitlab['gitlab_rails']['db_username'] || node['gitlab']['gitlab-rails']['db_username']

      Gitlab['geo_postgresql']['fdw_external_password'] ||=
        Gitlab['gitlab_rails']['db_password'] || node['gitlab']['gitlab-rails']['db_password']
    end

    def node
      Gitlab[:node]
    end
  end
end
