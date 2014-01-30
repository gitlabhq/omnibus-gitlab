#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'openssl'

ENV['PATH'] = "/opt/gitlab/bin:/opt/gitlab/embedded/bin:#{ENV['PATH']}"

directory "/etc/gitlab" do
  owner "root"
  group "root"
  mode "0775"
  action :nothing
end.run_action(:create)

if File.exists?("/etc/gitlab/gitlab.json")
  Chef::Log.warn("Please move to /etc/gitlab/gitlab.rb for configuration - /etc/gitlab/gitlab.json is deprecated.")
else
  GitLab[:node] = node
  if File.exists?("/etc/gitlab/gitlab.rb")
    GitLab.from_file("/etc/gitlab/gitlab.rb")
  end
  node.consume_attributes(GitLab.generate_config(node['fqdn']))
end

if File.exists?("/var/opt/gitlab/bootstrapped")
	node.set['gitlab']['bootstrap']['enable'] = false
end

# Create the Chef User
include_recipe "gitlab::users"

directory "/etc/chef" do
  owner "root"
  group node['gitlab']['user']['username']
  mode "0775"
  action :create
end

directory "/var/opt/gitlab" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

# Install our runit instance
include_recipe "runit"

# Configure Services
[
  "rabbitmq",
  "postgresql",
  "chef-solr",
  "chef-expander",
  "bookshelf",
  "erchef",
  "bootstrap",
  "gitlab-webui",
  "nginx"
].each do |service|
  if node["gitlab"][service]["enable"]
    include_recipe "gitlab::#{service}"
  else
    include_recipe "gitlab::#{service}_disable"
  end
end

include_recipe "gitlab::chef-pedant"

file "/etc/gitlab/gitlab-running.json" do
  owner node['gitlab']['user']['username']
  group "root"
  mode "0600"
  content Chef::JSONCompat.to_json_pretty({ "gitlab" => node['gitlab'].to_hash, "run_list" => node.run_list })
end
