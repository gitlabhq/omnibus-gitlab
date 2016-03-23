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

property :database_name, String, default: "gitlab-rails"
property :revision, String, default: nil
property :migrate_command, String, default: "/opt/gitlab/bin/gitlab-rake db:migrate"

load_current_value do
  revision_file = ::File.join(node['gitlab']['gitlab-rails']['dir'], "REVISION")
  if ::File.exist?(revision_file)
    revision IO.read(revision_file).chomp
  end
end

action :run do
  upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], "upgrade-status")
  db_migrate_status_file = ::File.join(upgrade_status_dir, "db-migrate-#{revision}")

  bash "migrate #{database_name} database for #{revision}" do
    code <<-EOH
      set -e
      log_file="/tmp/#{database_name}-db-migrate-$(date +%s)-$$/output.log"
      umask 077
      mkdir $(dirname ${log_file})
      #{migrate_command} 2>& 1 | tee ${log_file}
      STATUS=${PIPESTATUS[0]}
      echo $STATUS > #{db_migrate_status_file}
      exit $STATUS
    EOH
    not_if "(test -f #{db_migrate_status_file}) && (cat #{db_migrate_status_file} | grep -Fx 0)"
  end
end

action :nothing do
  #no-op
end
