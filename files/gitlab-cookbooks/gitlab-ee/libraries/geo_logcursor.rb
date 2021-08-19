module GeoLogcursor
  class << self
    def parse_variables
      parse_gitlab_cluster_overrides
    end

    private

    # GitLab cluster settings overrides setttings from /etc/gitlab/gitlab.rb
    def parse_gitlab_cluster_overrides
      Gitlab.merge_cluster_attribute!('geo_logcursor', 'enable', GitlabCluster.config.get('geo_logcursor', 'enable'))
    end
  end
end
