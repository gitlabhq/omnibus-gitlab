require 'io/console'
require 'rainbow/ext/string'

module Geo
  class PromotionPreflightChecks
    def execute
      confirm_manual_checks
    rescue RuntimeError => e
      puts e.message
      exit 1
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
      puts '- Ensure Geo replication is up-to-date'
      puts '- Verify the integrity of replicated data'
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
  end
end
