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

      existing, equivalences =
        if dry_run
          [[], []]
        else
          stdout = run_semanage_fcontext_l
          [parse_fcontext_patterns(stdout), parse_equivalences(stdout)]
        end

      # If SELinux is enabled, make sure that OpenSSH thinks the .ssh directory and authorized_keys file of the
      # git_user is valid. semanage refuses to register an fcontext spec that falls under an equivalence source
      # (EL10 ships '/var/opt = /opt'), so we register the substituted spec while still running restorecon
      # against the real path - the equivalence makes the label apply there.
      selinux_code = ["set -e"]
      unless dry_run
        ssh_spec = equivalent_spec("#{files[:ssh_dir]}(/.*)?", equivalences)
        op = existing.include?(ssh_spec) ? "-m" : "-a"
        selinux_code << "semanage fcontext #{op} -t gitlab_shell_t '#{ssh_spec}'"
      end
      selinux_code << "restorecon -R #{restorecon_flags} '#{files[:ssh_dir]}'" if File.exist?(files[:ssh_dir])
      [
        files[:authorized_keys],
        files[:gitlab_shell_config_file],
        files[:gitlab_shell_secret_file],
        files[:gitlab_workhorse_sockets_directory]
      ].compact.each do |file|
        unless dry_run
          spec = equivalent_spec(file, equivalences)
          op = existing.include?(spec) ? "-m" : "-a"
          selinux_code << "semanage fcontext #{op} -t gitlab_shell_t '#{spec}'"
        end
        next unless File.exist?(file)

        selinux_code << "restorecon #{restorecon_flags} '#{file}'"
      end

      selinux_code.join("\n")
    end

    def enabled?
      success?('id -Z')
    end

    def existing_fcontext_patterns
      parse_fcontext_patterns(run_semanage_fcontext_l)
    end

    # Parses the equivalence lines ("/var/opt = /opt") out of `semanage fcontext -l`,
    # returning [source, target] pairs sorted longest-source-first so the most
    # specific equivalence wins.
    def parse_equivalences(output)
      pairs = output.split("\n").filter_map do |line|
        next unless (match = line.strip.match(%r{\A(/\S+)\s*=\s*(/\S+)\z}))

        [match[1], match[2]]
      end
      pairs.sort_by { |source, _| -source.length }
    end

    # Rewrites an fcontext spec to honor a semanage equivalence: if the spec falls
    # under an equivalence source path, the source prefix is replaced with the
    # target (e.g. /var/opt/gitlab/.ssh(/.*)? -> /opt/gitlab/.ssh(/.*)?). Returns
    # the spec unchanged when no equivalence applies.
    def equivalent_spec(spec, equivalences)
      equivalences.each do |source, target|
        # Matches `source` only at a path-segment boundary (i.e., followed by "/", "(", or end-of-string)
        prefix = %r{\A#{Regexp.escape(source)}(?=/|\(|\z)}
        return spec.sub(prefix, target) if spec.match?(prefix)
      end
      spec
    end

    def context_set?(node)
      # semanager fcontext -l should output lines that look like:
      # /var/opt/gitlab/.ssh(/.*)?                         all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/.ssh/authorized_keys               all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-shell/config.yml            all files          system_u:object_r:gitlab_shell_t:s0
      # /var/opt/gitlab/gitlab-workhorse/sockets           all files          system_u:object_r:gitlab_shell_t:s0
      stdout = run_semanage_fcontext_l

      files = gitlab_shell_files(node)
      equivalences = parse_equivalences(stdout)
      patterns_to_check = [
        "#{files[:ssh_dir]}(/.*)?",
        files[:authorized_keys],
        files[:gitlab_shell_config_file],
        files[:gitlab_shell_secret_file],
        files[:gitlab_workhorse_sockets_directory]
      ].compact.map { |pattern| equivalent_spec(pattern, equivalences) }

      output = stdout.split("\n").map(&:strip)
      context_lines = output.select { |line| line.include?('gitlab_shell_t') }

      patterns_to_check.all? { |pattern| context_lines.any? { |line| line.split.first == pattern } }
    end

    private

    # Runs `semanage fcontext -l` and returns its stdout.
    # Raises if the command exits with a non-zero status.
    def run_semanage_fcontext_l
      result = Mixlib::ShellOut.new('semanage fcontext -l').run_command

      raise "error running semanage, exit code = #{result.exitstatus}, stderr = #{result.stderr.strip}" unless result.exitstatus.zero?

      result.stdout
    end

    # Parses the fcontext path entries out of `semanage fcontext -l` stdout,
    # returning the first field of each line that starts with '/' and is not
    # an equivalence line (e.g. "/var/opt = /opt").
    def parse_fcontext_patterns(output)
      output.split("\n").filter_map do |line|
        next unless line.start_with?('/')
        next if line.match?(/^\S+\s*=\s*\S+$/)

        line.split.first
      end
    end
  end
end
