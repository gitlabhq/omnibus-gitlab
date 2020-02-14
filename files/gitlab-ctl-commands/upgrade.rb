#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

add_command 'upgrade', 'Run migrations after a package upgrade', 1 do |cmd_name|
  # On a fresh installation, run reconfigure automatically if EXTERNAL_URL is set
  unless File.exist?("/var/opt/gitlab/bootstrapped") || external_url_unset?
    code = reconfigure
    print_welcome_and_exit if code.zero?
    Kernel.exit code
  end

  service_statuses = `#{base_path}/bin/gitlab-ctl status`

  if /: runsv not running/ =~ service_statuses || service_statuses.empty?
    log 'It looks like GitLab has not been configured yet; skipping the upgrade '\
      'script.'
    print_welcome_and_exit
  end

  unless GitlabCtl::Util.progress_message('Checking PostgreSQL executables') do
    remove_old_node_state
    status = GitlabCtl::Util.chef_run('solo.rb', 'postgresql-bin.json')
    $stdout.puts status.stdout
    !status.error?
  end
    log 'Could not update PostgreSQL executables.'
  end

  # TODO: Remove in 13.0, by which everyone would've reset their Grafana.
  # Issue: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4891
  unless GitlabCtl::Util.progress_message('Checking if Grafana needs to be reset') do
    command = %W(#{base_path}/bin/gitlab-ctl reset-grafana)
    status = run_command(command.join(' '))
    status.success?
  end
    log 'Failed to check if Grafana needs to be reset.'
  end

  auto_migrations_skip_file = "#{etc_path}/skip-auto-reconfigure"
  if File.exist?(auto_migrations_skip_file)
    log "Found #{auto_migrations_skip_file}, exiting..."
    print_upgrade_and_exit
  end

  if File.exist?('/etc/gitlab/disable-postgresql-upgrade')
    log ''
    log '==='
    log 'Skipping automatic PostgreSQL upgrade'
    log 'Please see https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server'
    log 'for details on how to manually upgrade the PostgreSQL server'
    log '==='
    log ''
  else
    unless GitlabCtl::Util.progress_message('Ensuring PostgreSQL is updated') do
      command = %W(#{base_path}/bin/gitlab-ctl pg-upgrade -w)
      status = run_command(command.join(' '))
      status.success?
    end
      log 'Error ensuring PostgreSQL is updated. Please check the logs'
      Kernel.exit 1
    end
  end

  # Refresh service_statuses to ensure we pick up any new services
  service_statuses = `#{base_path}/bin/gitlab-ctl status`

  log 'Shutting down all GitLab services except those needed for migrations'
  MIGRATION_SERVICES = %w(postgresql redis geo-postgresql gitaly praefect).freeze
  (get_all_services - MIGRATION_SERVICES).each do |sv_name|
    run_sv_command_for_service('stop', sv_name)
  end

  log 'Ensuring the required services are running'
  MIGRATION_SERVICES.each do |sv_name|
    # If the service is disabled, e.g. because we are using an external
    # Postgres server, or it is already running, then this command is a no-op.
    run_sv_command_for_service('start', sv_name)
  end

  # in case of downgrades, it might be necessary to remove the redis dump
  redis_dump = '/var/opt/gitlab/redis/dump.rdb'
  try_redis_restart = File.exist? redis_dump

  SERVICE_WAIT = 30
  MIGRATION_SERVICES.each do |sv_name|
    status = -1
    SERVICE_WAIT.times do
      status = run_sv_command_for_service('status', sv_name)
      break if status.zero?

      sleep 1
    end

    next if status.zero?

    if sv_name == 'redis' && try_redis_restart
      try_redis_restart = false
      log "Failed starting Redis; retrying after removing #{redis_dump}"
      status = run_sv_command_for_service('stop', 'redis')
      abort "Failed trying to put Redis in a down state" unless status.zero?
      sleep 1 # hack necessary, o/wise runit won't try to start the service
      File.delete redis_dump
      run_sv_command_for_service('start', 'redis')
      redo
    end

    abort "Failed to start #{sv_name} for migrations"
  end

  # Force upgrade to Prometheus 2.x
  unless GitlabCtl::Util.progress_message('Ensuring Prometheus is updated') do
    command = %W(#{base_path}/bin/gitlab-ctl prometheus-upgrade -w --skip-reconfigure)
    status = run_command(command.join(' '))
    status.success?
  end
    log 'Error ensuring Prometheus is updated. Please check the logs'
    Kernel.exit 1
  end

  # Do not show "WARN: Cookbook 'local-mode-cache' is empty or entirely chefignored at /opt/gitlab/embedded/cookbooks/local-mode-cache"
  local_mode_cache_path = "#{base_path}/embedded/cookbooks/local-mode-cache"
  run_command("rm -rf #{local_mode_cache_path}")

  log 'Reconfigure GitLab to apply migrations'
  reconfigure(false) # sending 'false' mans "don't quit afterwards"

  log 'Restarting previously running GitLab services'
  get_all_services.each do |sv_name|
    run_sv_command_for_service('start', sv_name) if /^run: #{sv_name}:/.match?(service_statuses)
  end

  print_upgrade_and_exit
end

# Check for stale files from previous/failed installs, and advise the user to remove them.
def stale_files_check
  # The ctime will always be reflective of when the file was installed, where mtime is not being
  #  set when the file is extracted from a package. By using ctime to sort the files, the newest
  #  file is always the file to keep, and it's name is excluded from the output to the user.
  sprocket_files = Dir.glob("#{base_path}/embedded/service/gitlab-rails/public/assets/.sprockets-manifest*").sort_by { |f| File.ctime(f) }
  return unless sprocket_files.size > 1

  puts "WARNING:"
  puts "GitLab discovered stale file(s) from a previous install that need to be cleaned up."
  puts "The following files need to be removed:"
  puts "\n"
  puts sprocket_files.take(sprocket_files.size - 1)
  puts "\n"
end

def get_color_strings
  # Check if terminal supports colored outputs.
  if system("which tput > /dev/null") && `tput colors`.strip.to_i >= 8
    # ANSI color codes for yellow and reset color. For printing beautiful ASCII art.
    yellow_string = "\e[33m%s"
    no_color_string = "\e(B\e[m%s"
  else
    yellow_string = "%s"
    no_color_string = "%s"
  end
  [yellow_string, no_color_string]
end

def print_tanuki_art
  tanuki_art = '
       *.                  *.
      ***                 ***
     *****               *****
    .******             *******
    ********            ********
   ,,,,,,,,,***********,,,,,,,,,
  ,,,,,,,,,,,*********,,,,,,,,,,,
  .,,,,,,,,,,,*******,,,,,,,,,,,,
      ,,,,,,,,,*****,,,,,,,,,.
         ,,,,,,,****,,,,,,
            .,,,***,,,,
                ,*,.
  '
  # Get the proper color strings if terminal supports them
  yellow_string, no_color_string = get_color_strings
  puts yellow_string % tanuki_art
  puts no_color_string % "\n"
end

def print_gitlab_art
  gitlab_art = '
     _______ __  __          __
    / ____(_) /_/ /   ____ _/ /_
   / / __/ / __/ /   / __ `/ __ \
  / /_/ / / /_/ /___/ /_/ / /_/ /
  \____/_/\__/_____/\__,_/_.___/
  '
  yellow_string, no_color_string = get_color_strings
  puts yellow_string % gitlab_art
  puts no_color_string % "\n"
end

def pg_upgrade_check
  pg_version_file = '/var/opt/gitlab/postgresql/data/PG_VERSION'
  manifest_file = '/opt/gitlab/version-manifest.txt'

  version = File.read(pg_version_file) if File.exist?(pg_version_file)
  new_version = File.readlines(manifest_file).grep(/postgresql_new/).first&.split&.[](1) if File.exist?(manifest_file)
  File.exist?("/var/opt/gitlab/bootstrapped")

  # Print when fresh install - Always
  # Print when upgrade
  #  - when we have a database and its not already on the new version
  is_install = !File.exist?('/var/opt/gitlab/bootstrapped')
  outdated_db = version && new_version && new_version !~ /^#{version}/
  return unless is_install || outdated_db

  puts "\nGitLab now ships with a newer version of PostgreSQL (#{new_version}), but it is not yet"
  puts "enabled by default. To upgrade, please see:"
  puts "https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server\n\n"
end

def print_welcome_and_exit
  print_tanuki_art
  print_gitlab_art

  external_url = ENV['EXTERNAL_URL']
  puts "Thank you for installing GitLab!"
  if external_url == "http://gitlab.example.com"
    puts "GitLab was unable to detect a valid hostname for your instance."
    puts "Please configure a URL for your GitLab instance by setting `external_url`"
    puts "configuration in /etc/gitlab/gitlab.rb file."
    puts "Then, you can start your GitLab instance by running the following command:"
    puts "  sudo gitlab-ctl reconfigure"
  else
    puts "GitLab should be available at #{ENV['EXTERNAL_URL']}"
  end

  puts "\nFor a comprehensive list of configuration options please see the Omnibus GitLab readme"
  puts "https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md\n\n"
  pg_upgrade_check
  stale_files_check
  Kernel.exit 0
end

def print_upgrade_and_exit
  print_gitlab_art
  puts "Upgrade complete! If your GitLab server is misbehaving try running"
  puts "  sudo gitlab-ctl restart"
  puts "before anything else."

  auto_backup_skip_file = "#{etc_path}/skip-auto-backup"
  if File.exist?(auto_backup_skip_file)
    puts "The automatic database backup was skipped as requested."
    puts "You may enable it again anytime by running the following command:"
    puts "  sudo rm #{auto_backup_skip_file}"
  else
    puts "If you need to roll back to the previous version you can use the database"
    puts "backup made during the upgrade (scroll up for the filename)."
  end

  puts "\n"
  pg_upgrade_check
  stale_files_check
  Kernel.exit 0
end

# Check if user already provided URL where GitLab should run
def external_url_unset?
  ENV['EXTERNAL_URL'].nil? || ENV['EXTERNAL_URL'].empty? || ENV['EXTERNAL_URL'] == "http://gitlab.example.com"
end
