require 'mixlib/shellout'
require 'timeout'
require_relative 'postgresql/pgpass'

module GitlabCtl
  class PostgreSQL
    class << self
      def wait_for_postgresql(timeout)
        # wait for *timeout* seconds for postgresql to respond to queries
        Timeout.timeout(timeout) do
          loop do
            begin
              results = Mixlib::ShellOut.new("gitlab-psql -l", timeout: 1800)
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
      rescue Timeout::TimeoutError
        raise TimeoutError("Timed out waiting for PostgreSQL to start")
      end
    end
  end
end
