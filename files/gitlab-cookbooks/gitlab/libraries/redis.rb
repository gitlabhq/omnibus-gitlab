#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'open3'

require_relative 'redis_uri.rb'
require_relative 'redis_helper.rb'

module Redis
  CommandExecutionError = Class.new(StandardError)

  class << self
    def parse_variables
      parse_redis_settings
      parse_redis_sentinel_settings
      parse_rename_commands
      populate_extra_config
    end

    def parse_redis_settings
      if RedisHelper::Checks.is_redis_tcp?
        # The user wants Redis to listen via TCP instead of unix socket.
        Gitlab['redis']['unixsocket'] = false

        parse_redis_bind_address
        # Try to discover gitlab_rails redis connection params
        # based on redis daemon
        parse_redis_daemon! unless RedisHelper::Checks.has_sentinels?
      end

      Gitlab['redis']['master'] = false if RedisHelper::Checks.replica_role?

      # When announce-ip is defined and announce-port not, infer the later from the main redis_port
      # This functionality makes sense for redis replicas but with sentinel, the redis role can swap
      # We introduce the option regardless the user defined de redis node as master or replica
      Gitlab['redis']['announce_port'] ||= Gitlab['redis']['port'] if Gitlab['redis']['announce_ip']

      Gitlab['redis']['master_password'] ||= Gitlab['redis']['password'] if redis_managed? && (RedisHelper::Checks.sentinel_daemon_enabled? || RedisHelper::Checks.is_redis_replica? || Gitlab['redis_master_role']['enable'])

      return unless RedisHelper::Checks.sentinel_daemon_enabled? || RedisHelper::Checks.is_redis_replica?

      raise "redis 'master_ip' is not defined" unless Gitlab['redis']['master_ip']
      raise "redis 'master_password' is not defined" unless Gitlab['redis']['master_password']
    end

    def parse_redis_sentinel_settings
      return unless RedisHelper::Checks.sentinel_daemon_enabled?

      Gitlab['gitlab_rails']['redis_sentinels_password'] ||= Gitlab['sentinel']['password']

      RedisHelper::REDIS_INSTANCES.each do |instance|
        Gitlab['gitlab_rails']["redis_#{instance}_sentinels_password"] ||= Gitlab['sentinel']['password']
      end
    end

    def parse_rename_commands
      return unless Gitlab['redis']['rename_commands'].nil?

      Gitlab['redis']['rename_commands'] = {
        'KEYS' => ''
      }
    end

    def redis_managed?
      Services.enabled?('redis')
    end

    def populate_extra_config
      return unless Gitlab['redis']['extra_config_command']

      command = Gitlab['redis']['extra_config_command']

      begin
        _, stdout_stderr, status = Open3.popen2e(*command.split(" "))
      # If the command is path to a script and it doesn't exist, inform the user
      rescue Errno::ENOENT
        raise CommandExecutionError, "Redis: Execution of `#{command}` failed. File does not exist."
      end

      output = stdout_stderr.read
      stdout_stderr.close

      # Command execution failed. Inform the user.
      raise CommandExecutionError, "Redis: Execution of `#{command}` failed with exit code #{status.value.exitstatus}. Output: #{output}" unless status.value.success?

      Gitlab['redis']['extra_config'] = output
      parse_redis_password_from_extra_config(output)
    end

    # Extract the password from generated config. This password is used by
    # omnibus-gitlab library code to connect to Redis to get running version.
    def parse_redis_password_from_extra_config(config)
      passwords = {
        password: %r{requirepass ['"](?<password>.*)['"]$},
        master_password: %r{masterauth ['"](?<master_password>.*)['"]$}
      }
      config.lines.each do |config|
        passwords.each do |setting, reg|
          match = reg.match(config)
          Gitlab['redis']["extracted_#{setting}"] = match[setting] if match
        end
      end
    end

    private

    def parse_redis_bind_address
      return unless redis_managed?

      redis_bind = Gitlab['redis']['bind'] || node['redis']['bind']
      Gitlab['redis']['default_host'] = redis_bind.split(' ').first
    end

    def parse_redis_daemon!
      return unless redis_managed?

      redis_bind = Gitlab['redis']['bind'] || node['redis']['bind']
      Gitlab['gitlab_rails']['redis_host'] ||= Gitlab['redis']['default_host']

      redis_port_config_key = if Gitlab['redis'].key?('port') && !Gitlab['redis']['port'].zero?
                                # If Redis is specified to run on a non-TLS port
                                'port'
                              elsif Gitlab['redis'].key?('tls_port') && !Gitlab['redis']['tls_port'].zero?
                                # If Redis is specified to run on a TLS port
                                'tls_port'
                              else
                                # If Redis is running on neither ports, then it doesn't matter which
                                # key we choose as both will return `nil`.
                                'port'
                              end

      redis_port = Gitlab['redis'][redis_port_config_key]
      Gitlab['gitlab_rails']['redis_port'] ||= redis_port

      Gitlab['gitlab_rails']['redis_password'] ||= Gitlab['redis']['master_password']

      Chef::Log.warn "gitlab-rails 'redis_host' is different than 'bind' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_host'] != redis_bind

      Chef::Log.warn "gitlab-rails 'redis_port' is different than '#{redis_port_config_key}' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_port'] != redis_port

      Chef::Log.warn "gitlab-rails 'redis_password' is different than 'master_password' value defined for managed redis instance. Are you sure you are pointing to the same redis instance?" if Gitlab['gitlab_rails']['redis_password'] != Gitlab['redis']['master_password']
    end

    def node
      Gitlab[:node]
    end
  end
end
