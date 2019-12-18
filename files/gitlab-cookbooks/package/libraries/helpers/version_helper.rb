require_relative 'shell_out_helper'

class VersionHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(VersionHelper)` at the end of the class definition)
  extend ShellOutHelper

  def self.version(cmd, env: {})
    result = do_shell_out(cmd, env: env)

    unless result.exitstatus.zero?
      warning = <<~MSG
        Execution of the command `#{cmd}` failed with a non-zero exit code (#{result.exitstatus})
        stdout: #{result.stdout}
        stderr: #{result.stderr}
      MSG

      raise warning
    end

    result.stdout
  end
end unless defined?(VersionHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
