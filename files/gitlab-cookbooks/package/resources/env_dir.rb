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

resource_name :env_dir
provides :env_dir

actions :create
default_action :create

property :variables, Hash, default: {}

action :create do
  resource_updated = false

  # Cleaning up non-existent variables
  if ::File.directory?(new_resource.name)
    deleted_env_vars = Dir.entries(new_resource.name) - new_resource.variables.keys - %w(. ..)
    deleted_env_vars.each do |deleted_var|
      file ::File.join(new_resource.name, deleted_var) do
        action :delete
      end
    end
    resource_updated ||= !deleted_env_vars.empty?
  end

  d = directory new_resource.name do
    recursive true
  end
  resource_updated ||= d.updated_by_last_action?

  new_resource.variables.each do |key, value|
    f = file ::File.join(new_resource.name, key) do
      content value
    end
    resource_updated ||= f.updated_by_last_action?
  end

  # This resource changed if the template create changed
  new_resource.updated_by_last_action(resource_updated)
end
