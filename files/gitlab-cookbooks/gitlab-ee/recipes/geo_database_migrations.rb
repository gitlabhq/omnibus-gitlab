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

omnibus_helper = OmnibusHelper.new(node)
gitlab_geo_helper = GitlabGeoHelper.new(node)

dependent_services = []
dependent_services << "runit_service[unicorn]" if omnibus_helper.should_notify?("unicorn")
dependent_services << "runit_service[puma]" if omnibus_helper.should_notify?("puma")
dependent_services << "runit_service[actioncable]" if omnibus_helper.should_notify?("actioncable")
dependent_services << "runit_service[sidekiq]" if omnibus_helper.should_notify?("sidekiq")

bash 'migrate gitlab-geo tracking database' do
  code <<-EOH
    set -e
    log_file="#{node['gitlab']['gitlab-rails']['log_directory']}/gitlab-geo-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log"
    umask 077
    /opt/gitlab/bin/gitlab-rake geo:db:migrate 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    echo $STATUS > #{gitlab_geo_helper.db_migrate_status_file}
    exit $STATUS
  EOH

  notifies :run, 'execute[start geo-postgresql]', :before if omnibus_helper.should_notify?('geo-postgresql')
  dependent_services.each do |svc|
    notifies :restart, svc, :immediately
  end
  not_if { gitlab_geo_helper.migrated? }
  only_if { node['gitlab']['geo-secondary']['auto_migrate'] }
end
