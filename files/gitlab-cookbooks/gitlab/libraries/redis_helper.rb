require_relative 'redis_uri.rb'
require 'cgi'

class RedisHelper
  REDIS_INSTANCES = %w[cache queues shared_state trace_chunks rate_limiting sessions repository_cache cluster_rate_limiting workhorse].freeze
  ALLOWED_REDIS_CLUSTER_INSTANCE = %w[cache rate_limiting cluster_rate_limiting].freeze

  def initialize(node)
    @node = node
  end

  def redis
    @node['redis']
  end

  def redis_params(service_config: @node['gitlab']['gitlab_rails'], support_sentinel_groupname: true)
    raise 'Redis announce_ip and announce_ip_from_hostname are mutually exclusive, please unset one of them' if redis['announce_ip'] && redis['announce_ip_from_hostname']

    params = if RedisHelper::Checks.has_sentinels? && support_sentinel_groupname
               [redis['master_name'], redis['master_port'], redis['master_password']]
             else
               host = service_config['redis_host'] || Gitlab['redis']['master_ip']
               port = service_config['redis_port'] || Gitlab['redis']['master_port']
               password = service_config['redis_password'] || Gitlab['redis']['master_password']

               [host, port, password]
             end
    params
  end

  def redis_url(support_sentinel_groupname: true)
    gitlab_rails = @node['gitlab']['gitlab_rails']

    redis_socket = gitlab_rails['redis_socket']
    redis_socket = false if RedisHelper::Checks.is_gitlab_rails_redis_tcp?
    params = redis_params(support_sentinel_groupname: support_sentinel_groupname)

    if redis_socket && !RedisHelper::Checks.has_sentinels?
      uri = URI("unix://")
      uri.path = redis_socket

      if params[2]
        password = encode_redis_password(params[2])
        uri.userinfo = ":#{password}"
      end
    else
      uri = build_redis_url(
        ssl: gitlab_rails['redis_ssl'],
        host: params[0],
        port: params[1],
        password: params[2],
        path: "/#{gitlab_rails['redis_database']}"
      )
    end

    uri
  end

  def workhorse_params
    gitlab_rails = @node['gitlab']['gitlab_rails']
    if gitlab_rails['redis_workhorse_instance'] || !gitlab_rails['redis_workhorse_sentinels'].empty?
      {
        url: gitlab_rails['redis_workhorse_instance'],
        password: gitlab_rails['redis_workhorse_password'],
        sentinels: redis_sentinel_urls('redis_workhorse_sentinels'),
        sentinelMaster: gitlab_rails['redis_workhorse_sentinel_master'],
        sentinelPassword: gitlab_rails['redis_workhorse_sentinels_password']
      }
    else
      {
        url: redis_url,
        password: redis_params.last,
        sentinels: redis_sentinel_urls('redis_sentinels'),
        sentinelMaster: redis['master_name'],
        sentinelPassword: gitlab_rails['redis_sentinels_password']
      }
    end
  end

  def validate_instance_shard_config(instance)
    gitlab_rails = @node['gitlab']['gitlab_rails']

    sentinels = gitlab_rails["redis_#{instance}_sentinels"]
    clusters = gitlab_rails["redis_#{instance}_cluster_nodes"]

    return if clusters.empty?

    raise "Both sentinel and cluster configurations are defined for #{instance}" unless sentinels.empty?
    raise "Cluster mode is not allowed for #{instance}" unless ALLOWED_REDIS_CLUSTER_INSTANCE.include?(instance)
  end

  def build_redis_url(ssl:, host:, port:, path:, password:)
    scheme = ssl ? 'rediss:/' : 'redis:/'
    uri = URI(scheme)
    uri.host = host
    uri.port = port
    uri.path = path
    # In case the password has non-alphanumeric passwords, be sure to encode it
    uri.password = encode_redis_password(password) if password

    uri
  end

  def encode_redis_password(password)
    URI::Generic::DEFAULT_PARSER.escape(password)
  end

  def redis_sentinel_urls(sentinels_key)
    gitlab_rails = @node['gitlab']['gitlab_rails']

    sentinels = gitlab_rails[sentinels_key]

    return [] unless sentinels

    sentinels_password = gitlab_rails["#{sentinels_key}_password"]

    sentinels.map do |sentinel|
      build_redis_url(
        ssl: sentinel['ssl'],
        host: sentinel['host'],
        port: sentinel['port'],
        path: '',
        password: sentinels_password)
    end
  end

  class Checks
    class << self
      def is_redis_tcp?
        (Gitlab['redis']['port'] && Gitlab['redis']['port'].positive?) || (Gitlab['redis']['tls_port'] && Gitlab['redis']['tls_port'].positive?)
      end

      def is_redis_replica?
        Gitlab['redis']['master'] == false
      end

      def sentinel_daemon_enabled?
        Services.enabled?('sentinel')
      end

      def has_sentinels?
        Gitlab['gitlab_rails']['redis_sentinels'] && !Gitlab['gitlab_rails']['redis_sentinels'].empty?
      end

      def is_gitlab_rails_redis_tcp?
        Gitlab['gitlab_rails']['redis_host']
      end

      def replica_role?
        Gitlab['redis_replica_role']['enable']
      end
    end
  end
end
