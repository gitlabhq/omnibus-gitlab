#
# Copyright:: Copyright (c) 2015 Chris Marchesi
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
resource_name :ssh_keygen
provides :ssh_keygen

actions :create, :delete
default_action :create

property :path, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: lazy { owner }
property :strength, equal_to: [2048, 4096], default: 2048
property :type, equal_to: ['rsa'], default: 'rsa'
property :comment, String, default: lazy { "#{owner}@#{node['hostname']}" }
property :passphrase, String, default: nil
property :secure_directory, TrueClass, default: nil

action_class do
  include SSHKeygen::Helper

  def key_exists?
    ::File.exist?(new_resource.path)
  end
end

action :create do
  notifying_block do
    unless key_exists?
      create_key
      save_private_key
      save_public_key
      update_directory_permissions

      new_resource.updated_by_last_action(true)
    end
  end
end
