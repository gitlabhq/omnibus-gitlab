require 'io/console'
require 'rainbow/ext/string'

module Geo
  class PromotionPreflightChecks
    def initialize(base_path, options)
      @base_path = base_path
      @options = options
    end

    def execute
      begin
        confirm_manual_checks
        confirm_primary_is_down

        check_replication_verification_status
      rescue RuntimeError => e
        puts e.message
        exit 1
      end

      success_message
    end

    private

    def confirm_manual_checks
      puts
      puts 'Ensure you have completed the following manual '\
        'preflight checks:'
      puts '- Check if you need to migrate to Object Storage'
      puts '- Review configuration of each secondary node'
      puts '- Run system checks'
      puts '- Check that secrets match between nodes'
      puts '- Notify users of scheduled maintenance'
      puts 'Please read https://docs.gitlab.com/ee/administration/geo/'\
        'disaster_recovery/planned_failover.html#preflight-checks'
      puts
      puts 'Did you perform all manual preflight checks (y/n)?'.color(:green)

      return if STDIN.gets.chomp.casecmp('y').zero?

      raise 'ERROR: Manual preflight checks were not performed! '\
        'Please read https://docs.gitlab.com/ee/administration/geo/'\
        'disaster_recovery/planned_failover.html#preflight-checks'.color(:red)
    end

    def confirm_primary_is_down
      return true if @options[:confirm_primary_is_down]

      puts
      puts '---------------------------------------'.color(:yellow)
      puts 'WARNING: Make sure your primary is down'.color(:yellow)
      puts 'If you have more than one secondary please see '\
        'https://docs.gitlab.com/ee/gitlab-geo/disaster-recovery.html#'\
        'promoting-secondary-geo-replica-in-multi-secondary-configurations'.color(:yellow)
      puts 'There may be data saved to the primary that was not been '\
        'replicated to the secondary before the primary went offline. '\
        'This data should be treated as lost if you proceed.'.color(:yellow)
      puts '---------------------------------------'.color(:yellow)
      puts

      print '*** Is primary down? (N/y): '.color(:green)

      return if STDIN.gets.chomp.casecmp('y').zero?

      raise 'ERROR: Primary node must be down.'.color(:red)
    end

    def check_replication_verification_status
      puts
      puts 'Running gitlab-rake gitlab:geo:'\
        'check_replication_verification_status...'.color(:yellow)
      puts

      status = run_command('gitlab-rake gitlab:geo:check_replication_verification_status')
      puts status.stdout

      raise 'ERROR: Replication/verification is incomplete.' if status.error?
    end

    def success_message
      puts
      puts 'All preflight checks have passed.'\
        ' This node can now be promoted.'.color(:green)
    end

    def run_command(cmd)
      GitlabCtl::Util.run_command(cmd, live: true)
    end
  end
end
