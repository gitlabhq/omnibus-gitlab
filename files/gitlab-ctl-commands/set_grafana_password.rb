#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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

add_command 'set-grafana-password', 'Reset admin password for Grafana', 2 do |cmd_name|
  unless service_enabled?('grafana')
    log "Grafana not enabled."
    Kernel.exit 0
  end

  home_dir = GitlabCtl::Util.get_node_attributes['monitoring']['grafana']['home']

  begin
    password = GitlabCtl::Util.get_password
  rescue GitlabCtl::Errors::PasswordMismatch
    warn "Passwords do not match."
    Kernel.exit 1
  end

  log "Stopping Grafana for password update"
  run_sv_command_for_service('stop', 'grafana')

  status = GitlabCtl::Util.run_command("/opt/gitlab/embedded/bin/grafana-cli --homepath #{home_dir} admin reset-admin-password \'#{password}\'")

  log "Restarting Grafana."
  run_sv_command_for_service('start', 'grafana')

  if status.error?
    log "Failed to update password."
    $stdout.puts status.stdout
    warn status.stderr
    Kernel.exit 1
  else
    log "Password updated successfully."
  end
end
