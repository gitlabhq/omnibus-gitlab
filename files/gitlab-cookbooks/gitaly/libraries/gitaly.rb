#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require 'chef/mash'
require_relative '../../package/libraries/helpers/output_helper.rb'

module Gitaly
  class << self
    include OutputHelper

    def parse_variables
      parse_git_data_dirs
      parse_gitaly_storages
      detect_deprecated_settings
    end

    def gitaly_address
      socket_path = user_config['socket_path'] || package_default['socket_path']
      listen_addr = user_config['listen_addr'] || package_default['listen_addr']

      # Default to using socket path if available
      if socket_path && !socket_path.empty?
        "unix:#{socket_path}"
      elsif listen_addr && !listen_addr.empty?
        "tcp://#{listen_addr}"
      end
    end

    def detect_deprecated_settings
      git_data_dirs = Gitlab['git_data_dirs']
      deprecated_key_used = 'git_data_dir' if Gitlab['git_data_dir']
      if git_data_dirs.any?
        git_data_dirs.map do |name, data_directory|
          if data_directory.is_a?(String)
            deprecated_key_used = 'git_data_dirs'
            break
          end
        end
      end

      if deprecated_key_used # rubocop:disable Style/GuardClause
        warn_message = <<~EOS
          Your #{deprecated_key_used} settings are deprecated.
          Please update it to the following:

          git_data_dirs(#{print_ruby_object(converted_git_data_dirs)})

          Please refer to https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory for updated documentation.
        EOS
        LoggingHelper.deprecation warn_message
      end
    end

    def converted_git_data_dirs
      # Converting values in old formats to the correct, new one.
      # Before version 8.10 we used git_data_dir configuration, which had a string representing a path as value.
      # From version 8.10 till version 8.17.8, we used git_data_dirs configuration, which had a { <name> => <path> } hash as value.
      # Now, since version 9.0, git_data_dirs has a { <name> => {"path" => <path> } } hash as value.
      # So we convert all the old formats to the new one, until we remove the support of them.

      git_data_dirs = Gitlab['git_data_dirs']
      git_data_dir = Gitlab['git_data_dir']
      return { "default" => { "path" => "/var/opt/gitlab/git-data" } } unless git_data_dirs.any? || git_data_dir

      if git_data_dirs.any?
        Mash.new(Hash[git_data_dirs.map do |name, data_directory|
          if data_directory.is_a?(String)
            [name, { 'path' => data_directory }]
          else
            [name, data_directory]
          end
        end])
      else
        { 'default' => { 'path' => git_data_dir } }
      end
    end

    def parse_git_data_dirs
      Gitlab['gitlab_rails']['repositories_storages'] =
        Hash[converted_git_data_dirs.map do |name, data_directory|
          shard_gitaly_address = data_directory['gitaly_address'] || gitaly_address

          defaults = { 'path' => File.join(data_directory['path'], 'repositories'), 'gitaly_address' => shard_gitaly_address }
          params = data_directory.merge(defaults)

          [name, params]
        end]
    end

    def parse_gitaly_storages
      return unless Gitlab['gitaly']['storage'].nil?

      storages = []
      Gitlab['gitlab_rails']['repositories_storages'].each do |key, value|
        storages << {
          'name' => key,
          'path' => value['path']
        }
      end
      Gitlab['gitaly']['storage'] = storages
    end

    private

    def user_config
      Gitlab['gitaly']
    end

    def package_default
      Gitlab['node']['gitaly'].to_hash
    end
  end
end
