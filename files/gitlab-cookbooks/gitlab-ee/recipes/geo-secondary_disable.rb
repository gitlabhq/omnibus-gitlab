#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

omnibus_helper = OmnibusHelper.new(node)

gitlab_rails_source_dir = '/opt/gitlab/embedded/service/gitlab-rails'
gitlab_rails_dir = node['gitlab']['gitlab-rails']['dir']
gitlab_rails_etc_dir = File.join(gitlab_rails_dir, "etc")

dependent_services = []
%w(
  puma
  sidekiq
).each do |svc|
  dependent_services << "runit_service[#{svc}]" if omnibus_helper.should_notify?(svc)
end

templatesymlink 'Removes database_geo.yml symlink' do
  link_from File.join(gitlab_rails_source_dir, 'config/database_geo.yml')
  link_to File.join(gitlab_rails_etc_dir, 'database_geo.yml')
  dependent_services.each { |svc| notifies :restart, svc }
  notifies :restart, "unicorn_service[unicorn]" if omnibus_helper.should_notify?('unicorn')

  action :delete
end
