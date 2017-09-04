#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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
require_relative 'gitaly.rb'

module GitlabShell
  class << self
    def parse_variables
      parse_git_data_dirs
      parse_auth_file
    end

    def parse_git_data_dirs
      git_data_dirs = Gitlab['git_data_dirs']
      git_data_dir = Gitlab['git_data_dir']
      return unless git_data_dirs.any? || git_data_dir
      gitaly_address = Gitaly.gitaly_address

      Gitlab['gitlab_shell']['git_data_directories'] ||=
        if git_data_dirs.any?
          Hash[git_data_dirs.map do |name, data_directory|
            if data_directory.is_a?(String)
              Chef::Log.warn "Your git_data_dirs settings are deprecated. Please refer to https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory for updated documentation."
              [name, { 'path' => data_directory }]
            else
              [name, data_directory]
            end
          end]
        else
          { 'default' => { 'path' => git_data_dir } }
        end

      Gitlab['gitlab_rails']['repositories_storages'] ||=
        Hash[Gitlab['gitlab_shell']['git_data_directories'].map do |name, data_directory|
          shard_gitaly_address = data_directory['gitaly_address'] || gitaly_address

          defaults = { 'path' => File.join(data_directory['path'], 'repositories'), 'gitaly_address' => shard_gitaly_address }
          params = data_directory.merge(defaults)

          [name, params]
        end]
    end

    def parse_auth_file
      Gitlab['user']['home'] ||=  Gitlab['node']['gitlab']['user']['home']
      Gitlab['gitlab_shell']['auth_file'] ||=  File.join(Gitlab['user']['home'], '.ssh', 'authorized_keys')
    end
  end
end
