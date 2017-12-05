require 'mixlib/shellout'
require 'io/console'
require 'chef/mash'
require 'chef/mixins'

require 'socket'

module GitlabCtl
  module Util
    class <<self
      def get_command_output(command, user = nil)
        shell_out = run_command(command, live: false, user: user)

        begin
          shell_out.error!
        rescue Mixlib::ShellOut::ShellCommandFailed
          raise GitlabCtl::Errors::ExecutionError.new(
            command, shell_out.stdout, shell_out.stderr
          )
        end

        shell_out.stdout
      end

      def run_command(command, live: false, user: nil, timeout: nil)
        timeout = Mixlib::ShellOut::DEFAULT_READ_TIMEOUT if timeout.nil?
        shell_out = Mixlib::ShellOut.new(command, timeout: timeout)
        shell_out.user = user unless user.nil?
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

      def get_password(input_text: 'Enter password: ', do_confirm: true)
        return STDIN.gets.chomp unless STDIN.tty?

        password = STDIN.getpass(input_text)

        if do_confirm
          password_confirm = STDIN.getpass('Confirm password: ')
          raise GitlabCtl::Errors::PasswordMismatch unless password.eql?(password_confirm)
        end

        password
      end

      def userinfo(username)
        Etc.getpwnam(username)
      end
    end
  end
end
