#
# Copyright:: Copyright (c) 2020 GitLab.com
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
logfiles_helper = LogfilesHelper.new(node)
logging_settings = logfiles_helper.logging_settings('praefect')

bash 'migrate praefect database' do
  code <<-EOH
    set -e
    log_file="#{logging_settings[:log_directory]}/praefect-sql-migrate-$(date +%Y-%m-%d-%H-%M-%S).log"

   /opt/gitlab/embedded/bin/praefect -config #{File.join(node['praefect']['dir'], 'config.toml')} sql-migrate 2>& 1 | tee ${log_file}

    exit ${PIPESTATUS[0]}
  EOH
  user account_helper.gitlab_user
  group account_helper.gitlab_group

  notifies :hup, "runit_service[praefect]", :immediately
  only_if { node['praefect']['auto_migrate'] }
end
