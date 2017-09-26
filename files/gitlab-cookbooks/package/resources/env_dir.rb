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
property :restarts, Array, default: []

action :create do
  # Cleaning up non-existent variables
  if ::File.directory?(name)
    deleted_env_vars = Dir.entries(name) - variables.keys - %w(. ..)
    deleted_env_vars.each do |deleted_var|
      file ::File.join(name, deleted_var) do
        action :delete
        restarts.each do |svc|
          notifies :restart, svc
        end
      end
    end
  end

  directory name do
    recursive true
  end

  variables.each do |key, value|
    file ::File.join(name, key) do
      content value
      restarts.each do |svc|
        notifies :restart, svc
      end
    end
  end
end
