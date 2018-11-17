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

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"

INST_DIR = "#{base_path}/embedded/postgresql".freeze

add_command_under_category 'revert-pg-upgrade', 'database',
                           'Run this to revert to the previous version of the database',
                           2 do |_cmd_name|
  options = GitlabCtl::PgUpgrade.parse_options(ARGV)
  @db_worker = GitlabCtl::PgUpgrade.new(base_path, data_path, options[:tmp_dir])

  maintenance_mode('enable')

  if progress_message('Checking if we need to downgrade') do
    @db_worker.fetch_running_version == default_version
  end
    log "Already running #{default_version}"
    Kernel.exit 1
  end

  unless Dir.exist?("#{@db_worker.tmp_data_dir}.#{default_version.major}")
    log "#{@db_worker.tmp_data_dir}.#{default_version} does not exist, cannot revert data"
    log 'Will proceed with reverting the running program version only, unless you interrupt'
  end

  log "Reverting database to #{default_version} in 5 seconds"
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
  revert
  maintenance_mode('disable')
end

add_command_under_category 'pg-upgrade', 'database',
                           'Upgrade the PostgreSQL DB to the latest supported version',
                           2 do |_cmd_name|
  options = GitlabCtl::PgUpgrade.parse_options(ARGV)
  @db_worker = GitlabCtl::PgUpgrade.new(base_path, data_path, options[:tmp_dir])

  running_version = @db_worker.fetch_running_version

  unless progress_message(
    'Checking for an omnibus managed postgresql') do
      !running_version.nil? && \
          get_all_services.member?('postgresql')
    end
    $stderr.puts 'No currently installed postgresql in the omnibus instance found.'
    Kernel.exit 0
  end

  log 'Checking for a newer version of PostgreSQL to install'
  if upgrade_version && Dir.exist?("#{INST_DIR}/#{upgrade_version.major}")
    log "Upgrading PostgreSQL to #{upgrade_version}"
  else
    $stderr.puts 'No new version of PostgreSQL installed, nothing to upgrade to'
    Kernel.exit 0
  end

  if progress_message('Checking if we already upgraded') do
    running_version == upgrade_version
  end
    $stderr.puts "The latest version #{upgrade_version} is already running, nothing to do"
    Kernel.exit 0
  end

  unless progress_message(
    'Checking if PostgreSQL bin files are symlinked to the expected location'
  ) do
    Dir.glob("#{INST_DIR}/#{running_version.major}/bin/*").each do |bin_file|
      link = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
      File.symlink?(link) && File.readlink(link).eql?(bin_file)
    end
  end
    log "#{link} is not linked to #{bin_file}, unable to proceed with non-standard installation"
    Kernel.exit 1
  end

  # The current instance needs to be running, start it if it isn't
  unless @db_worker.running?
    log 'Starting the database'

    begin
      @db_worker.start
    rescue Mixlib::ShellOut::ShellCommandFailed => scf
      log "Error starting the database. Please fix the error before continuing"
      log scf.message
      Kernel.exit 1
    end
  end

  # All tests have passed, this should be an upgradable instance.
  maintenance_mode('enable')

  # Wait for processes to settle, and give use one last chance to change their
  # mind
  log "Waiting 30 seconds to ensure tasks complete before PostgreSQL upgrade."
  status = GitlabCtl::Util.delay_for(30) if options[:wait]
  unless status
    maintenance_mode('disable')
    Kernel.exit(0)
  end

  # Get the existing locale before we move on
  begin
    locale = @db_worker.fetch_lc_collate
    encoding = @db_worker.fetch_server_encoding
  rescue GitlabCtl::Errors::ExecutionError => ee
    log 'There wasn an error fetching locale and encoding information from the database'
    log 'Please ensure the database is running and functional before running pg-upgrade'
    log "STDOUT: #{ee.stdout}"
    log "STDERR: #{ee.stderr}"
  end

  # Ensure tmp_data_dir and data_dir are set before the database is stopped
  @db_worker.tmp_data_dir

  progress_message('Stopping the database') do
    run_sv_command_for_service('stop', 'postgresql')
  end

  progress_message('Update the symlinks') do
    create_links(upgrade_version)
  end

  unless progress_message('Creating temporary data directory') do
    begin
      @db_worker.run_pg_command(
        "mkdir -p #{@db_worker.tmp_data_dir}.#{upgrade_version.major}"
      )
    rescue GitlabCtl::Errors::ExecutionError => ee
      log "Error creating new directory: #{@db_worker.tmp_data_dir}.#{upgrade_version.major}"
      log "STDOUT: #{ee.stdout}"
      log "STDERR: #{ee.stderr}"
      false
    else
      true
    end
  end
    die 'Please check the output'
  end

  unless progress_message('Initializing the new database') do
    begin
      @db_worker.run_pg_command(
        "#{base_path}/embedded/bin/initdb " \
        "-D #{@db_worker.tmp_data_dir}.#{upgrade_version.major} " \
        "--locale #{locale} " \
        "--encoding #{encoding} " \
        " --lc-collate=#{locale} " \
        "--lc-ctype=#{locale}"
      )
    rescue GitlabCtl::Errors::ExecutionError => ee
      log "Error initializing database for #{upgrade_version}"
      log "STDOUT: #{ee.stdout}"
      log "STDERR: #{ee.stderr}"
      die 'Please check the output and try again'
    end
  end
    die 'Error initializing new database'
  end

  unless progress_message('Upgrading the data') do
    begin
      @db_worker.run_pg_command(
        "#{base_path}/embedded/bin/pg_upgrade " \
        "-b #{base_path}/embedded/postgresql/#{default_version.major}/bin " \
        "-d #{@db_worker.data_dir} " \
        "-D #{@db_worker.tmp_data_dir}.#{upgrade_version.major} " \
        "-B #{base_path}/embedded/bin"
      )
    rescue GitlabCtl::Errors::ExecutionError => ee
      log "Error upgrading the data to version #{upgrade_version}"
      log "STDOUT: #{ee.stdout}"
      log "STDERR: #{ee.stderr}"
      false
    end
  end
    die 'Error upgrading the database'
  end

  unless progress_message('Move the old data directory out of the way') do
    run_command(
      "mv #{@db_worker.data_dir} #{@db_worker.tmp_data_dir}.#{default_version.major}"
    )
  end
    die 'Error moving data for older version, '
  end

  unless progress_message('Rename the new data directory') do
    run_command(
      "mv #{@db_worker.tmp_data_dir}.#{upgrade_version.major} #{@db_worker.data_dir}"
    )
  end
    die "Error moving #{@db_worker.tmp_data_dir}.#{upgrade_version.major} to #{@db_worker.data_dir}"
  end

  log 'Upgrade is complete, doing post configuration steps'
  unless progress_message('Running reconfigure') do
    run_chef("#{base_path}/embedded/cookbooks/dna.json").success?
  end
    die 'Something went wrong during final reconfiguration, please check the output'
  end
  log 'Database upgrade is complete, running analyze_new_cluster.sh'
  analyze_script = File.join(
    File.dirname(@db_worker.default_data_dir),
    'analyze_new_cluster.sh'
  )
  begin
    @db_worker.run_pg_command("/bin/sh #{analyze_script}")
  rescue GitlabCtl::Errors::ExecutionError => ee
    log 'Error running analyze_new_cluster.sh'
    log "STDOUT: #{ee.stdout}"
    log "STDERR: #{ee.stderr}"
    log 'Please check the output, and rerun the command if needed:'
    log "/bin/sh #{analyze_script}"
    log 'If the error persists, please open an issue at: '
    log 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
  end
  log '==== Upgrade has completed ===='
  log 'Please verify everything is working and run the following if so'
  log "rm -rf #{@db_worker.tmp_data_dir}.#{default_version.major}"
  maintenance_mode('disable')
  Kernel.exit 0
end

def version_from_manifest(software)
  if @versions.nil?
    @versions = JSON.parse(File.read("#{base_path}/version-manifest.json"))
  end
  if @versions['software'].key?(software)
    return @versions['software'][software]['described_version']
  end
  nil
end

def default_version
  PGVersion.parse(version_from_manifest('postgresql'))
end

def upgrade_version
  PGVersion.parse(version_from_manifest('postgresql_new'))
end

def create_links(version)
  Dir.glob("#{INST_DIR}/#{version.major}/bin/*").each do |bin_file|
    destination = "#{base_path}/embedded/bin/#{File.basename(bin_file)}"
    GitlabCtl::Util.get_command_output("ln -sf #{bin_file} #{destination}")
  end
end

def revert
  log '== Reverting =='
  run_sv_command_for_service('stop', 'postgresql')
  if Dir.exist?("#{@db_worker.tmp_data_dir}.#{default_version.major}")
    run_command("rm -rf #{@db_worker.data_dir}")
    run_command(
      "mv #{@db_worker.tmp_data_dir}.#{default_version.major} #{@db_worker.data_dir}"
    )
  end
  create_links(default_version)
  run_sv_command_for_service('start', 'postgresql')
  log'== Reverted =='
end

def die(message)
  log '== Fatal error =='
  log message
  revert
  log "== Reverted to #{default_version}. Please check output for what went wrong =="
  maintenance_mode('disable')
  exit 1
end

def progress_message(message, &block)
  $stdout.print "\r#{message}:"
  results = yield
  if results
    $stdout.print "\r#{message}: \e[32mOK\e[0m\n"
  else
    $stdout.print "\r#{message}: \e[31mNOT OK\e[0m\n"
  end
  results
end

def maintenance_mode(command)
  # In order for the deploy page to work, we need nginx, unicorn, redis, and
  # gitlab-workhorse running
  # We'll manage postgresql during the ugprade process
  omit_services = %w(postgresql nginx unicorn redis gitlab-workhorse)
  if command.eql?('enable')
    dp_cmd = 'up'
    sv_cmd = 'stop'
  elsif command.eql?('disable')
    dp_cmd = 'down'
    sv_cmd = 'start'
  else
    raise StandardError("Cannot handle command #{command}")
  end
  progress_message('Toggling deploy page') do
    run_command("#{base_path}/bin/gitlab-ctl deploy-page #{dp_cmd}")
  end
  progress_message('Toggling services') do
    get_all_services.select { |x| !omit_services.include?(x) }.each do |svc|
      run_sv_command_for_service(sv_cmd, svc)
    end
  end
end
