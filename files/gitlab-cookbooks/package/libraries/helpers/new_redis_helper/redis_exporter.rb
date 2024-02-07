# frozen_string_literal: true

module NewRedisHelper
  class RedisExporter < NewRedisHelper::Base
    def redis_params
      {
        url: redis_url
      }
    end

    def formatted_redis_url
      url = redis_url

      url.scheme == 'unix' ? "unix://#{url.path}" : url.to_s
    end

    private

    def node_access_keys
      %w[gitlab gitlab_rails]
    end

    def support_sentinel_groupname?
      false
    end
  end
end
