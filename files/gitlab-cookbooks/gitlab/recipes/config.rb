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

# Make node object available to libraries to access default values specified in
# attribute files
Gitlab[:node] = node

# Populate the service list. When using `roles`, services will get
# automatically enabled. For that, services should be already present in the
# list.
Services.add_services('gitlab', Services::BaseServices.list)

# Parse `/etc/gitlab/gitlab.rb` and populate Gitlab object
Gitlab.from_file('/etc/gitlab/gitlab.rb') if File.exist?('/etc/gitlab/gitlab.rb')

# Generate config hash with settings specified in gitlab.rb, computed default
# values for settings via parse_variable method, and secrets either loaded from
# gitlab-secrets.json file or created anew. After this point, `Gitlab` object
# will have values either read from `/etc/gitlab/gitlab.rb` or computed by the
# libraries.
generated_config = Gitlab.generate_config(node['fqdn'])

# Populate node objects with the config hash generated above. After this point,
# the node objects will have the final values to be used in recipes.
node.consume_attributes(generated_config)

# Override configuration with the one loaded from cluster.json file
NodeHelper.consume_cluster_attributes(node, GitlabCluster.config.all)
