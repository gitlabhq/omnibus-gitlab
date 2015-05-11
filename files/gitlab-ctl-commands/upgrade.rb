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

add_command 'upgrade', 'Run migrations after a package upgrade', 1 do |cmd_name|
  auto_migrations_skip_file = "#{etc_path}/skip-auto-migrations"
  if File.exists?(auto_migrations_skip_file)
    log "Found #{auto_migrations_skip_file}, exiting..."
    exit! 0
  end

  service_statuses = `#{base_path}/bin/gitlab-ctl status`

  if /: runsv not running/.match(service_statuses) || service_statuses.empty? then
    log 'It looks like GitLab has not been installed yet; skipping the upgrade '\
      'script.'
    exit! 0
  end

  log 'Shutting down all GitLab services except those needed for migrations'
  get_all_services.each do |sv_name|
    run_sv_command_for_service('stop', sv_name)
  end

  MIGRATION_SERVICES = %w{postgresql redis}
  MIGRATION_SERVICES.each do |sv_name|
    # If the service is disabled, e.g. because we are using an external
    # Postgres server, then this command is a no-op.
    run_sv_command_for_service('start', sv_name)
  end

  SERVICE_WAIT = 30
  MIGRATION_SERVICES.each do |sv_name|
    status = -1
    SERVICE_WAIT.times do
      status = run_sv_command_for_service('status', sv_name)
      break if status.zero?
      sleep 1
    end
    abort "Failed to start #{sv_name} for migrations" unless status.zero?
  end

  log 'Reconfiguring GitLab to apply migrations'
  reconfigure(false) # sending 'false' means "don't quit afterwards"

  log 'Restarting previously running GitLab services'
  get_all_services.each do |sv_name|
    if /^run: #{sv_name}:/.match(service_statuses)
      run_sv_command_for_service('start', sv_name)
    end
  end

  log <<EOS

Upgrade complete! If your GitLab server is misbehaving try running

   sudo gitlab-ctl restart

before anything else. If you need to roll back to the previous version you can
use the database backup made during the upgrade (scroll up for the filename).
EOS
end
