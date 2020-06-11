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

omnibus_helper = OmnibusHelper.new(node)

remote_syslog_dir = node['gitlab']['remote-syslog']['dir']
remote_syslog_log_dir = node['gitlab']['remote-syslog']['log_directory']
logging_hostname = node['gitlab']['logging']['udp_log_shipping_hostname']

[
  remote_syslog_dir,
  remote_syslog_log_dir
].each do |dir|
  directory dir do
    mode "0700"
    recursive true
  end
end

template File.join(remote_syslog_dir, "remote_syslog.yml") do
  mode "0644"
  variables(node['gitlab']['remote-syslog'].to_hash)
  notifies :restart, 'runit_service[remote-syslog]' if omnibus_helper.should_notify?("remote-syslog")
end

runit_service "remote-syslog" do
  start_down node['gitlab']['remote-syslog']['ha']
  options({
    log_directory: remote_syslog_log_dir,
    dir: remote_syslog_dir,
    logging_hostname: logging_hostname,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['remote-syslog'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start remote-syslog" do
    retries 20
  end
end
