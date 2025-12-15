require_relative '../helpers/shell_out_helper'

class SELinuxHelper
  class << self
    include ShellOutHelper

    def use_unified_policy?(node)
      return false if node['package']['selinux_policy_version'].nil?

      true
    end

    def gitlab_shell_files(node)
      ssh_dir = File.join(node['gitlab']['user']['home'], ".ssh")
      authorized_keys = node['gitlab']['gitlab_shell']['auth_file']
      gitlab_shell_var_dir = node['gitlab']['gitlab_shell']['dir']
      gitlab_shell_config_file = File.join(gitlab_shell_var_dir, "config.yml")
      gitlab_rails_dir = node['gitlab']['gitlab_rails']['dir']
      gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")
      gitlab_shell_secret_file = File.join(gitlab_rails_etc_dir, 'gitlab_shell_secret')
      gitlab_workhorse_sockets_directory = node['gitlab']['gitlab_workhorse']['sockets_directory']

      {
        ssh_dir: ssh_dir,
        authorized_keys: authorized_keys,
        gitlab_shell_config_file: gitlab_shell_config_file,
        gitlab_shell_secret_file: gitlab_shell_secret_file,
        gitlab_workhorse_sockets_directory: gitlab_workhorse_sockets_directory
      }
    end

    def commands(node, dry_run: false)
      files = gitlab_shell_files(node)
      restorecon_flags = "-v"
      restorecon_flags << " -n" if dry_run

      # If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory and authorized_keys file of the
      # git_user is valid.
      selinux_code = ["set -e"]
      selinux_code << "semanage fcontext -a -t gitlab_shell_t '#{files[:ssh_dir]}(/.*)?'" unless dry_run
      selinux_code << "restorecon -R #{restorecon_flags} '#{files[:ssh_dir]}'" if File.exist?(files[:ssh_dir])
      [
        files[:authorized_keys],
        files[:gitlab_shell_config_file],
        files[:gitlab_shell_secret_file],
        files[:gitlab_workhorse_sockets_directory]
      ].compact.each do |file|
        selinux_code << "semanage fcontext -a -t gitlab_shell_t '#{file}'" unless dry_run
        next unless File.exist?(file)

        selinux_code << "restorecon #{restorecon_flags} '#{file}'"
      end

      selinux_code.join("\n")
    end

    def enabled?
      success?('id -Z')
    end

    def context_set?(node)
      # semanager fcontext -l should output lines that look like:
      # /var/opt/gitlab/.ssh(/.*)?                         all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/.ssh/authorized_keys               all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-shell/config.yml            all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-workhorse/sockets           all files          system_u:object_r:gitlab_shell_t:s0
      result = Mixlib::ShellOut.new('semanage fcontext -l').run_command

      raise "error running semanage, exit code = #{result.exitstatus}, stderr = #{result.stderr}" unless result.exitstatus.zero?

      files = gitlab_shell_files(node)
      files_to_check = [
        files[:ssh_dir],
        files[:authorized_keys],
        files[:gitlab_shell_config_file],
        files[:gitlab_shell_secret_file],
        files[:gitlab_workhorse_sockets_directory]
      ].compact

      output = result.stdout.split("\n").map(&:strip)
      context_lines = output.select { |line| line.include?('gitlab_shell_t') }

      files_to_check.all? { |file| context_lines.any? { |line| line.start_with?(file) } }
    end
  end
end
