module GeoPostgresql
  class << self
    def parse_variables
      postgresql_dir = Gitlab['geo_postgresql']['dir'] || node['gitlab']['geo-postgresql']['dir']

      Gitlab['geo_postgresql']['unix_socket_directory'] ||= postgresql_dir
      Gitlab['geo_postgresql']['home'] ||= postgresql_dir

      parse_wal_keep_size
    end

    def node
      Gitlab[:node]
    end

    private

    def parse_wal_keep_size
      wal_segment_size = 16
      wal_keep_segments = Gitlab['geo_postgresql']['wal_keep_segments'] || node['gitlab']['geo-postgresql']['wal_keep_segments']
      wal_keep_size = Gitlab['geo_postgresql']['wal_keep_size'] || node['gitlab']['geo-postgresql']['wal_keep_size']

      Gitlab['geo_postgresql']['wal_keep_size'] = if wal_keep_size.nil?
                                                    wal_keep_segments.to_i * wal_segment_size
                                                  else
                                                    wal_keep_size
                                                  end
    end
  end
end
