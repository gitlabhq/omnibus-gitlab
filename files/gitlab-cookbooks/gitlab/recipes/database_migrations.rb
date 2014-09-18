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

execute "initialize database" do
  command "/opt/gitlab/bin/gitlab-rake db:schema:load db:seed_fu"
  action :nothing
end

bash "migrate database" do
  code <<-EOH
    log_file="/tmp/gitlab-db-migrate-$(date +%s)-$$"
    umask 077
    /opt/gitlab/bin/gitlab-rake db:migrate 2>& 1 | tee ${log_file}
    exit ${PIPESTATUS[0]}
  EOH
  action :nothing
end
