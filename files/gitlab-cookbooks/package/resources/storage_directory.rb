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

resource_name :storage_directory
provides :storage_directory

actions :create
default_action :create

unified_mode true

property :path, [String, nil], default: nil
property :owner, [String, nil], default: 'root'
property :group, [String, nil], default: nil
property :mode, [String, nil], default: nil

action :create do
  next unless node['gitlab']['manage-storage-directories']['enable']

  new_resource.path ||= new_resource.name
  storage_helper = StorageDirectoryHelper.new(new_resource.owner, new_resource.group, new_resource.mode)

  ruby_block "directory resource: #{new_resource.path}" do
    block do
      # Ensure the directory exists
      storage_helper.ensure_directory_exists(new_resource.path)

      # Ensure the permissions are set
      storage_helper.ensure_permissions_set(new_resource.path)

      # Error out if we have not achieved the target permissions
      storage_helper.validate!(new_resource.path)
    end
    not_if { storage_helper.validate(new_resource.path) }
  end
end
