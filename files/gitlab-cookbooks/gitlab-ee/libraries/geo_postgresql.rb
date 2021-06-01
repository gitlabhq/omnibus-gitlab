module GeoPostgresql
  class << self
    def parse_variables
      postgresql_dir = Gitlab['geo_postgresql']['dir'] || node['gitlab']['geo-postgresql']['dir']

      Gitlab['geo_postgresql']['unix_socket_directory'] ||= postgresql_dir

      Gitlab['geo_postgresql']['home'] ||= postgresql_dir
    end

    def node
      Gitlab[:node]
    end
  end
end
