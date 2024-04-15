module RedisHelper
  class GitlabKAS < RedisHelper::Base
    def redis_params
      {
        network: redis_network,
        address: redis_address,
        password: redis_credentials[:password],
        sentinels: redis_sentinels,
        sentinelMaster: master_name,
        sentinelPassword: redis_sentinels_password,
        ssl: redis_ssl
      }
    end

    private

    def redis_network
      redis_url.scheme == 'unix' ? 'unix' : 'tcp'
    end

    def redis_address
      redis_network == 'tcp' ? "#{redis_host}:#{redis_port || URI::Redis::DEFAULT_PORT}" : redis_socket
    end

    def master_name
      node_attr['redis_sentinels_master_name']
    end

    def node_access_keys
      %w[gitlab_kas]
    end

    def support_sentinel_groupname?
      true
    end
  end
end
