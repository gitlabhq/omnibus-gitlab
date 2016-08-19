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

# Manage the storage directory as the owner user instead of root when root_squash_safe is true
# if the owner user has write access to the directory
# Otherwise run the directory resource like normal
define :storage_directory, path: nil, owner: 'root', group: nil, mode: nil do
  params[:path] ||= params[:name]
  storage_helper = StorageDirectoryHelper.new(params[:path], params[:owner], params[:group], params[:mode])

  ruby_block "directory resource: #{params[:path]}" do
    block do
      # Ensure the directory exists
      storage_helper.run_command("mkdir -p #{params[:path]}", use_euid: storage_helper.writable?('..'))

      # Check the owner, and chown if needed
      if params[:owner] != storage_helper.run_command("stat --printf='%U' #{params[:path]}", use_euid: true).stdout
        begin
          FileUtils.chown(params[:owner], params[:group], params[:path])
        rescue Errno::EPERM
          Chef::Log.warn("Root cannot chown #{params[:path]}. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.")
          raise
        end
      end

      # Update the remaining directory permissions
      is_writable = storage_helper.writable?
      storage_helper.run_command("chmod #{params[:mode]} #{params[:path]}", use_euid: is_writable) if params[:mode]
      storage_helper.run_command("chgrp #{params[:group]} #{params[:path]}", use_euid: is_writable) if params[:group]

      # Test that directory is in expected state and error if not
      storage_helper.run_command(storage_helper.test_stat_cmd, use_euid: true)
    end
    not_if storage_helper.test_stat_cmd, user: params[:owner], group: params[:group]
  end
end
