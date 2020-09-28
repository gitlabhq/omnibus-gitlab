require 'mixlib/shellout'
require 'timeout'
require_relative 'postgresql/pgpass'
require_relative 'gitlab_ctl/util'

module GitlabCtl
  class PostgreSQL
    class << self
      def wait_for_postgresql(timeout, psql_command: 'gitlab-psql')
        # wait for *timeout* seconds for postgresql to respond to queries
        Timeout.timeout(timeout) do
          loop do
            begin
              results = Mixlib::ShellOut.new("#{psql_command} -l", timeout: 1800)
              results.run_command
              results.error!
            rescue Mixlib::ShellOut::ShellCommandFailed
              sleep 1
              next
            else
              break
            end
          end
        end
      rescue Timeout::Error
        raise Timeout::Error, "Timed out waiting for PostgreSQL to start"
      end

      def postgresql_username
        node_attributes = GitlabCtl::Util.get_node_attributes
        node_attributes.dig('postgresql', 'username').to_s
      end

      def postgresql_group
        node_attributes = GitlabCtl::Util.get_node_attributes
        node_attributes.dig('postgresql', 'group')
      end

      def postgresql_version(data_path)
        version_file = "#{data_path}/postgresql/data/PG_VERSION"

        return nil unless File.exist?(version_file)

        File.read(version_file).strip.to_i
      end
    end
  end
end
