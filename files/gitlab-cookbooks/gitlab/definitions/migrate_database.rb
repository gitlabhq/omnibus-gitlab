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

define :migrate_database, :command => nil, :action => :run do
  bash "migrate #{params[:name]} database" do
    code <<-EOH
      set -e
      log_file="/tmp/#{params[:name]}-db-migrate-$(date +%s)-$$/output.log"
      umask 077
      mkdir $(dirname ${log_file})
      #{params[:command]} 2>& 1 | tee ${log_file}
      exit ${PIPESTATUS[0]}
    EOH
    action params[:action]
  end
end
