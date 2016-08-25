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

# Manage the storage directory as the target owner user instead of the running
# user in order to work with root_squash directories on NFS mounts. It will
# fallback to using root if the target owner user doesn't have enough access
define :storage_directory, path: nil, owner: 'root', group: nil, mode: nil do
  next unless node['gitlab']['manage-storage-directories']['enable']

  params[:path] ||= params[:name]
  storage_helper = StorageDirectoryHelper.new(params[:owner], params[:group], params[:mode])

  ruby_block "directory resource: #{params[:path]}" do
    block do
      # Ensure the directory exists
      storage_helper.ensure_directory_exists(params[:path])

      # Ensure the permissions are set
      storage_helper.ensure_permissions_set(params[:path])

      # Error out if we have not achieved the target permissions
      storage_helper.validate!(params[:path])
    end
    not_if { storage_helper.validate(params[:path]) }
  end
end
