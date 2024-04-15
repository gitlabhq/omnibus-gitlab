module RedisHelper
  class GitlabExporter < RedisHelper::Base
    def redis_params
      {
        url: redis_url,
        enable_client: enable_client
      }
    end

    private

    def enable_client
      node_attr['redis_enable_client']
    end

    # GitLab Exporter uses the same Redis information as GitLab Rails
    def node_access_keys
      %w[gitlab gitlab_rails]
    end

    def support_sentinel_groupname?
      false
    end
  end
end
