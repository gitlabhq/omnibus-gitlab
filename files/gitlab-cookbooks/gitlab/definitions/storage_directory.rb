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
define :storage_directory, path: nil, owner: 'root', group: nil, mode: nil, recursive: false do
  params[:path] ||= params[:name]

  group_ownership = ":#{params[:group]}" unless params[:group].nil?
  mode_flag = "-m #{params[:mode]} " unless params[:mode].nil?
  chmod_cmd = "chmod #{params[:mode]} #{params[:path]}" unless params[:mode].nil?

  bash "directory resource: #{params[:path]}" do
    code <<-EOS
      if [ -d "#{params[:path]}" ]; then
        chown #{params[:owner]}#{group_ownership} #{params[:path]}
        #{chmod_cmd}
      else
        mkdir #{mode_flag}-p #{params[:path]}
      fi
    EOS
    user params[:owner]
    group params[:group] if params[:group]
    only_if { node['gitlab']['manage-storage-directories']['root_squash_safe'] && StorageDirectoryHelper.writable?(params[:owner], File.dirname(params[:path])) }
  end

  directory params[:path] do
    owner params[:owner]
    group params[:group] if params[:group]
    mode params[:mode] if params[:mode]
    recursive params[:recursive]
    not_if { node['gitlab']['manage-storage-directories']['root_squash_safe'] && StorageDirectoryHelper.writable?(params[:owner], File.dirname(params[:path])) }
  end
end
