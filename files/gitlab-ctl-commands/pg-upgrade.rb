#
# Copyright:: Copyright (c) 2016 GitLab Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rainbow'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql"

INST_DIR = "#{base_path}/embedded/postgresql".freeze
REVERT_VERSION_FILE = "#{data_path}/postgresql-version.old".freeze

add_command_under_category 'revert-pg-upgrade', 'database',
                           'Run this to revert to the previous version of the database',
                           2 do |_cmd_name|
  begin
    options = GitlabCtl::PgUpgrade.parse_options(ARGV)
  rescue ArgumentError => e
    log "Command line parameter error: #{e.message}"
    Kernel.exit 64
  end

  revert_version = lookup_version(options[:target_version], read_revert_version || default_version)

  @attributes = GitlabCtl::Util.get_node_attributes(base_path)
  patroni_enabled = service_enabled?('patroni')
  pg_enabled = service_enabled?('postgresql')
  geo_pg_enabled = service_enabled?('geo-postgresql')

  @db_service_name = patroni_enabled ? 'patroni' : 'postgresql'
  db_worker = GitlabCtl::PgUpgrade.new(
    base_path,
    data_path,
    revert_version,
    options[:tmp_dir],
    options[:timeout]
  )

  if geo_pg_enabled
    geo_db_worker = GitlabCtl::PgUpgrade.new(
      base_path,
      data_path,
      revert_version,
      options[:tmp_dir],
      options[:timeout]
    )
    geo_db_worker.data_dir = @attributes['gitlab']['geo-postgresql']['data_dir']
    geo_db_worker.tmp_data_dir = "#{geo_db_worker.tmp_dir}/geo-data" unless geo_db_worker.tmp_dir.nil?
    geo_db_worker.psql_command = 'gitlab-geo-psql'
  end

  if GitlabCtl::Util.progress_message('Checking if we need to downgrade') do
    (!(pg_enabled || patroni_enabled) || db_worker.fetch_data_version == revert_version.major) && \
        (!geo_pg_enabled || geo_db_worker.fetch_data_version == revert_version.major) && \
        db_worker.initial_version == revert_version
  end
    log "Already running #{revert_version}"
    Kernel.exit 1
  end

  maintenance_mode('enable') unless patroni_enabled

  unless Dir.exist?("#{db_worker.tmp_data_dir}.#{revert_version.major}")
    if !geo_pg_enabled || !Dir.exist?("#{geo_db_worker.tmp_data_dir}.#{revert_version.major}")
      log "#{db_worker.tmp_data_dir}.#{revert_version.major} does not exist, cannot revert data"
      log "#{geo_db_worker.tmp_data_dir}.#{revert_version.major} does not exist, cannot revert data" if geo_pg_enabled
      log 'Will proceed with reverting the running program version only, unless you interrupt'
    end
  end

  if patroni_enabled
    @db_worker = db_worker
    patroni_preflight_check(options)
  end

  log "Reverting database to #{revert_version} in 5 seconds"
  log '=== WARNING ==='
  log 'This will revert the database to what it was before you upgraded, including the data.'
  log "Please hit Ctrl-C now if this isn't what you were looking for"
  log '=== WARNING ==='
  begin
    sleep 5
  rescue Interrupt
    log 'Received interrupt, not doing anything'
    Kernel.exit 0
  end

  if patroni_enabled
    log '== Reverting =='
    if @instance_type == :patroni_leader
      patroni_leader_downgrade(revert_version)
    else
      patroni_replica_downgrade(revert_version)
    end
    log '== Reverted =='
  elsif pg_enabled
    @db_worker = db_worker
    revert(revert_version)
  end

  if geo_pg_enabled
    @db_service_name = 'geo-postgresql'
    @db_worker = geo_db_worker
    revert(revert_version)
  end

  clean_revert_version
  maintenance_mode('disable') unless patroni_enabled
end

add_command_under_category 'pg-upgrade', 'database',
                           'Upgrade the PostgreSQL DB to the latest supported version',
                           2 do |_cmd_name|
  options = GitlabCtl::PgUpgrade.parse_options(ARGV)

  patroni_enabled = service_enabled?('patroni')
  pg_enabled = service_enabled?('postgresql')
  geo_enabled = service_enabled?('geo-postgresql')

  @db_service_name = patroni_enabled ? 'patroni' : 'postgresql'
  @db_worker = GitlabCtl::PgUpgrade.new(
    base_path,
    data_path,
    lookup_version(options[:target_version], default_version),
    options[:tmp_dir],
    options[:timeout]
  )
  @instance_type = :single_node
  @roles = GitlabCtl::Util.roles(base_path)
  @attributes = GitlabCtl::Util.get_node_attributes(base_path)

  unless GitlabCtl::Util.progress_message(
    'Checking for an omnibus managed postgresql') do
      !@db_worker.initial_version.nil? && \
          (pg_enabled || patroni_enabled || service_enabled?('geo-postgresql'))
    end
    $stderr.puts 'No currently installed postgresql in the omnibus instance found.'
    Kernel.exit 0
  end

  unless GitlabCtl::Util.progress_message(
    "Checking if postgresql['version'] is set"
  ) do
    @attributes['postgresql']['version'].nil?
  end
    log "postgresql['version'] is set in /etc/gitlab/gitlab.rb. Not checking for a PostgreSQL upgrade"
    deprecation_message if @attributes['postgresql']['version'].to_f < 11
    Kernel.exit 0
  end

  if GitlabCtl::Util.progress_message('Checking if we already upgraded') do
    @db_worker.initial_version.major.to_f >= @db_worker.target_version.major.to_f
  end
    $stderr.puts "The latest version #{@db_worker.initial_version} is already running, nothing to do"
    Kernel.exit 0
  end

  log 'Checking for a newer version of PostgreSQL to install'
  if @db_worker.target_version && Dir.exist?("#{INST_DIR}/#{@db_worker.target_version.major}")
    log "Upgrading PostgreSQL to #{@db_worker.target_version}"
  else
    $stderr.puts 'No new version of PostgreSQL installed, nothing to upgrade to'
    Kernel.exit 0
  end

  deprecation_message if @db_worker.target_version.major.to_f < 11

  unless options[:skip_disk_check]
    check_dirs = [@db_worker.tmp_dir]
    check_dirs << @db_worker.data_dir if pg_enabled || patroni_enabled
    check_dirs << @attributes['gitlab']['geo-postgresql']['data_dir'] if geo_enabled

    check_dirs.compact.uniq.each do |dir|
      unless GitlabCtl::Util.progress_message(
        "Checking if disk for directory #{dir} has enough free space for PostgreSQL upgrade"
      ) do
        @db_worker.enough_free_space?(dir)
      end
        log "Upgrade requires #{@db_worker.space_needed(dir)}MB, but only #{@db_worker.space_free(dir)}MB is free."
        Kernel.exit 1
      end
      next
    end
  end

  unless GitlabCtl::Util.progress_message(
    'Checking if PostgreSQL bin files are symlinked to the expected location'
  ) do
    Dir.glob("#{INST_DIR}/#{@db_worker.initial_version.major}/bin/*").each do |bin_file|
      link = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
      File.symlink?(link) && File.readlink(link).eql?(bin_file)
    end
  end
    log "#{link} is not linked to #{bin_file}, unable to proceed with non-standard installation"
    Kernel.exit 1
  end

  # The current instance needs to be running, start it if it isn't
  if pg_enabled && !@db_worker.running?
    log 'Starting the database'

    begin
      @db_worker.start
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      log "Error starting the database. Please fix the error before continuing"
      log e.message
      Kernel.exit 1
    end
  end

  if service_enabled?('geo-postgresql') && !@db_worker.running?('geo-postgresql')
    log 'Starting the geo database'

    begin
      @db_worker.start('geo-postgresql')
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      log "Error starting the geo database. Please fix the error before continuing"
      log e.message
      Kernel.exit 1
    end
  end

  patroni_preflight_check(options) if patroni_enabled

  if options[:wait]
    # Wait for processes to settle, and give use one last chance to change their
    # mind
    log "Waiting 30 seconds to ensure tasks complete before PostgreSQL upgrade."
    log "See https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server for details"
    log "If you do not want to upgrade the PostgreSQL server at this time, enter Ctrl-C and see the documentation for details"
    status = GitlabCtl::Util.delay_for(30)
    unless status
      maintenance_mode('disable') unless patroni_enabled
      Kernel.exit(0)
    end
  end

  if patroni_enabled
    if @instance_type == :patroni_leader
      patroni_leader_upgrade
    else
      patroni_replica_upgrade
    end
  elsif service_enabled?('repmgrd')
    log "Detected an HA cluster."
    node = RepmgrHandler::Node.new
    if node.is_master?
      log "Primary node detected."
      @instance_type = :pg_primary
      general_upgrade
    else
      log "Secondary node detected."
      @instance_type = :pg_secondary
      ha_secondary_upgrade(options)
    end
  elsif @roles.include?('geo-primary')
    log 'Detected a GEO primary node'
    @instance_type = :geo_primary
    general_upgrade
  elsif @roles.include?('geo-secondary') || service_enabled?('geo-postgresql')
    log 'Detected a GEO secondary node'
    @instance_type = :geo_secondary
    geo_secondary_upgrade(options[:tmp_dir], options[:timeout])
  else
    general_upgrade
  end
end

def common_pre_upgrade(enable_maintenance = true)
  maintenance_mode('enable') if enable_maintenance

  locale, collate, encoding = get_locale_encoding

  stop_database
  create_links(@db_worker.target_version)
  create_temp_data_dir
  initialize_new_db(locale, collate, encoding)
end

def common_post_upgrade(disable_maintenance = true)
  cleanup_data_dir

  if @db_service_name == 'patroni'
    copy_patroni_dynamic_config
    start_database
  end

  configure_postgresql

  log 'Running reconfigure to re-generate any dependent service configuration'
  run_reconfigure

  restart_patroni_node if @db_service_name == 'patroni'

  log "Waiting for Database to be running."
  if @db_service_name == 'geo-postgresql'
    GitlabCtl::PostgreSQL.wait_for_postgresql(120, psql_command: 'gitlab-geo-psql')
  else
    GitlabCtl::PostgreSQL.wait_for_postgresql(120)
  end

  unless [:pg_secondary, :geo_secondary, :patroni_replica].include?(@instance_type)
    log 'Database upgrade is complete, running vacuumdb analyze'
    analyze_cluster
  end

  maintenance_mode('disable') if disable_maintenance
  goodbye_message
end

def ha_secondary_upgrade(options)
  promote_database
  restart_database
  if options[:skip_unregister]
    log "Not attempting to unregister secondary node due to --skip-unregister flag"
  else
    log "Unregistering secondary node from cluster"
    RepmgrHandler::Standby.unregister({})
  end

  common_pre_upgrade
  common_post_upgrade
end

def general_upgrade
  common_pre_upgrade
  begin
    @db_worker.run_pg_upgrade
  rescue GitlabCtl::Errors::ExecutionError
    die "Error running pg_upgrade, please check logs"
  end
  common_post_upgrade
end

def patroni_leader_upgrade
  common_pre_upgrade(false)
  begin
    @db_worker.run_pg_upgrade
  rescue GitlabCtl::Errors::ExecutionError
    die 'Error running pg_upgrade, please check logs'
  end
  remove_patroni_cluster_state
  common_post_upgrade(false)
end

def patroni_replica_upgrade
  stop_database
  create_links(@db_worker.target_version)
  common_post_upgrade(false)
end

def patroni_leader_downgrade(revert_version)
  stop_database
  create_links(revert_version)
  revert_data_dir(revert_version)
  remove_patroni_cluster_state
  start_database
  configure_postgresql
  restart_patroni_node
end

def patroni_replica_downgrade(revert_version)
  stop_database
  create_links(revert_version)
  revert_data_dir(revert_version)
  start_database
  configure_postgresql
  restart_patroni_node
end

def configure_postgresql
  log 'Configuring PostgreSQL'
  status = GitlabCtl::Util.chef_run('solo.rb', "#{@db_service_name}-config.json")
  $stdout.puts status.stdout
  if status.error?
    $stderr.puts '===STDERR==='
    $stderr.puts status.stderr
    $stderr.puts '======'
    die 'Error updating PostgreSQL configuration. Please check the output'
  end

  restart_database
end

def start_database
  sv_progress('start', @db_service_name)
end

def stop_database
  sv_progress('stop', @db_service_name)
end

def restart_database
  sv_progress('restart', @db_service_name)
end

def sv_progress(action, service)
  GitlabCtl::Util.progress_message("Running #{action} on #{service}") do
    run_sv_command_for_service(action, service)
  end
end

def promote_database
  log 'Promoting the database'
  @db_worker.run_pg_command(
    "#{base_path}/embedded/bin/pg_ctl -D #{@db_worker.data_dir} promote"
  )
end

def geo_secondary_upgrade(tmp_dir, timeout)
  pg_enabled = service_enabled?('postgresql')
  geo_pg_enabled = service_enabled?('geo-postgresql')

  # Run the first time to link the primary postgresql instance
  if pg_enabled
    log('Upgrading the postgresql database')
    begin
      promote_database
    rescue GitlabCtl::Errors::ExecutionError
      die "There was an error promoting the database. Please check the logs"
    end

    # Restart the database after promotion, and wait for it to be ready
    restart_database
    GitlabCtl::PostgreSQL.wait_for_postgresql(600)

    common_pre_upgrade

    # Only disable maintenance_mode if geo-pg is not enabled
    common_post_upgrade(!geo_pg_enabled)
  end

  return unless geo_pg_enabled

  # Update the location to handle the geo-postgresql instance
  log('Upgrading the geo-postgresql database')
  # Secondary nodes have a replica db under /var/opt/gitlab/postgresql that needs
  # the bin files updated and the geo tracking db under /var/opt/gitlab/geo-postgresl that needs data updated
  data_dir = @attributes['gitlab']['geo-postgresql']['data_dir']

  @db_service_name = 'geo-postgresql'
  @db_worker.data_dir = data_dir
  @db_worker.tmp_data_dir = @db_worker.tmp_dir.nil? ? data_dir : "#{@db_worker.tmp_dir}/geo-data"
  @db_worker.psql_command = 'gitlab-geo-psql'
  common_pre_upgrade
  begin
    @db_worker.run_pg_upgrade
  rescue GitlabCtl::Errors::ExecutionError
    die "Error running pg_upgrade on secondary, please check logs"
  end
  common_post_upgrade
end

def get_locale_encoding
  begin
    locale = @db_worker.fetch_lc_ctype
    collate = @db_worker.fetch_lc_collate
    encoding = @db_worker.fetch_server_encoding
  rescue GitlabCtl::Errors::ExecutionError => e
    log 'There was an error fetching locale and encoding information from the database'
    log 'Please ensure the database is running and functional before running pg-upgrade'
    log "STDOUT: #{e.stdout}"
    log "STDERR: #{e.stderr}"
    die 'Please check error logs'
  end

  [locale, collate, encoding]
end

def create_temp_data_dir
  unless GitlabCtl::Util.progress_message('Creating temporary data directory') do
    begin
      @db_worker.run_pg_command(
        "mkdir -p #{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major}"
      )
    rescue GitlabCtl::Errors::ExecutionError => e
      log "Error creating new directory: #{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major}"
      log "STDOUT: #{e.stdout}"
      log "STDERR: #{e.stderr}"
      false
    else
      true
    end
  end
    die 'Please check the output'
  end
end

def initialize_new_db(locale, collate, encoding)
  unless GitlabCtl::Util.progress_message('Initializing the new database') do
    begin
      @db_worker.run_pg_command(
        "#{@db_worker.target_version_path}/bin/initdb " \
        "-D #{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major} " \
        "--locale #{locale} " \
        "--encoding #{encoding} " \
        " --lc-collate=#{collate} " \
        "--lc-ctype=#{locale}"
      )
    rescue GitlabCtl::Errors::ExecutionError => e
      log "Error initializing database for #{@db_worker.target_version}"
      log "STDOUT: #{e.stdout}"
      log "STDERR: #{e.stderr}"
      die 'Please check the output and try again'
    end
  end
    die 'Error initializing new database'
  end
end

def cleanup_data_dir
  unless GitlabCtl::Util.progress_message('Move the old data directory out of the way') do
    run_command(
      "mv #{@db_worker.data_dir} #{@db_worker.tmp_data_dir}.#{@db_worker.initial_version.major}"
    )
  end
    die 'Error moving data for older version, '
  end

  if @instance_type == :patroni_replica
    unless GitlabCtl::Util.progress_message('Recreating an empty data directory') do
      run_command("mkdir -p #{@db_worker.data_dir}")
    end
      die "Error refreshing #{@db_worker.data_dir}"
    end
  else
    unless GitlabCtl::Util.progress_message('Rename the new data directory') do
      run_command(
        "mv #{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major} #{@db_worker.data_dir}"
      )
    end
      die "Error moving #{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major} to #{@db_worker.data_dir}"
    end
  end

  unless GitlabCtl::Util.progress_message('Saving the old version information') do
    save_revert_version
  end
    die
  end
end

def run_reconfigure
  unless GitlabCtl::Util.progress_message('Running reconfigure') do
    run_chef("#{base_path}/embedded/cookbooks/dna.json").success?
  end
    die 'Something went wrong during final reconfiguration, please check the output'
  end
end

def analyze_cluster
  pg_username = @attributes.dig(:gitlab, :postgresql, :username) || @attributes.dig(:postgresql, :username)
  pg_host = @attributes.dig(:gitlab, :postgresql, :unix_socket_directory) || @attributes.dig(:postgresql, :unix_socket_directory)
  analyze_cmd = "#{@db_worker.target_version_path}/bin/vacuumdb -j2 --all --analyze-in-stages -h #{pg_host} -p #{@db_worker.port}"
  begin
    @db_worker.run_pg_command(analyze_cmd)
  rescue GitlabCtl::Errors::ExecutionError => e
    log "Error running #{analyze_cmd}"
    log "STDOUT: #{e.stdout}"
    log "STDERR: #{e.stderr}"
    log 'Please check the output, and rerun the command as root or with sudo if needed:'
    log "sudo su - #{pg_username} -c \"#{analyze_cmd}\""
    log 'If the error persists, please open an issue at: '
    log 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
  rescue Mixlib::ShellOut::CommandTimeout
    $stderr.puts "Time out while running the analyze stage.".color(:yellow)
    $stderr.puts "Please re-run the command manually as the #{pg_username} user".color(:yellow)
    $stderr.puts analyze_command.color(:yellow)
  end
end

def patroni_preflight_check(options)
  log 'Detected a Patroni cluster.'

  @instance_type = (:patroni_leader if options[:leader]) || (:patroni_replica if options[:replica])
  guess_patroni_node_role unless @instance_type

  check_patroni_cluster_status

  if @instance_type == :patroni_leader
    log "Using #{Rainbow('leader').yellow} node upgrade procedure."
  else
    log "Using #{Rainbow('replica').yellow} node upgrade procedure."
    log Rainbow('This procedure REMOVES DATA directory.').yellow
  end
end

def guess_patroni_node_role
  failure_cause = :none
  unless GitlabCtl::Util.progress_message('Attempting to detect the role of this Patroni node') do
    begin
      node = Patroni::Client.new
      scope = @attributes.dig(:patroni, :scope)
      node_name = @attributes.dig(:patroni, :name)

      if node.up?
        @instance_type = :patroni_leader if node.leader?
        @instance_type = :patroni_replica if node.replica?
        failure_cause = :patroni_running_on_replica if @instance_type == :patroni_replica
        @instance_type == :patroni_leader
      else
        leader_name = GitlabCtl::Util.get_command_output("#{base_path}/embedded/bin/consul kv get /service/#{scope}/leader").strip
        @instance_type = node_name == leader_name ? :patroni_leader : :patroni_replica unless leader_name.nil? || leader_name.empty?
        failure_cause = :patroni_stopped_on_leader if @instance_type == :patroni_leader
        @instance_type == :patroni_replica
      end
    rescue GitlabCtl::Errors::ExecutionError => e
      log 'Unable to get the role of the Patroni node from Consul'
      log "STDOUT: #{e.stdout}"
      log "STDERR: #{e.stderr}"
      false
    end
  end
    case failure_cause
    when :patroni_running_on_replica
      log 'Looks like that this is a replica node but the Patroni service is still running.'
      log 'Try to stop the Patroni service before attempting the upgrade.'

      die 'Patroni service is still running on the replica node.'
    when :patroni_stopped_on_leader
      log 'Looks like that this is the leader node but the Patroni is not running.'
      log 'Try to start the Patroni service before attempting the upgrade.'

      die 'Patroni service is not running on the leader node.'
    else
      log 'Unable to detect the role of this Patroni node.'
      log 'Try to use --leader or --replica switches to specify the role manually.'
      log 'See: https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#upgrading-postgresql-major-version-in-a-patroni-cluster'

      die 'Unable to detect the role of this Patroni node.'
    end
  end
end

def check_patroni_cluster_status
  # If the client can be created then it means that the
  # required node attributes are stored correctly.
  node = Patroni::Client.new

  return unless @instance_type == :patroni_leader

  die 'Patroni service is not running on the leader node.' unless node.up?

  running_replica_count = 0
  node.cluster_status[:members]&.each do |member|
    running_replica_count += 1 if member[:state] == 'running' && member[:role] == 'replica'
  end
  log Rainbow("WARNING: Looks like that at least one replica node is running.\n" \
              "         It is strongly recommended to shutdown all replicas\n" \
              "         before upgrading the cluster.").yellow if running_replica_count.positive?
end

def remove_patroni_cluster_state
  scope = @attributes.dig(:patroni, :scope) || ''
  unless !scope.empty? && GitlabCtl::Util.progress_message('Wiping Patroni cluster state') do
    run_command("#{base_path}/embedded/bin/consul kv delete -recurse /service/#{scope}/")
  end
    die 'Unable to wipe the cluster state'
  end
end

def restart_patroni_node
  name = @attributes.dig(:patroni, :name) || ''
  scope = @attributes.dig(:patroni, :scope) || ''
  unless !name.empty? && !scope.empty? && GitlabCtl::Util.progress_message("Restarting Patroni on this node\n") do
    patroni_dir = @attributes.dig(:patroni, :dir) || '/var/opt/gitlab/patroni'
    run_command("#{base_path}/embedded/bin/patronictl -c #{patroni_dir}/patroni.yaml restart --force #{scope} #{name}")
  end
    die 'Unable to wipe the cluster state'
  end
end

def copy_patroni_dynamic_config
  src = "#{@db_worker.data_dir}/patroni.dynamic.json"
  dst = "#{@db_worker.tmp_data_dir}.#{@db_worker.target_version.major}/patroni.dynamic.json"
  FileUtils.copy_file(src, dst, true) if File.exist?(src) && !File.exist?(dst)
end

def version_from_manifest(software)
  @versions = JSON.parse(File.read("#{base_path}/version-manifest.json")) if @versions.nil?
  return @versions['software'][software]['described_version'] if @versions['software'].key?(software)

  nil
end

def old_version
  PGVersion.parse(version_from_manifest('postgresql_old')) || PGVersion.parse(version_from_manifest('postgresql'))
end

def default_version
  PGVersion.parse(version_from_manifest('postgresql'))
end

def new_version
  PGVersion.parse(version_from_manifest('postgresql_new')) || PGVersion.parse(version_from_manifest('postgresql'))
end

SUPPORTED_VERSIONS = [old_version, default_version, new_version].freeze

def lookup_version(major_version, fallback_version)
  return fallback_version unless major_version

  target_version = SUPPORTED_VERSIONS.select { |v| v.major == major_version }

  if target_version.empty?
    log "The specified major version #{major_version} is not supported. Choose from one of #{SUPPORTED_VERSIONS.map(&:major).uniq.join(', ')}."
    Kernel.exit 1
  else
    target_version[0]
  end
end

def create_links(version)
  GitlabCtl::Util.progress_message('Symlink correct version of binaries') do
    Dir.glob("#{INST_DIR}/#{version.major}/bin/*").each do |bin_file|
      destination = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
      GitlabCtl::Util.get_command_output("ln -sf #{bin_file} #{destination}")
    end
  end
end

def revert(version)
  log '== Reverting =='
  run_sv_command_for_service('stop', @db_service_name)
  revert_data_dir(version)
  create_links(version)
  run_sv_command_for_service('start', @db_service_name)
  log'== Reverted =='
end

def revert_data_dir(version)
  if @instance_type == :patroni_replica
    run_command("rm -rf #{@db_worker.data_dir}")
    run_command("mkdir #{@db_worker.data_dir}")
    return
  end

  return unless Dir.exist?("#{@db_worker.tmp_data_dir}.#{version.major}")

  run_command("rm -rf #{@db_worker.data_dir}")
  run_command(
    "mv #{@db_worker.tmp_data_dir}.#{version.major} #{@db_worker.data_dir}"
  )
end

def maintenance_mode(command)
  # In order for the deploy page to work, we need nginx, unicorn, redis, and
  # gitlab-workhorse running
  # We'll manage postgresql and patroni during the upgrade process
  omit_services = %w(postgresql geo-postgresql patroni consul nginx unicorn puma redis gitlab-workhorse)
  if command.eql?('enable')
    dp_cmd = 'up'
    sv_cmd = 'stop'
  elsif command.eql?('disable')
    dp_cmd = 'down'
    sv_cmd = 'start'
  else
    raise StandardError("Cannot handle command #{command}")
  end
  GitlabCtl::Util.progress_message('Toggling deploy page') do
    run_command("#{base_path}/bin/gitlab-ctl deploy-page #{dp_cmd}")
  end
  GitlabCtl::Util.progress_message('Toggling services') do
    get_all_services.select { |x| !omit_services.include?(x) }.each do |svc|
      run_sv_command_for_service(sv_cmd, svc)
    end
  end
end

def die(message)
  $stderr.puts '== Fatal error =='
  $stderr.puts message
  revert(@db_worker.initial_version)
  $stderr.puts "== Reverted to #{@db_worker.initial_version}. Please check output for what went wrong =="
  maintenance_mode('disable') unless service_enabled?('patroni')
  exit 1
end

def read_revert_version
  File.exist?(REVERT_VERSION_FILE) ? PGVersion.parse(File.read(REVERT_VERSION_FILE)) : nil
end

def save_revert_version
  File.write(REVERT_VERSION_FILE, @db_worker.initial_version)
end

def clean_revert_version
  File.delete(REVERT_VERSION_FILE) if File.exist? REVERT_VERSION_FILE
end

def goodbye_message
  log '==== Upgrade has completed ===='
  log 'Please verify everything is working and run the following if so'
  log "sudo rm -rf #{@db_worker.tmp_data_dir}.#{@db_worker.initial_version.major}"
  log "sudo rm -f #{REVERT_VERSION_FILE}"
  log ""

  case @instance_type
  when :pg_secondary
    log "As part of PostgreSQL upgrade, this secondary node was removed from"
    log "the HA cluster. Once the primary node is upgraded to new version of"
    log "PostgreSQL, you will have to configure this secondary node to follow"
    log "the primary node again."
    log "Check https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster for details."
  when :pg_primary

    log "As part of PostgreSQL upgrade, the secondary nodes were removed from"
    log "the HA cluster. So right now, the cluster has only a single node in"
    log "it - the primary node."
    log "Now the primary node has been upgraded to new version of PostgreSQL,"
    log "you may go ahead and configure the secondary nodes to follow this"
    log "primary node."
    log "Check https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster for details."
  when :geo_primary, :geo_secondary
    log 'As part of the PostgreSQL upgrade, replication between primary and secondary has'
    log 'been shut down. After the secondary has been upgraded, it needs to be re-initialized'
    log 'Please see the instructions at https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance'
  end
end

def deprecation_message
  log '=== WARNING ==='
  log 'Note that PostgreSQL 11 will become the minimum required PostgreSQL version in GitLab 13.0 (May 2020).'
  log 'PostgreSQL 9.6 and PostgreSQL 10 will be removed in GitLab 13.0.'
  log 'To upgrade, please see: https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server'
  log '=== WARNING ==='
end
