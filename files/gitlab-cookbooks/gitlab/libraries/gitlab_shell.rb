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

    def parse_secrets
      Gitlab['gitlab_shell']['secret_token'] ||= SecretsHelper.generate_hex(64)
    end

    def parse_git_data_dirs
      # Make sure we inform the user that they are using configuration that is
      # not supported.
      raise 'Encountered unsupported config key \'git_data_dir\' in /etc/gitlab/gitlab.rb.' if Gitlab['git_data_dir']

      git_data_dirs = Gitlab['git_data_dirs']
      return unless git_data_dirs.any?
      git_data_dirs.select{ |k,v| raise 'Unsupported configuration detected in \'git_data_dirs\' in /etc/gitlab/gitlab.rb.' if v.is_a?(String)}

      gitaly_address = Gitaly.gitaly_address

      Gitlab['gitlab_shell']['git_data_directories'] ||= git_data_dirs
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
