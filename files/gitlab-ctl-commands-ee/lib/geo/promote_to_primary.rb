require 'io/console'
require 'rainbow/ext/string'

module Geo
  class PromoteToPrimary
    TRIGGER_FILE_PATH = '/tmp/postgresql.trigger'.freeze

    def initialize(base_path, options)
      @base_path = base_path
      @options = options
    end

    def execute
      make_sure_primary_is_down

      promote_postgresql_to_primary

      remove_ssh_keys

      reconfigure

      promote_to_primary
    end

    private

    def git_user_home
      GitlabCtl::Util.get_node_attributes(@base_path)['gitlab']['user']['home']
    end

    def make_sure_primary_is_down
      return true if @options[:confirm_primary_is_down]

      puts
      puts '---------------------------------------'.color(:yellow)
      puts 'WARNING: Make sure your primary is down and also be aware that'.color(:yellow)
      puts 'this command only works for setups with one secondary.'.color(:yellow)
      puts 'If you have more of them please see https://docs.gitlab.com/ee/gitlab-geo/disaster-recovery.md#promoting-secondary-geo-replica-in-multi-secondary-configurations'.color(:yellow)
      puts '---------------------------------------'.color(:yellow)
      puts

      print '*** Are you sure? (N/y): '.color(:green)

      unless STDIN.gets.chomp.downcase == 'y'
        raise 'Exited because primary node must be down'
      end
    end

    def promote_postgresql_to_primary
      puts
      puts 'Promoting the Postgres to primary...'.color(:yellow)
      puts

      run_command("touch #{TRIGGER_FILE_PATH}")
    end

    def remove_ssh_keys
      return nil unless File.exist?(key_path) || File.exist?(public_key_path)

      unless @options[:confirm_removing_keys]
        puts
        puts 'SSH keys detected! Remove? See https://docs.gitlab.com/ee/gitlab-geo/disaster-recovery.html#promoting-a-secondary-node for more information [Y/n]'.color(:yellow)

        if STDIN.gets.chomp.downcase == 'n'
          return true
        end
      end

      [key_path, public_key_path].each do |path|
        File.delete(path) if File.exist?(path)
      end
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

    def run_command(cmd, live: false)
      GitlabCtl::Util.run_command(cmd, live: live)
    end

    def key_path
      @key_path ||= File.join(git_user_home, '.ssh/id_rsa')
    end

    def public_key_path
      @public_key_path ||= File.join(git_user_home ,'.ssh/id_rsa.pub')
    end
  end
end
