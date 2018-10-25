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

define :sidekiq_service, rails_app: nil, user: nil do
  svc = params[:name]
  user = params[:user]
  group = params[:group]
  rails_app = params[:rails_app]

  metrics_dir = File.join(node['gitlab']['runtime-dir'].to_s, 'gitlab/sidekiq') unless node['gitlab']['runtime-dir'].nil?

  sidekiq_log_dir = node['gitlab'][svc]['log_directory']

  directory sidekiq_log_dir do
    owner user
    mode '0700'
    recursive true
  end

  runit_service svc do
    down node['gitlab'][svc]['ha']
    template_name 'sidekiq'
    options({
      rails_app: rails_app,
      user: user,
      groupname: group,
      shutdown_timeout: node['gitlab'][svc]['shutdown_timeout'],
      concurrency: node['gitlab'][svc]['concurrency'],
      log_directory: sidekiq_log_dir,
      metrics_dir: metrics_dir,
      clean_metrics_dir: true
    }.merge(params))
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][svc].to_hash)
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end
