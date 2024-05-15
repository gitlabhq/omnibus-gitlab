module NewRedisHelper
  class GitlabRails < NewRedisHelper::Base
    REDIS_INSTANCES = %w[cache queues shared_state trace_chunks rate_limiting sessions repository_cache cluster_rate_limiting workhorse].freeze
    ALLOWED_REDIS_CLUSTER_INSTANCE = %w[cache rate_limiting cluster_rate_limiting].freeze

    def redis_params
      {
        url: redis_url
      }
    end

    def validate_instance_shard_config(instance)
      sentinels = node_attr["redis_#{instance}_sentinels"]
      clusters = node_attr["redis_#{instance}_cluster_nodes"]

      return if clusters.empty?

      raise "Both sentinel and cluster configurations are defined for #{instance}" unless sentinels.empty?
      raise "Cluster mode is not allowed for #{instance}" unless ALLOWED_REDIS_CLUSTER_INSTANCE.include?(instance)
    end

    private

    def node_access_keys
      %w[gitlab gitlab_rails]
    end

    def support_sentinel_groupname?
      true
    end
  end
end
