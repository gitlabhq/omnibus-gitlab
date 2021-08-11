module GeoSecondary
  class << self
    def parse_variables
      parse_gitlab_cluster_overrides
    end

    private

    # GitLab cluster settings overrides setttings from /etc/gitlab/gitlab.rb
    def parse_gitlab_cluster_overrides
      Gitlab.gitlab_cluster_settings.merge!('geo_secondary', 'enable')
    end
  end
end
