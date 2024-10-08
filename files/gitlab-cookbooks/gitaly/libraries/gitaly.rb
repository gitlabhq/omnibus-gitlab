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
require 'tomlib'
require_relative '../../package/libraries/helpers/output_helper.rb'

module Gitaly
  class << self
    include OutputHelper

    def parse_variables
      parse_git_data_dirs
      parse_gitaly_storages
      parse_gitconfig
      check_duplicate_storage_paths
    end

    def parse_secrets
      # The secret should be same between GitLab Rails, GitLab Shell, and
      # Gitaly. GitLab Shell has a priority of 10, which means it gets parsed
      # before Gitaly and Gitlab['gitlab_shell']['secret_token'] will
      # definitely have a value.
      Gitlab['gitaly']['gitlab_secret'] ||= Gitlab['gitlab_shell']['secret_token']

      LoggingHelper.warning("Gitaly and GitLab Shell specifies different secrets to authenticate with GitLab") if Gitlab['gitaly']['gitlab_secret'] != Gitlab['gitlab_shell']['secret_token']
    end

    def gitaly_address
      listen_addr = user_config.dig('configuration', 'listen_addr')         || package_default.dig('configuration', 'listen_addr')
      socket_path = user_config.dig('configuration', 'socket_path')         || package_default.dig('configuration', 'socket_path')
      tls_listen_addr = user_config.dig('configuration', 'tls_listen_addr') || package_default.dig('configuration', 'tls_listen_addr')

      # Default to using socket path if available
      if tls_listen_addr && !tls_listen_addr.empty?
        "tls://#{tls_listen_addr}"
      elsif socket_path && !socket_path.empty?
        "unix:#{socket_path}"
      elsif listen_addr && !listen_addr.empty?
        "tcp://#{listen_addr}"
      end
    end

    def parse_git_data_dirs
      Gitlab['git_data_dirs'] = { "default" => { "path" => "/var/opt/gitlab/git-data" } } if Gitlab['git_data_dirs'].empty?

      Gitlab['git_data_dirs'].map do |name, details|
        Gitlab['git_data_dirs'][name]['path'] = details[:path] || details['path'] || '/var/opt/gitlab/git-data'
      end

      Gitlab['gitlab_rails']['repositories_storages'] =
        Hash[Mash.new(Gitlab['git_data_dirs']).map do |name, data_directory|
          shard_gitaly_address = data_directory['gitaly_address'] || gitaly_address

          defaults = { 'path' => File.join(data_directory['path'], 'repositories'), 'gitaly_address' => shard_gitaly_address }
          params = data_directory.merge(defaults)

          [name, params]
        end]
    end

    def parse_gitaly_storages
      return unless Gitlab['gitaly'].dig('configuration', 'storage').nil?

      storages = []
      Gitlab['gitlab_rails']['repositories_storages'].each do |key, value|
        storages << {
          'name' => key,
          'path' => value['path']
        }
      end
      Gitlab['gitaly']['configuration'] ||= {}
      Gitlab['gitaly']['configuration']['storage'] = storages
    end

    # Compute the default gitconfig from the old Omnibus gitconfig setting.
    # This depends on the Gitlab cookbook having been parsed already.
    def parse_gitconfig
      # If the administrator has set `gitaly[:configuration][:git][:config]` then we do not add a
      # fallback gitconfig.
      return unless Gitlab['gitaly'].dig('configuration', 'git', 'config').nil?

      # Furthermore, if the administrator has not overridden the
      # `omnibus_gitconfig` we do not have to migrate anything either. Most
      # importantly, we are _not_ interested in migrating defaults.
      return if Gitlab['omnibus_gitconfig']['system'].nil?

      # We use the old system-level Omnibus gitconfig as the default value...
      omnibus_gitconfig = Gitlab['omnibus_gitconfig']['system'].flat_map do |section, entries|
        entries.map do |entry|
          key, value = entry.split('=', 2)

          raise "Invalid entry detected in omnibus_gitconfig['system']: '#{entry}' should be in the form key=value" if key.nil? || value.nil?

          "#{section}.#{key.strip}=#{value.strip}"
        end
      end

      # ... but remove any of its values that had been part of the default
      # configuration when introducing the Gitaly gitconfig. We do not want to
      # inject our old default values into Gitaly anymore given that it is
      # setting its own defaults nowadays. Furthermore, we must not inject the
      # `core.fsyncObjectFiles` config entry, which has been deprecated in Git.
      omnibus_gitconfig -= [
        'pack.threads=1',
        'receive.advertisePushOptions=true',
        'receive.fsckObjects=true',
        'repack.writeBitmaps=true',
        'transfer.hideRefs=^refs/tmp/',
        'transfer.hideRefs=^refs/keep-around/',
        'transfer.hideRefs=^refs/remotes/',
        'core.alternateRefsCommand="exit 0 #"',
        'core.fsyncObjectFiles=true',
        'fetch.writeCommitGraph=true'
      ]

      # The configuration format has changed. Previously, we had a map of
      # top-level config entry keys to their sublevel entry keys which also
      # included a value. The new format is an array of hashes with key and
      # value entries.
      gitaly_gitconfig = omnibus_gitconfig.map do |config|
        # Split up the `foo.bar=value` to obtain the left-hand and right-hand sides of the assignment
        section_subsection_and_key, value = config.split('=', 2)

        # We need to split up the left-hand side. This can either be of the
        # form `core.gc`, or of the form `http "http://example.com".insteadOf`.
        # We thus split from the right side at the first dot we see.
        key, section_and_subsection = section_subsection_and_key.reverse.split('.', 2)
        key.reverse!

        # And then we need to potentially split the section/subsection if we
        # have `http "http://example.com"` now.
        section, subsection = section_and_subsection.reverse!.split(' ', 2)
        subsection&.gsub!(/\A"|"\Z/, '')

        # So that we have finally split up the section, subsection, key and
        # value. It is fine for the `subsection` to be `nil` here in case there
        # is none.
        { 'section' => section, 'subsection' => subsection, 'key' => key, 'value' => value }
      end

      return unless gitaly_gitconfig.any?

      tmp_source_hash = {
        configuration: {
          git: {
            config: gitaly_gitconfig.map do |entry|
              {
                key: [entry['section'], entry['subsection'], entry['key']].compact.join('.'),
                value: entry['value']
              }
            end
          }
        }
      }

      Chef::Mixin::DeepMerge.deep_merge!(tmp_source_hash, Gitlab['gitaly'])
    end

    # Validate that no storages are sharing the same path.
    def check_duplicate_storage_paths
      # If Gitaly isn't running, there is no need to do this check.
      return unless Services.enabled?('gitaly')

      # Deep copy storages to avoid mutating the original.
      storages = Marshal.load(Marshal.dump(Gitlab['gitaly']['configuration']['storage']))

      storages.each do |storage|
        storage[:realpath] =
          begin
            File.realpath(storage[:path])
          rescue Errno::ENOENT
            storage[:path]
          end
      end

      realpath_duplicates = storages.group_by { |storage| storage[:realpath] }.select { |_, entries| entries.size > 1 }

      return if realpath_duplicates.empty?

      output = realpath_duplicates.map do |realpath, entries|
        names = entries.map { |s| s[:name] }.join(', ')
        "#{realpath}: #{names}"
      end

      raise "Multiple Gitaly storages are sharing the same filesystem path:\n  #{output.join('\n  ')}"
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
