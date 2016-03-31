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

revision_file = ::File.join(node['gitlab']['gitlab-rails']['dir'], "REVISION")
if ::File.exist?(revision_file)
  revision = IO.read(revision_file).chomp
end
upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], "upgrade-status")
db_migrate_status_file = ::File.join(upgrade_status_dir, "db-migrate-#{revision}")

execute "initialize gitlab-rails database" do
  command "/opt/gitlab/bin/gitlab-rake db:schema:load db:seed_fu"
  environment ({'GITLAB_ROOT_PASSWORD' => initial_root_password }) if initial_root_password
  action :nothing
  notifies :run, 'execute[enable pg_trgm extension]', :before unless OmnibusHelper.not_listening?("posgresql") || !node['gitlab']['postgresql']['enable']
end

# TODO: Refactor this into a resource
# Currently blocked due to a bug in Chef 12.6.0
# https://github.com/chef/chef/issues/4537
bash "migrate gitlab-rails database" do
  code <<-EOH
    set -e
    log_file="/tmp/gitlab-rails-db-migrate-$(date +%s)-$$/output.log"
    umask 077
    mkdir $(dirname ${log_file})
    /opt/gitlab/bin/gitlab-rake db:migrate 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    echo $STATUS > #{db_migrate_status_file}
    exit $STATUS
  EOH
  notifies :run, 'execute[enable pg_trgm extension]', :before unless OmnibusHelper.not_listening?("postgresql") || !node['gitlab']['postgresql']['enable']
  notifies :run, "execute[clear the gitlab-rails cache]", :immediately unless OmnibusHelper.not_listening?("redis")
  dependent_services.each do |svc|
    notifies :restart, svc, :immediately
  end
  not_if "(test -f #{db_migrate_status_file}) && (cat #{db_migrate_status_file} | grep -Fx 0)"
end
