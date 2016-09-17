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

add_command 'deploy-page', 'Put up the deploy page', 2 do |cmd_name, state|
  require 'fileutils'
  deploy = File.join(base_path, 'embedded/service/gitlab-rails/public/deploy.html')
  index = deploy.sub('deploy', 'index')

  case state
  when 'up'
    FileUtils.cp(deploy, index, verbose: true)
  when 'down'
    FileUtils.rm_f(index, verbose: true)
  when 'status'
    status = File.exist?(index) ? 'up' : 'down'
    puts "Deploy page is #{status}"
  else
    puts "Usage: #{cmd_name} up|down|status"
  end
end
