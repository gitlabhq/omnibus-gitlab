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

add_command 'get-redis-master', 'Get connection details to Redis master', 2 do |cmd_name|
  node_attributes = GitlabCtl::Util.get_node_attributes
  redis_sentinels = node_attributes['gitlab']['gitlab-rails']['redis_sentinels']
  redis_master_name = node_attributes['redis']['master_name']

  master_host = nil
  master_port = nil

  if redis_sentinels.empty?
    log "No Redis Sentinels defined in /etc/gitlab/gitlab.rb. Exiting."
    Kernel.exit 0
  end

  unless redis_master_name
    log "No Redis master name defined in /etc/gitlab/gitlab.rb. Exiting."
    Kernel.exit 0
  end

  # Attempt to cycle through each sentinel and get the master information.
  # Break out of the loop on first positive hit.
  redis_sentinels.each do |sentinel|
    host = sentinel['host']
    port = sentinel['port']
    command = "/opt/gitlab/embedded/bin/redis-cli -h #{host} -p #{port} SENTINEL get-master-addr-by-name #{redis_master_name}"
    output = GitlabCtl::Util.get_command_output(command).strip
    master_host, master_port = output.split("\n")
    break
  rescue GitlabCtl::Errors::ExecutionError
    log "Error fetching Redis master information from sentinel running at `#{host}:#{port}`. Trying a different sentinel node."
    next
  end

  if master_host.nil? || master_port.nil?
    log "Failed to fetch Redis master host and port."
    Kernel.exit 1
  end

  log "Redis master found at host #{master_host} listening on port #{master_port}"
end
