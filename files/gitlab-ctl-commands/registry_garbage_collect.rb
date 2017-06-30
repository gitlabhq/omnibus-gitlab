#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

add_command_under_category 'registry-garbage-collect', 'container-registry', 'Run Container Registry garbage collection.', 2 do |cmd_name, path|
  service_name = "registry"

  unless service_enabled?(service_name)
    log "Container registry is not enabled, exiting..."
    Kernel.exit 1
  end

  config_file_path = path || '/var/opt/gitlab/registry/config.yml'

  unless File.exist?(config_file_path)
    log "Didn't find #{config_file_path}, please supply the path to registry config.yml file, eg: gitlab-ctl registry-garbage-collect /path/to/config.yml"
    Kernel.exit 1
  end

  run_sv_command_for_service('stop', service_name)
  log "Running garbage-collect using configuration from #{config_file_path}, this might take a while...\n"
  status = run_command("/opt/gitlab/embedded/bin/registry garbage-collect #{config_file_path}")

  if status.exitstatus.zero?
    run_sv_command_for_service('start', service_name)
    Kernel.exit 0
  else
    log "\nFailed to run garbage-collect command, starting registry service."
    run_sv_command_for_service('start', service_name)
    Kernel.exit 1
  end
end
