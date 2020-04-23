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

        # We still need to support legacy attributes starting with `gitlab`, as they might exists before running
        # configure on an existing installation
        #
        # TODO: Remove support for legacy attributes in GitLab 13.0
        (node_attributes.dig('gitlab', 'postgresql', 'username') || node_attributes.dig('postgresql', 'username')).to_s
      end
    end
  end
end
