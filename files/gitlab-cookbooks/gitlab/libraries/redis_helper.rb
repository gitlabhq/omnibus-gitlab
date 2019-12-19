require_relative 'redis_uri.rb'
require 'cgi'

class RedisHelper
  def initialize(node)
    @node = node
  end

  def redis_params(support_sentinel_groupname: true)
    gitlab_rails_config = @node['gitlab']['gitlab-rails']
    redis_config = @node['redis']

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
    gitlab_rails = @node['gitlab']['gitlab-rails']

    redis_socket = gitlab_rails['redis_socket']
    redis_socket = false if RedisHelper::Checks.is_gitlab_rails_redis_tcp?

    if redis_socket && !RedisHelper::Checks.has_sentinels?
      uri = URI('unix:/')
      uri.path = redis_socket
    else
      scheme = gitlab_rails['redis_ssl'] ? 'rediss:/' : 'redis:/'
      uri = URI(scheme)
      params = redis_params(support_sentinel_groupname: support_sentinel_groupname)
      # In case the password has non-alphanumeric passwords, be sure to encode it
      params[2] = CGI.escape(params[2]) if params[2]
      uri.host, uri.port, uri.password = params
      uri.path = "/#{gitlab_rails['redis_database']}"
    end

    uri
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

      def is_redis_slave?
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
    end
  end
end
