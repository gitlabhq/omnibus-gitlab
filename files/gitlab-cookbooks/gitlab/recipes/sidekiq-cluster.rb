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

log_directory = node['gitlab']['sidekiq-cluster']['log_directory']
metrics_dir = File.join(node['gitlab']['runtime-dir'].to_s, "gitlab/#{service}") unless node['gitlab']['runtime-dir'].nil?

directory log_directory do
  owner account_helper.gitlab_user
  mode '0700'
  recursive true
end

# The service wrapping `sidekiq-cluster` will be called `sidekiq` in case it was
# enabled from the `sidekiq` configuration.
#
# This indirection will be removed once sidekiq-cluster becomes the only way to
# start sidekiq in omnibus: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/240
runit_service service do
  start_down node['gitlab']['sidekiq-cluster']['ha']
  template_name 'sidekiq-cluster'
  options({
    user: account_helper.gitlab_user,
    groupname: account_helper.gitlab_group,
    log_directory: log_directory,
    metrics_dir: metrics_dir,
    clean_metrics_dir: true
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['sidekiq-cluster'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start sidekiq-cluster" do
    retries 20
  end
end

if service != 'sidekiq-cluster'
  # The service that's being started is called sidekiq, disable `sidekiq-cluster`
  # if it was still running. We don't allow cluster configuration through sidekiq
  # in combination with a `sidekiq-cluster` service.
  runit_service 'sidekiq-cluster' do
    action :disable
  end
end
