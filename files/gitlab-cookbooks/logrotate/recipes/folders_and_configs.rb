#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('logrotate')

logrotate_dir = node['logrotate']['dir']
logrotate_d_dir = File.join(logrotate_dir, 'logrotate.d')

[
  logrotate_dir,
  logrotate_d_dir
].each do |dir|
  directory dir do
    mode "0700"
  end
end

# Create log_directory
directory logging_settings[:log_directory] do
  owner logging_settings[:log_directory_owner]
  mode logging_settings[:log_directory_mode]
  if log_group = logging_settings[:log_directory_group]
    group log_group
  end
  recursive true
end

template File.join(logrotate_dir, "logrotate.conf") do
  mode "0644"
  variables(node['logrotate'].to_hash)
end

logfiles_helper.logrotate_services_list.each do |svc, logging_settings|
  template File.join(logrotate_d_dir, svc) do
    source 'logrotate-service.erb'
    variables(
      username: logging_settings[:log_directory_owner],
      groupname: logging_settings[:logrotate_group],
      log_directory: logging_settings[:log_directory],
      options: logging_settings[:options]
    )
  end
end
