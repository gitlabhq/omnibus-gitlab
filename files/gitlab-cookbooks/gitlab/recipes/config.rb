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

Services.add_services('gitlab', Services::BaseServices.list)

Gitlab.from_file('/etc/gitlab/gitlab.rb') if File.exist?('/etc/gitlab/gitlab.rb')

node.consume_attributes(Gitlab.generate_config(node['fqdn']))
