require 'mixlib/shellout'
require 'chef/mash'
require 'chef/mixins'

require 'socket'

module GitlabCtl
  module Util
    class <<self
      def get_command_output(command)
        shell_out = run_command(command)

        begin
          shell_out.error!
        rescue Mixlib::ShellOut::ShellCommandFailed
          raise GitlabCtl::Errors::ExecutionError.new(
            command, shell_out.stdout, shell_out.stderr
          )
        end

        shell_out.stdout
      end

      def run_command(command, live: false)
        shell_out = Mixlib::ShellOut.new(command)
        shell_out.live_stdout = $stdout if live
        shell_out.live_stderr = $stderr if live
        shell_out.run_command
        shell_out
      end

      def fqdn
        results = run_command('hostname -f')
        results.stdout.chomp
      end

      def get_node_attributes(base_path)
        # reconfigure creates a json file containing all of the attributes of
        # the node after a chef run, indexed by priority. Merge an return those
        # as a single level Hash
        attribute_file = "#{base_path}/embedded/nodes/#{fqdn}.json"
        begin
          data = JSON.parse(File.read(attribute_file))
        rescue JSON::ParserError
          raise GitlabCtl::Errors::NodeError(
            "Error reading #{attribute_file}, has reconfigure been run yet?"
          )
        end

        Chef::Mixin::DeepMerge.merge(data['default'], data['normal'])
      end
    end
  end
end
