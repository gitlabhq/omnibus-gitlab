# frozen_string_literal: true

require_relative '../version_helper'

module NewRedisHelper
  class Server < NewRedisHelper::Base
    def installed_version
      return unless OmnibusHelper.new(@node).service_up?('redis')

      command = '/opt/gitlab/embedded/bin/redis-server --version'

      command_output = VersionHelper.version(command)
      raise "Execution of the command `#{command}` failed" unless command_output

      version_match = command_output.match(/Redis server v=(?<redis_version>\d*\.\d*\.\d*)/)
      raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

      version_match['redis_version']
    end

    def running_version
      return unless OmnibusHelper.new(@node).service_up?('redis')

      commands = ['/opt/gitlab/embedded/bin/redis-cli']
      commands << redis_cli_connect_options
      commands << "INFO"
      command = commands.join(" ")

      command_output = VersionHelper.version(command)
      raise "Execution of the command `#{command}` failed" unless command_output

      version_match = command_output.match(/redis_version:(?<redis_version>\d*\.\d*\.\d*)/)
      raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

      version_match['redis_version']
    end

    private

    def redis_cli_connect_options
      args = []
      if redis_server_over_tcp?
        args = redis_cli_tcp_connect_options(args)
      else
        args << "-s #{redis['unixsocket']}"
      end

      args << "-a '#{redis['password']}'" if redis['password']

      args
    end

    def redis_cli_tcp_connect_options(args)
      args << ["-h #{redis['default_host']}"]
      port = redis['port'].to_i

      if port.zero?
        args = redis_cli_tls_options(args)
      else
        args << "-p #{port}"
      end

      args
    end

    def redis_cli_tls_options(args)
      tls_port = redis['tls_port'].to_i

      args << "--tls"
      args << "-p #{tls_port}"
      args << "--cacert '#{redis['tls_ca_cert_file']}'" if redis['tls_ca_cert_file']
      args << "--cacertdir '#{redis['tls_ca_cert_dir']}'" if redis['tls_ca_cert_dir']

      return args unless client_certs_required?

      raise "Redis TLS client authentication requires redis['tls_cert_file'] and redis['tls_key_file'] options" unless client_cert_and_key_available?

      args << "--cert '#{redis['tls_cert_file']}'"
      args << "--key '#{redis['tls_key_file']}'"

      args
    end

    def client_certs_required?
      redis['tls_auth_clients'] == 'yes'
    end

    def client_cert_and_key_available?
      redis['tls_cert_file'] && !redis['tls_cert_file'].empty? &&
        redis['tls_key_file'] && !redis['tls_key_file'].empty?
    end
  end
end
