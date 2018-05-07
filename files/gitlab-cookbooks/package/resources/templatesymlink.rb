#
# Copyright:: Copyright (c) 2016 GitLab Inc
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
resource_name :templatesymlink
provides :templatesymlink

actions :create, :delete
default_action :create

property :link_from, String
property :link_to, String
property :source, String
property :owner, String
property :group, String
property :mode, String
property :cookbook, String
property :variables, Hash, default: {}
property :helpers, Module, default: OutputHelper

action :create do
  template new_resource.link_to do
    source new_resource.source
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    cookbook new_resource.cookbook if new_resource.cookbook
    variables new_resource.variables
    helpers new_resource.helpers
    sensitive new_resource.sensitive
    action :create
  end

  link "Link #{new_resource.link_from} to #{new_resource.link_to}" do
    target_file new_resource.link_from
    to new_resource.link_to
    action :create
  end
end

action :delete do
  file new_resource.link_to do
    action :delete
  end

  link new_resource.link_from do
    action :delete
  end
end
