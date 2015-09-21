#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

ci_dependent_services = []
ci_dependent_services << "ci-unicorn" if OmnibusHelper.should_notify?("ci-unicorn")
ci_dependent_services << "ci-sidekiq" if OmnibusHelper.should_notify?("ci-sidekiq")
ci_dependent_services << "ci-redis" if OmnibusHelper.should_notify?("ci-redis")

directory node['gitlab']['gitlab-ci']['backup_path'] do
  owner AccountHelper.new(node).gitlab_ci_user
  mode '0755'
  recursive true
end


# Stop and disable services
ci_dependent_services.each do |ci_service|
  service ci_service do
    action :stop
  end

  include_recipe "gitlab::#{ci_service}_disable"

  if node["gitlab"][ci_service]["enable"]
    node.override["gitlab"][ci_service]["enable"] = false
  end
end
