#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

define :env_dir, :variables => Hash.new, :restarts => [] do
  env_dir = params[:name]

  directory env_dir do
    recursive true
  end

  restarts = params[:restarts]

  params[:variables].each do |key, value|
    file File.join(env_dir, key) do
      content value
      restarts.each do |svc|
        notifies :restart, svc
      end
    end
  end

  if File.directory?(env_dir)
    deleted_env_vars = Dir.entries(env_dir) - params[:variables].keys - %w{. ..}
    deleted_env_vars.each do |deleted_var|
      file File.join(env_dir, deleted_var) do
        action :delete
        restarts.each do |svc|
          notifies :restart, svc
        end
      end
    end
  end
end
