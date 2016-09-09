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

add_command_under_category 'registry', 'container-registry',  'Container registry commands', 2 do |cmd_name, command, path|
  service_name = "registry"
  return "Container registry is not enabled, exiting..." unless service_enabled?(service_name)

  if path.nil?
    default_registry_config_file = "/var/opt/gitlab/registry/config.yml"

    unless File.exists?(default_registry_config_file)
      log "Didn't find #{default_registry_config_file}, please supply the path to registry config.yml file, eg: gitlab-ctl registry COMMAND /path/to/config.yml ."
      exit! 1
    end
  end

  config_file_path = path || default_registry_config_file

  case command
  when 'garbage-collect'
    run_sv_command_for_service('stop', service_name)
    log "Running garbage-collect using configuration from #{config_file_path}, this might take a while...\n"
    status = run_command("/opt/gitlab/embedded/bin/registry garbage-collect #{config_file_path}")

    if status.exitstatus == 0
      run_sv_command_for_service('start', service_name)
      exit! 0
    else
      log "\nFailed to run garbage-collect command, starting registry service."
      run_sv_command_for_service('start', service_name)
      exit! 1
    end
  else
    puts "\nUsage: #{cmd_name} garbage-collect"
  end
end
