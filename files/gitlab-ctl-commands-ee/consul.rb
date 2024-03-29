#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/consul"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/consul_download"

add_command_under_category('consul', 'consul', 'Interact with the gitlab-consul cluster', 2) do
  consul = ConsulHandler.new(ARGV, $stdin.gets)
  consul.execute
end

add_command_under_category('consul-download', 'consul', 'Download consul for the gitlab-consul cluster', 2) do
  ConsulDownloadCommand.new(ARGV).run
end
