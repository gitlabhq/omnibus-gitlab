require_relative 'redis_uri.rb'
require 'cgi'

class RedisHelper
  REDIS_INSTANCES = %w[cache queues shared_state trace_chunks rate_limiting sessions repository_cache cluster_rate_limiting workhorse].freeze
  ALLOWED_REDIS_CLUSTER_INSTANCE = %w[cache rate_limiting cluster_rate_limiting].freeze

  def initialize(node)
    @node = node
  end

  def redis_params(support_sentinel_groupname: true)
    gitlab_rails_config = @node['gitlab']['gitlab_rails']
    redis_config = @node['redis']

    raise 'Redis announce_ip and announce_ip_from_hostname are mutually exclusive, please unset one of them' if redis_config['announce_ip'] && redis_config['announce_ip_from_hostname']

    params = if RedisHelper::Checks.has_sentinels? && support_sentinel_groupname
               [redis_config['master_name'], redis_config['master_port'], redis_config['master_password']]
             else
               host = gitlab_rails_config['redis_host'] || Gitlab['redis']['master_ip']
               port = gitlab_rails_config['redis_port'] || Gitlab['redis']['master_port']
               password = gitlab_rails_config['redis_password'] || Gitlab['redis']['master_password']

               [host, port, password]
             end
    params
  end

  def redis_url(support_sentinel_groupname: true)
    gitlab_rails = @node['gitlab']['gitlab_rails']

    redis_socket = gitlab_rails['redis_socket']
    redis_socket = false if RedisHelper::Checks.is_gitlab_rails_redis_tcp?

    if redis_socket && !RedisHelper::Checks.has_sentinels?
      uri = URI('unix:/')
      uri.path = redis_socket
    else
      params = redis_params(support_sentinel_groupname: support_sentinel_groupname)

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
        sentinelMaster: @node['redis']['master_name'],
        sentinelPassword: @node['redis']['master_password']
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
    uri.password = CGI.escape(password) if password

    uri
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

  def running_version
    return unless OmnibusHelper.new(@node).service_up?('redis')

    commands = ['/opt/gitlab/embedded/bin/redis-cli']

    commands << if RedisHelper::Checks.is_redis_tcp?
                  "-h #{@node['redis']['bind']} -p #{@node['redis']['port']}"
                else
                  "-s #{@node['redis']['unixsocket']}"
                end

    commands << "-a '#{Gitlab['redis']['password']}'" if Gitlab['redis']['password']

    commands << "INFO"
    command = commands.join(" ")

    command_output = VersionHelper.version(command)
    raise "Execution of the command `#{command}` failed" unless command_output

    version_match = command_output.match(/redis_version:(?<redis_version>\d*\.\d*\.\d*)/)
    raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

    version_match['redis_version']
  end

  def installed_version
    return unless OmnibusHelper.new(@node).service_up?('redis')

    command = '/opt/gitlab/embedded/bin/redis-server --version'

    command_output = VersionHelper.version(command)
    raise "Execution of the command `#{command}` failed" unless command_output

    version_match = command_output.match(/Redis server v=(?<redis_version>\d*\.\d*\.\d*)/)
    raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

    version_match['redis_version']
  end

  class Checks
    class << self
      def is_redis_tcp?
        Gitlab['redis']['port'] && Gitlab['redis']['port'].positive?
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
