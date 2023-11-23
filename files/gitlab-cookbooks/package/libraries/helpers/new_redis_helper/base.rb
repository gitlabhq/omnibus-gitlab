require_relative '../../../../gitlab/libraries/redis_uri'

module NewRedisHelper
  class Base
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def redis_params
      # Defined in each component that extends this class. Should return all
      # the Redis related information required by the component to populate
      # it's own config file
      raise NotImplementedError
    end

    def redis_credentials
      params = if has_sentinels?
                 master = support_sentinel_groupname? ? master_name : master_ip
                 [master, master_port, redis_password]
               else
                 [redis_host, redis_port, redis_password]
               end

      {
        host: params[0],
        port: params[1],
        password: params[2]
      }
    end

    def redis_url
      socket = if connect_to_redis_over_tcp?
                 false
               else
                 redis_socket
               end

      if socket && !has_sentinels?
        uri = URI('unix:/')
        uri.path = socket
      else
        params = redis_credentials

        uri = NewRedisHelper.build_redis_url(
          ssl: redis_ssl,
          host: params[:host],
          port: params[:port],
          password: params[:password],
          path: "/#{redis_database}"
        )
      end

      uri.to_s
    end

    private

    def node_access_keys
      # List of keys to obtain the attributes of the service from node object.
      # For example ['gitlab', 'gitlab_workhorse'] or ['gitlab_kas']
      raise NotImplementedError
    end

    def gitlab_rb_attr
      Gitlab[node_access_keys.last]
    end

    def node_attr
      @node.dig(*node_access_keys)
    end

    def redis
      @node['redis']
    end

    def redis_server_over_tcp?
      redis['port']&.positive? || redis['tls_port']&.positive?
    end

    def connect_to_redis_over_tcp?
      gitlab_rb_attr['redis_host']
    end

    def redis_replica?
      redis['master'] == false
    end

    def sentinel_daemon_enabled?
      Services.enabled?('sentinel')
    end

    def master_name
      node_attr['redis_sentinel_master']
    end

    def master_ip
      node_attr['redis_sentinel_master_ip']
    end

    def master_port
      node_attr['redis_sentinel_master_port']
    end

    def redis_sentinels_password
      node_attr['redis_sentinels_password']
    end

    def redis_socket
      node_attr['redis_socket']
    end

    def redis_host
      node_attr['redis_host']
    end

    def redis_port
      node_attr['redis_port']
    end

    def redis_password
      node_attr['redis_password']
    end

    def redis_sentinels
      node_attr['redis_sentinels']
    end

    def redis_ssl
      !!node_attr['redis_ssl']
    end

    def redis_database
      node_attr['redis_database']
    end

    def has_sentinels?
      node_attr['redis_sentinels'] && !node_attr['redis_sentinels'].empty?
    end

    def sentinel_urls
      NewRedisHelper.build_sentinels_urls(sentinels: redis_sentinels, password: redis_sentinels_password)&.map(&:to_s)
    end

    def support_sentinel_groupname?
      # Defined in each component that extends this class. Should denote
      # whether the component can connect to the primary Redis using a
      # groupname instead of an IP
      raise NotImplementedError
    end
  end
end
