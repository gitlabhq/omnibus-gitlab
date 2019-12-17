require_relative 'shell_out_helper'

class VersionHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(VersionHelper)` at the end of the class definition)
  extend ShellOutHelper

  def self.version(cmd, env: {})
    result = do_shell_out(cmd, env: env)

    raise "Execution of the command `#{cmd}` failed with a non-zero exit code (#{result.exitstatus})" unless result.exitstatus.zero?

    result.stdout
  end
end unless defined?(VersionHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
