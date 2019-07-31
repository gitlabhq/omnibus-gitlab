require 'io/console'

class PostgreSQL
  class Replication
    def initialize(ctl)
      @ctl = ctl
    end

    def set_password!
      unless @ctl.service_enabled?('postgresql')
        puts 'There is no PostgreSQL instance enabled in Omnibus, exiting...'
        exit 1
      end

      run_command <<~CMD
        #{@ctl.base_path}/bin/gitlab-psql -d template1 -c \
        "ALTER USER #{replication_user} WITH ENCRYPTED PASSWORD '#{ask_password}'"
      CMD
    end

    private

    def run_command(cmd)
      GitlabCtl::Util.run_command(cmd).tap do |status|
        if status.error?
          puts status.stdout
          puts status.stderr
          puts "[ERROR] Failed to execute: #{cmd} -- be sure to run this command as root!"
          exit 1
        end
      end
    end

    def ask_password
      GitlabCtl::Util.get_password
    rescue GitlabCtl::Errors::PasswordMismatch
      $stderr.puts "Passwords do not match"
      Kernel.exit 1
    end

    def replication_user
      # We still need to support legacy attributes starting with `gitlab`, as they might exists before running
      # configure on an existing installation
      #
      # TODO: Remove support for legacy attributes in GitLab 13.0
      configured_user = (node_attributes.dig('gitlab', 'postgresql', 'sql_replication_user') ||
          node_attributes.dig('postgresql', 'sql_replication_user')).to_s

      configured_user.tap do |user|
        raise ArgumentError, 'Replication user not defined in `sql_replication_user`!' if user.strip.empty?
      end
    end

    def node_attributes
      @node_attributes ||= GitlabCtl::Util.get_node_attributes(@ctl.base_path)
    end
  end
end
