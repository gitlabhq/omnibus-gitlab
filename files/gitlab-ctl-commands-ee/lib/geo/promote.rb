require 'io/console'
require 'rainbow/ext/string'

module Geo
  class Promote
    GEO_NODE_ROLES = %i[primary secondary].freeze
    PATRONI_NODE_ROLES = %i[leader replica standby_leader].freeze
    PATRONI_LEADER_ROLES = %i[leader standby_leader].freeze
    SERVICE_NAMES = %w[puma sidekiq postgresql patroni geo-logcursor geo-postgresql].freeze

    attr_accessor :base_path, :ctl, :options

    def initialize(ctl, options)
      @ctl = ctl
      @base_path = @ctl.base_path
      @options = options
    end

    def execute
      ask_for_confirmation
      check_running_services
      promote_database
      toggle_geo_services
      promote_to_primary
      run_reconfigure
      print_success_message
    end

    private

    def check_running_services
      unless progress_message('Checking if we need to promote any service running on this node') do
        SERVICE_NAMES.any? { |service| service_enabled?(service) }
      end
        print_no_actions_required_message
        exit 0
      end
    end

    def ask_for_confirmation
      return if options[:force]

      puts
      puts 'WARNING: Note that this command is not production-ready. Please read ' \
        'https://docs.gitlab.com/ee/administration/geo/disaster_recovery/planned_failover.html ' \
        'for further instructions.'.color(:red)

      puts
      puts 'WARNING: The current secondary node will now be promoted to a primary node. '\
        'Are you sure you want to proceed? (y/n)'.color(:yellow)

      return if $stdin.gets.chomp.casecmp('y').zero?

      exit 1
    end

    def promote_database
      promote_postgresql if pg_enabled?
      promote_patroni_standby_cluster if patroni_enabled?
    end

    def promote_postgresql
      log('Detected a PostgreSQL Standby server cluster.')

      promote_postgresql_read_write
    end

    def promote_postgresql_read_write
      return unless pg_is_in_recovery?

      progress_message('Promoting the PostgreSQL to end standby mode and begin read-write operations') do
        Geo::PromoteDb.new(ctl).execute
      end
    end

    def promote_patroni_standby_cluster
      promote_postgresql_read_write if patroni_leader?
      disable_patroni_standby_cluster
      run_reconfigure
    end

    def disable_patroni_standby_cluster
      unless progress_message('Disabling Patroni Standby server settings in the cluster configuration file') do
        GitlabCluster.config.set('patroni', 'standby_cluster', 'enable', false)
        GitlabCluster.config.save
      end
        die("Unable to write to #{GitlabCluster::JSON_FILE}.")
      end
    end

    def pause_patroni_cluster
      return unless patroni_enabled? && patroni_leader?

      unless progress_message('Disabling Patroni auto-failover') do
        run_command("#{base_path}/bin/gitlab-ctl patroni pause")
      end
        die('Unable to disable Patroni auto-failover')
      end
    end

    def resume_patroni_cluster
      return unless patroni_enabled? && patroni_leader?

      unless progress_message('Resuming Patroni auto-failover') do
        run_command("#{base_path}/bin/gitlab-ctl patroni resume")
      end
        die('Unable to resume Patroni auto-failover')
      end
    end

    def patroni_leader?
      @patroni_leader ||= PATRONI_LEADER_ROLES.include?(patroni_node_role)
    end

    def patroni_node_role
      return @patroni_node_role if defined?(@patroni_node_role)

      unless progress_message('Attempting to detect the role of this Patroni node') do
        node = Patroni::Client.new
        @patroni_node_role = :standby_leader if node.standby_leader?
        @patroni_node_role = :leader if node.leader?
        @patroni_node_role = :replica if node.replica?

        PATRONI_NODE_ROLES.include?(@patroni_node_role)
      end
        die('Unable to detect the role of this Patroni node.')
      end

      @patroni_node_role
    end

    def toggle_geo_services
      return unless puma_enabled? || sidekiq_enabled? || geo_logcursor_enabled? || geo_postgresql_enabled?

      log('Detected an application or a Sidekiq or a Geo log cursor or a Geo PostgreSQL node.')

      # The geo_secondary_role must not be used in a mutiple-server setup.
      # It is very convenient only for single-server Geo secondary sites.
      if single_server_site?
        GitlabCluster.config.set('primary', true)
        GitlabCluster.config.set('secondary', false)
      else
        GitlabCluster.config.set('geo_secondary', 'enable', false) if puma_enabled? || sidekiq_enabled?
        GitlabCluster.config.set('geo_logcursor', 'enable', false) if geo_logcursor_enabled?
        GitlabCluster.config.set('geo_postgresql', 'enable', false) if geo_postgresql_enabled?
      end

      unless progress_message('Disabling the secondary services and enabling the primary services in the cluster configuration file') do
        GitlabCluster.config.save
      end
        die("Unable to write to #{GitlabCluster::JSON_FILE}.")
      end
    end

    def promote_to_primary
      return unless puma_enabled? && secondary_node?

      log('Detected an application node.')

      unless progress_message('Promoting secondary site to primary site') do
        !run_task('geo:set_secondary_as_primary').error?
      end
        die("Unable to promote secondary site to primary site.")
      end
    end

    def secondary_node?
      node_role == :secondary
    end

    def node_role
      return @node_role if defined?(@node_role)

      unless progress_message('Attempting to detect the role of this Geo node') do
        cmd = run_runner("puts Gitlab::Geo.secondary?")

        @node_role =
          if cmd.stdout.strip.to_s == 'true'
            :secondary
          else
            :unknown
          end

        GEO_NODE_ROLES.include?(@node_role)
      end
        die('Unable to detect the role of this Geo node.')
      end

      @node_role
    end

    def run_reconfigure
      # If the current node is a Patorni leader, we need to enable Patroni
      # maintenance mode to prevent an automatic failover during reconfigure.
      pause_patroni_cluster

      progress_message('Running reconfigure to apply changes') do
        ctl.run_chef("#{base_path}/embedded/cookbooks/dna.json").success?
      end

      resume_patroni_cluster
    end

    def print_no_actions_required_message
      puts
      puts "The #{SERVICE_NAMES.join(' or ')} services are not enabled. No actions are required to promote this node.".color(:green)
    end

    def print_success_message
      puts
      puts 'You successfully promoted the current node!'.color(:green)
    end

    def pg_is_in_recovery?
      query = run_query('SELECT pg_is_in_recovery();')
      raise PgIsInRecoveryError, "Unable to check if PostgreSQL is in recovery #{query.stderr.strip}" if query.error?

      query.stdout.strip.to_s == 't'
    end

    def single_server_site?
      @single_server ||= GitlabCtl::Util.roles(base_path).include?('geo-secondary')
    end

    def geo_logcursor_enabled?
      @geo_logcursor_enabled ||= service_enabled?('geo-logcursor')
    end

    def geo_postgresql_enabled?
      @geo_postgresql_enabled ||= service_enabled?('geo-postgresql')
    end

    def patroni_enabled?
      @patroni_enabled ||= service_enabled?('patroni')
    end

    def pg_enabled?
      @pg_enabled ||= service_enabled?('postgresql')
    end

    def puma_enabled?
      @puma_enabled ||= service_enabled?('puma')
    end

    def sidekiq_enabled?
      @sidekiq_enabled ||= service_enabled?('sidekiq')
    end

    def service_enabled?(service)
      ctl.service_enabled?(service)
    end

    def progress_message(message, &block)
      GitlabCtl::Util.progress_message(message, &block)
    end

    def die(message)
      warn(message)
      exit 1
    end

    def log(*args)
      ctl.log(*args)
    end

    def attributes
      @attributes ||= GitlabCtl::Util.get_node_attributes(base_path)
    end

    def run_command(cmd, live: false)
      GitlabCtl::Util.run_command(cmd, live: live)
    end

    def run_query(query, live: false)
      run_command("#{base_path}/bin/gitlab-psql -c \"#{query}\" -q -t", live: live)
    end

    def run_runner(cmd, live: false)
      run_command("#{base_path}/bin/gitlab-rails runner \"#{cmd}\"", live: live)
    end

    def run_task(task, live: false)
      run_command("#{base_path}/bin/gitlab-rake #{task}", live: live)
    end
  end

  PgIsInRecoveryError = Class.new(StandardError)
end
