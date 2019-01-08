#
# Copyright:: Copyright (c) 2018 GitLab Inc
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

add_command 'prometheus-upgrade', 'Upgrade the Prometheus data to the latest supported version',
  2 do |_cmd_name|

  unless service_enabled?('prometheus')
    log "Prometheus not enabled."
    Kernel.exit 0
  end

  options = GitlabCtl::PrometheusUpgrade.parse_options(ARGV)
  home_dir = File.expand_path(options[:home_dir])

  prometheus_upgrade = GitlabCtl::PrometheusUpgrade.new(base_path, home_dir)

  # v1_path points to the current data directory
  unless File.exist?(prometheus_upgrade.v1_path)
    log "Specified home directory, #{home_dir} either does not exist or does not contain any data directory inside."
    log "Use --home-dir flag to specify Prometheus home directory."
    Kernel.exit 1
  end

  if prometheus_upgrade.is_version_2?
    log "Already running Prometheus version 2."
    Kernel.exit 0
  end

  unless options[:skip_data_migration]
    if options[:wait]
      log "Converting existing data to new format is a time consuming process and can take hours."
      log "If you prefer not to migrate existing data, press Ctrl-C now and re-run the command with --skip-data-migration flag."
      log "Waiting for 30 seconds for input."
      status = GitlabCtl::Util.delay_for(30)
      Kernel.exit(0) unless status
    end
  end

  prometheus_upgrade.prepare_directories
  prometheus_upgrade.backup_data

  log "\nStopping prometheus for upgrade"
  run_sv_command_for_service('stop', 'prometheus')

  unless options[:skip_data_migration]
    log "Migrating data"
    status = prometheus_upgrade.migrate
    unless status
      log "Migration failed. Restoring data and restarting prometheus."
      prometheus_upgrade.revert
      run_sv_command_for_service('start', 'prometheus')
      Kernel.exit 1
    end
    log "Migration successful. "
  end

  prometheus_upgrade.rename_directory

  log "Running reconfigure to apply changes"
  run_chef("#{base_path}/embedded/cookbooks/dna.json").success?

  log "Starting prometheus"
  run_sv_command_for_service('start', 'prometheus')

  log "Prometheus upgrade completed. You are now running Prometheus version 2"
  log "Old data directory has been backed up to #{prometheus_upgrade.backup_path}."
end
