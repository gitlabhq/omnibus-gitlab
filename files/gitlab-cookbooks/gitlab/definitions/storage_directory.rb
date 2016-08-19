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
  guard_command = StorageDirectoryHelper.test_stat_cmd(params[:path], params[:owner], params[:group], params[:mode])

  ruby_block "directory resource: #{params[:path]}" do
    block do
      owner_parent_writable = StorageDirectoryHelper.writable?(params[:owner], File.dirname(params[:path]))

      StorageDirectoryHelper.run_command(
        "mkdir -p #{params[:path]}",
        user: (params[:owner] if owner_parent_writable),
        group: (params[:group] if owner_parent_writable)
      )

      current_owner = StorageDirectoryHelper.run_command(
        "stat --printf='%U' #{params[:path]}",
        user: params[:owner],
        group: params[:group]
      ).stdout

      begin
        FileUtils.chown(params[:owner], params[:group], params[:path])
      rescue Errno::EPERM
        Chef::Log.warn("Root cannot chown #{params[:path]}. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.")
        raise
      end if current_owner != params[:owner]

      owner_writable = StorageDirectoryHelper.writable?(params[:owner], params[:path])

      StorageDirectoryHelper.run_command(
        "chmod #{params[:mode]} #{params[:path]}",
        user: (params[:owner] if owner_writable),
        group: (params[:group] if owner_writable)
      ) if params[:mode]

      StorageDirectoryHelper.run_command(
        "chgrp #{params[:group]} #{params[:path]}",
        user: (params[:owner] if owner_writable),
        group: (params[:group] if owner_writable)
      ) if params[:group]

      StorageDirectoryHelper.run_command(guard_command, user: params[:owner], group: params[:group])
    end
    not_if guard_command, user: params[:owner], group: params[:group]
  end
end
