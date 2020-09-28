#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

runit_service "logrotate" do
  start_down node['gitlab']['logrotate']['ha']
  control ['t']
  options({
    log_directory: node['gitlab']['logrotate']['log_directory']
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['logrotate'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start logrotate" do
    retries 20
  end
end
