module RedisHelper
  class GitlabWorkhorse < RedisHelper::Base
    def redis_params
      {
        url: redis_url.to_s,
        password: redis_credentials[:password],
        sentinels: sentinel_urls,
        sentinelMaster: master_name,
        sentinelPassword: redis_sentinels_password
      }
    end

    private

    def node_access_keys
      %w[gitlab gitlab_workhorse]
    end

    def support_sentinel_groupname?
      true
    end
  end
end
