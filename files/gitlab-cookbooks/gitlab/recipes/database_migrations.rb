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
require 'digest'

omnibus_helper = OmnibusHelper.new(node)
account_helper = AccountHelper.new(node)

initial_root_password = node['gitlab']['gitlab-rails']['initial_root_password']
initial_license_file = node['gitlab']['gitlab-rails']['initial_license_file'] || Dir.glob('/etc/gitlab/*.gitlab-license').first
initial_runner_token = node['gitlab']['gitlab-rails']['initial_shared_runners_registration_token']

dependent_services = []
dependent_services << "runit_service[unicorn]" if omnibus_helper.should_notify?("unicorn")
dependent_services << "runit_service[puma]" if omnibus_helper.should_notify?("puma")
dependent_services << "runit_service[sidekiq]" if omnibus_helper.should_notify?("sidekiq")
dependent_services << "runit_service[sidekiq-cluster]" if omnibus_helper.should_notify?("sidekiq-cluster")

connection_attributes = %w(
  db_adapter
  db_database
  db_host
  db_port
  db_socket
).collect { |attribute| node['gitlab']['gitlab-rails'][attribute] }
connection_digest = Digest::MD5.hexdigest(Marshal.dump(connection_attributes))

revision_file = "/opt/gitlab/embedded/service/gitlab-rails/REVISION"
revision = IO.read(revision_file).chomp if ::File.exist?(revision_file)
upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], "upgrade-status")
db_migrate_status_file = ::File.join(upgrade_status_dir, "db-migrate-#{connection_digest}-#{revision}")

env_variables = {}
env_variables['GITLAB_ROOT_PASSWORD'] = initial_root_password if initial_root_password
env_variables['GITLAB_LICENSE_FILE'] = initial_license_file if initial_license_file
env_variables['GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN'] = initial_runner_token if initial_runner_token

# TODO: Refactor this into a resource
# Currently blocked due to a bug in Chef 12.6.0
# https://github.com/chef/chef/issues/4537
bash "migrate gitlab-rails database" do
  code <<-EOH
    set -e
    log_file="#{node['gitlab']['gitlab-rails']['log_directory']}/gitlab-rails-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log"
    umask 077
    /opt/gitlab/bin/gitlab-rake gitlab:db:configure 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    chown #{account_helper.gitlab_user}:#{account_helper.gitlab_group} ${log_file}
    echo $STATUS > #{db_migrate_status_file}
    exit $STATUS
  EOH
  environment env_variables unless env_variables.empty?
  notifies :run, "execute[clear the gitlab-rails cache]", :immediately
  dependent_services.each do |svc|
    notifies :restart, svc, :immediately
  end
  not_if "(test -f #{db_migrate_status_file}) && (cat #{db_migrate_status_file} | grep -Fx 0)"
  only_if { node['gitlab']['gitlab-rails']['auto_migrate'] }
end
