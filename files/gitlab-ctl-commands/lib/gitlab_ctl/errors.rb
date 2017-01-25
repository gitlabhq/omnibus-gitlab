module GitlabCtl
  class Errors
    class ExecutionError < StandardError
      attr_accessor :command, :stdout, :stderr
      def initialize(command, stdout, stderr)
        @command = command
        @stdout = stdout
        @stderr = stderr
      end
    end
  end
end
