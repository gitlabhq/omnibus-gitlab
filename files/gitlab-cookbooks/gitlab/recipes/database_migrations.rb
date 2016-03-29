#
# Copyright:: Copyright (c) 2014 GitLab.com
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

initial_root_password = node['gitlab']['gitlab-rails']['initial_root_password']

dependent_services = []
dependent_services << "service[unicorn]" if OmnibusHelper.should_notify?("unicorn")
dependent_services << "service[sidekiq]" if OmnibusHelper.should_notify?("sidekiq")

execute "initialize gitlab-rails database" do
  command "/opt/gitlab/bin/gitlab-rake db:schema:load db:seed_fu"
  environment ({'GITLAB_ROOT_PASSWORD' => initial_root_password }) if initial_root_password
  action :nothing
  notifies :run, 'execute[enable pg_trgm extension]', :before unless OmnibusHelper.not_listening?("posgresql") || !node['gitlab']['postgresql']['enable']
end

migrate_database 'gitlab-rails' do
  command '/opt/gitlab/bin/gitlab-rake db:migrate'
  action :nothing
  restarts dependent_services
end
