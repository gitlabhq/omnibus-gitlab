require 'mixlib/shellout'

module GitlabCtl
  module Util
    class <<self
      def get_command_output(command)
        shell_out = Mixlib::ShellOut.new(command)
        shell_out.run_command
        begin
          shell_out.error!
        rescue Mixlib::ShellOut::ShellCommandFailed
          raise GitlabCtl::Errors::ExecutionError.new(
            command, shell_out.stdout, shell_out.stderr
          )
        end
        shell_out.stdout
      end
    end
  end
end
