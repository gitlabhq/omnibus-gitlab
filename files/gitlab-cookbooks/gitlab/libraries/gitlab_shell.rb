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
      git_data_dirs = Gitlab['git_data_dirs']
      git_data_dir = Gitlab['git_data_dir']
      return unless git_data_dirs.any? || git_data_dir
      gitaly_address = Gitaly.gitaly_address
      deprecated_key_used = 'git_data_dir' if git_data_dir

      Gitlab['gitlab_shell']['git_data_directories'] ||=
        if git_data_dirs.any?
          Hash[git_data_dirs.map do |name, data_directory|
            if data_directory.is_a?(String)
              deprecated_key_used = 'git_data_dirs'
              [name, { 'path' => data_directory }]
            else
              [name, data_directory]
            end
          end]
        else
          { 'default' => { 'path' => git_data_dir } }
        end

      # Show deprecated warning in yellow, and give a slight pause to increase awareness
      # @TODO these warnings should be displayed again at the end of reconfigure https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2533
      if deprecated_key_used
        warn_message = "Your #{deprecated_key_used} settings are deprecated.\nPlease update it to the following:\n\ngit_data_dirs(#{Chef::JSONCompat.to_json_pretty(Gitlab['gitlab_shell']['git_data_directories'])})\n\nPlease refer to https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory for updated documentation."
        Chef::Log.warn warn_message
        puts "\033[33mWARNING: #{warn_message}\033[0m"
        sleep 5
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
