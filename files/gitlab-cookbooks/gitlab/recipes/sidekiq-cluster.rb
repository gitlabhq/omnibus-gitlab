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
account_helper = AccountHelper.new(node)
service = OmnibusHelper.new(node).sidekiq_cluster_service_name

sidekiq_service service do
  log_directory node['gitlab'][service]['log_directory']
  template_name 'sidekiq-cluster'
  user account_helper.gitlab_user
end

consul_service service do
  action Prometheus.service_discovery_action
  ip_address node['gitlab'][service]['listen_address']
  port node['gitlab'][service]['listen_port']
  reload_service false unless node['consul']['enable']
end

if service != 'sidekiq-cluster'
  # The service that's being started is called sidekiq, disable `sidekiq-cluster`
  # if it was still running. We don't allow cluster configuration through sidekiq
  # in combination with a `sidekiq-cluster` service.
  runit_service 'sidekiq-cluster' do
    action :disable
  end
end
