#
# Copyright:: Copyright (c) 2022 GitLab Inc.
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

gitlab_rails_source_dir = "/opt/gitlab/embedded/service/gitlab-rails"
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")

dependent_services = []
node['gitlab']['gitlab-rails']['dependent_services'].each do |name|
  dependent_services << "runit_service[#{name}]" if omnibus_helper.should_notify?(name)
end
dependent_services << "sidekiq_service[sidekiq]" if omnibus_helper.should_notify?('sidekiq')

templatesymlink 'Create a gitlab_suggested_reviewers_secret and create a symlink to Rails root' do
  link_from File.join(gitlab_rails_source_dir, '.gitlab_suggested_reviewers_secret')
  link_to File.join(gitlab_rails_etc_dir, 'gitlab_suggested_reviewers_secret')
  source 'secret_token.erb'
  cookbook 'gitlab'
  owner 'root'
  group 'root'
  mode '0644'
  sensitive true
  variables(secret_token: node['gitlab']['suggested-reviewers']['api_secret_key'])
  dependent_services.each { |svc| notifies :restart, svc }
  only_if { node['gitlab']['suggested-reviewers']['api_secret_key'] }
end
