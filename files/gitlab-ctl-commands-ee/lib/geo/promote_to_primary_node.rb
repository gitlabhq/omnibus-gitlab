require 'io/console'
require 'rainbow/ext/string'

module Geo
  class PromoteToPrimaryNode
    attr_accessor :ctl, :base_path

    def initialize(ctl, options)
      @ctl = ctl
      @base_path = @ctl.base_path
      @options = options
    end

    def execute
      run_preflight_checks
      final_confirmation
      toggle_geo_roles
      promote_postgresql_to_primary
      reconfigure
      promote_to_primary
      success_message
    end

    private

    def run_preflight_checks
      return true if @options[:skip_preflight_checks]

      begin
        PromotionPreflightChecks.new(@base_path, @options).execute
      rescue SystemExit => e
        raise e unless @options[:force]

        confirm_proceed_after_preflight_checks_fail
      end
    end

    def confirm_proceed_after_preflight_checks_fail
      puts
      puts 'WARNING: Preflight checks failed but you are running this in '\
        'force mode. If you proceed data loss may happen. '\
        'This may be desired in case of an actual disaster.'\
        'Are you sure you want to proceed? (y/n)'.color(:yellow)

      return if STDIN.gets.chomp.casecmp('y').zero?

      exit 1
    end

    def final_confirmation
      return if @options[:force]

      puts
      puts 'WARNING: Secondary will now be promoted to primary. '\
        'Are you sure you want to proceed? (y/n)'.color(:yellow)

      return if STDIN.gets.chomp.casecmp('y').zero?

      exit 1
    end

    def toggle_geo_roles
      puts
      puts 'Disabling the secondary role and enabling the primary in the cluster configuration file...'.color(:yellow)
      puts

      cluster_helper = GitlabClusterHelper.new
      cluster_helper.config['primary'] = true
      cluster_helper.config['secondary'] = false
      return if cluster_helper.write_to_file!

      puts "ERROR: Could not write to #{GitlabClusterHelper::JSON_FILE}.".color(:red)
      exit 1
    end

    def promote_postgresql_to_primary
      Geo::PromoteDb.new(ctl).execute
    end

    def reconfigure
      puts
      puts 'Reconfiguring...'.color(:yellow)
      puts

      run_command('gitlab-ctl reconfigure', live: true)
    end

    def promote_to_primary
      puts
      puts 'Running gitlab-rake geo:set_secondary_as_primary...'.color(:yellow)
      puts

      run_command('gitlab-rake geo:set_secondary_as_primary', live: true)
    end

    def success_message
      puts
      puts 'You successfully promoted this node!'.color(:green)
    end

    def run_command(cmd, live: false)
      GitlabCtl::Util.run_command(cmd, live: live)
    end
  end
end
