require 'rainbow/ext/string'

# The first path works on production, while the second path works for tests
begin
  require_relative '../../../omnibus-ctl/lib/gitlab_ctl/util'
rescue LoadError
  require_relative '../../../gitlab-ctl-commands/lib/gitlab_ctl/util'
end

module Geo
  # PromoteDb promotes standby database as usual "pg-ctl promote" but
  # if point-in-time LSN file is found, the database will be recovered to that state first
  class PromoteDb
    PITR_FILE_NAME = 'geo-pitr-file'.freeze

    attr_accessor :base_path, :postgresql_dir_path

    def initialize(ctl)
      @base_path = ctl.base_path
      @postgresql_dir_path = GitlabCtl::Util.get_public_node_attributes.dig('postgresql', 'dir')
    end

    def execute
      return true if recovery_to_point_in_time

      puts
      puts 'Promoting the PostgreSQL read-only replica to primary...'.color(:yellow)
      puts

      run_command('/opt/gitlab/embedded/bin/gitlab-pg-ctl promote', live: true).error!

      success_message
    end

    private

    def postgresql_version
      @postgresql_version ||= GitlabCtl::PostgreSQL.postgresql_version
    end

    def recovery_to_point_in_time
      lsn = lsn_from_pitr_file

      return if lsn.nil?

      puts
      puts "Recovery to point #{lsn} and promoting...".color(:yellow)
      puts

      write_recovery_settings(lsn)

      run_command('gitlab-ctl restart postgresql', live: true).error!

      success_message

      true
    end

    def lsn_from_pitr_file
      geo_pitr_file = "#{postgresql_dir_path}/data/#{PITR_FILE_NAME}"

      return nil unless File.exist?(geo_pitr_file)

      lsn = File.read(geo_pitr_file)

      lsn.empty? ? nil : lsn
    end

    def built_recovery_setting_for_pitr(lsn)
      <<-EOF
        recovery_target_lsn = '#{lsn}'
        recovery_target_action = 'promote'
      EOF
    end

    def write_recovery_settings(lsn)
      settings = built_recovery_setting_for_pitr(lsn)

      if postgresql_version >= 12
        puts "PostgreSQL 12 or newer. Writing settings to postgresql.conf...".color(:green)

        write_geo_config_file(settings)
      else
        puts "Writing recovery.conf...".color(:green)

        write_recovery_conf(settings)
      end
    end

    def write_geo_config_file(settings)
      geo_conf_file = "#{postgresql_dir_path}/data/gitlab-geo.conf"

      File.open(geo_conf_file, "w", 0640) do |file|
        file.write(settings)
      end
    end

    def write_recovery_conf(settings)
      recovery_conf = "#{postgresql_dir_path}/data/recovery.conf"

      File.open(recovery_conf, 'a', 0640) do |file|
        file.write(settings)
      end
    end

    def run_command(cmd, live: false)
      GitlabCtl::Util.run_command(cmd, live: live)
    end

    def success_message
      puts
      puts 'The database is successfully promoted!'.color(:green)
    end
  end
end
