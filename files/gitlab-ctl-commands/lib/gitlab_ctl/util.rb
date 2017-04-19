require 'mixlib/shellout'

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
    end
  end
end
