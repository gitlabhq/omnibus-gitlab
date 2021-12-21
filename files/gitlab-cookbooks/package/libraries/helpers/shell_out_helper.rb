require 'mixlib/shellout'

module ShellOutHelper
  def do_shell_out(cmd, user = nil, cwd = nil, env: {})
    o = Mixlib::ShellOut.new(cmd, user: user, cwd: cwd, environment: env)
    o.run_command
    o
  rescue Errno::EACCES
    Chef::Log.info("Cannot execute #{cmd}.")
    o
  rescue Errno::ENOENT
    Chef::Log.info("#{cmd} does not exist.")
    o
  end

  def do_shell_out_with_embedded_path(cmd, user = nil, cwd = nil, env: {})
    env = env.transform_keys(&:to_sym)
    modified_paths = ["/opt/gitlab/embedded/bin"]
    modified_paths << env[:PATH] if env.key?(:PATH)
    modified_paths << ENV['PATH']
    env[:PATH] = modified_paths.join(':')

    do_shell_out(cmd, user, cwd, env: env)
  end

  def success?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus.zero?
  end

  def failure?(cmd)
    o = do_shell_out(cmd)
    o.exitstatus != 0
  end
end
