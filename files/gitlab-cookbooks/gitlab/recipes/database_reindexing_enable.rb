#
# Copyright:: Copyright (c) 2020 GitLab B.V.
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

reindexing = node['gitlab']['gitlab-rails']['database_reindexing']

include_recipe "crond::enable"

crond_job 'database-reindexing' do
  user "root"
  hour reindexing['hour']
  minute reindexing['minute']
  month reindexing['month']
  day_of_month reindexing['day_of_month']
  day_of_week reindexing['day_of_week']

  command "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
end
