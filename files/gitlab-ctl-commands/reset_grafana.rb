#
# Copyright:: Copyright (c) 2019 GitLab Inc
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

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/util"
require 'fileutils'
require 'date'

add_command 'reset-grafana', 'Reset Grafana instance to its initial state by removing the data directory', 1 do |_cmd_name|
  unless service_enabled?('grafana')
    log "\nGrafana is not enabled. Skipping."
    Kernel.exit 0
  end

  node_attributes = GitlabCtl::Util.get_node_attributes
  home_dir = node_attributes['monitoring']['grafana']['home']

  data_dir = File.join(home_dir, 'data')
  backup_path = File.join(home_dir, "data.bak.#{Date.today}")
  status_file = File.join(home_dir, 'CVE_reset_status')

  # In postinst (which is where upgrade script runs), we have no clue from
  # which version user is upgrading. This gitlab-ctl command gets called
  # from upgrade script and we need it to not be run if the resetting was
  # already done on a previous upgrade. So we depend on a status file for this.
  if File.exist?(status_file) && File.read(status_file).strip == '0'
    log "\nStatus file found. Grafana is not vulnerable. Skipping reset."
    Kernel.exit 0
  end

  log "\nMoving old data directory to #{backup_path}"
  begin
    FileUtils.mv(data_dir, backup_path)
    File.write(status_file, '0')
    log "\nGrafana has been reset. Old data directory has been backed up to #{backup_path}."
  rescue StandardError => e
    log "\nFailed to move old data directory to #{backup_path}."
    log e.message
  end

  log "\nRestarting Grafana"
  run_sv_command_for_service('restart', 'grafana')
end
