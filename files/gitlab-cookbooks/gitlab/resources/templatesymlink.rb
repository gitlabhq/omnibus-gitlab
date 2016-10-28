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
property :variables, Hash, default: {}
property :helpers, Module, default: SingleQuoteHelper
property :notifies, Array
property :restarts, Array, default: []


action :create do
  template link_to do
    source new_resource.source
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    variables new_resource.variables
    helpers new_resource.helpers
    notifies *(new_resource.notifies) if new_resource.notifies
    restarts.each do |resource|
      notifies :restart, resource
    end
    action :create
  end

  link "Link #{link_from} to #{link_to}" do
    target_file link_from
    to link_to
    action :create
    restarts.each do |resource|
      notifies :restart, resource
    end
  end
end

action :delete do
  template link_to do
    action :delete
  end

  link "Link #{link_from} to #{link_to}" do
    action :delete
  end
end
