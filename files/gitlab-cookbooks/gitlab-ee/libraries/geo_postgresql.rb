module GeoPostgresql
  class << self
    def parse_variables
      postgresql_dir = Gitlab['geo_postgresql']['dir'] || node['gitlab']['geo-postgresql']['dir']

      Gitlab['geo_postgresql']['unix_socket_directory'] ||= postgresql_dir
      Gitlab['geo_postgresql']['home'] ||= postgresql_dir

      parse_gitlab_cluster_overrides
    end

    def node
      Gitlab[:node]
    end

    private

    # GitLab cluster settings overrides setttings from /etc/gitlab/gitlab.rb
    def parse_gitlab_cluster_overrides
      Gitlab.gitlab_cluster_settings.merge!('geo_postgresql', 'enable')
    end
  end
end
