class SELinuxHelper
  class << self
    def commands(node)
      ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
      authorized_keys = node['gitlab']['gitlab-shell']['auth_file']
      gitlab_shell_var_dir = node['gitlab']['gitlab-shell']['dir']
      gitlab_shell_config_file = File.join(gitlab_shell_var_dir, "config.yml")
      gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
      gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
      gitlab_shell_secret_file = File.join(gitlab_rails_etc_dir, 'gitlab_shell_secret')

      # If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory and authorized_keys file of the
      # git_user is valid.
      selinux_code = []

      if File.exist?(ssh_dir)
        selinux_code << "semanage fcontext -a -t ssh_home_t '#{ssh_dir}(/.*)?'"
        selinux_code << "restorecon -R -v '#{ssh_dir}'"
      end

      [
        authorized_keys,
        gitlab_shell_config_file,
        gitlab_shell_secret_file
      ].each do |file|
        next unless File.exist?(file)

        selinux_code << "semanage fcontext -a -t ssh_home_t '#{file}'"
        selinux_code << "restorecon -v '#{file}'"
      end

      selinux_code.join("\n")
    end
  end
end
