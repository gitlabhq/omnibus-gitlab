require_relative 'shell_out_helper'

class VersionHelper
  extend ShellOutHelper

  def self.version(cmd)
    result = do_shell_out(cmd)
    if result.exitstatus == 0
      result.stdout
    else
      nil
    end
  end
end
