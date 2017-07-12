#
# Copyright:: Copyright (c) 2016 GitLab B.V.
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

Gitlab[:node] = node

# Include EE config if our run-list contains the gitlab-ee cookbook
includes_ee = node.run_list.select { |item| item.name =~ /^gitlab-ee:/ }.count.positive?

Services.add_services('gitlab', Gitlab::Services.list)
Services.add_services('gitlab-ee', GitlabEE::Services.list) if includes_ee

if File.exists?('/etc/gitlab/gitlab.rb')
  Gitlab.from_file('/etc/gitlab/gitlab.rb')
end

node.consume_attributes(Gitlab.generate_config(node['fqdn']))
node.consume_attributes(GitlabEE.generate_config) if includes_ee
