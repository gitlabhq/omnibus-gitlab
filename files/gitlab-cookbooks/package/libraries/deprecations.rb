require_relative 'object_proxy'
require_relative 'helpers/logging_helper'
require_relative 'settings_dsl.rb'

module Gitlab
  class Deprecations
    class << self
      ATTRIBUTE_BLOCKS ||= %w[gitlab monitoring].freeze

      def list(existing_config = nil)
        # List of deprecations. Remember to convert underscores to hyphens for
        # the first level configurations (eg: gitlab_rails => gitlab-rails)
        # Use the following structure:
        # {
        #   config_keys: %w(<space separated list>),
        #   deprecation: '<version when deprecated>',
        #   removal: '<version when to be removed>' # <link to removal issue>
        #   note: '<Any extra notes>'
        # }
        #
        # `config_keys` represents a list of keys, which can be used to traverse
        # the configuration hash available from /opt/gitlab/embedded/nodes/{fqdn}json
        # to reach a specific configuration. For example %w(mattermost
        # log_file_directory) means `mattermost['log_file_directory']` setting.
        # Similarly, %w(gitlab nginx listen_addresses) means
        # `gitlab['nginx']['listen_addresses']`. We internally convert it to
        # nginx['listen_addresses'], which is what we use in /etc/gitlab/gitlab.rb
        #
        # If you need to deprecate configuration relating to a component entirely,
        # make use of the `identify_deprecated_config` method. You can do this
        # by adding a line like the following before the return statement of
        # this method.
        # deprecations += identify_deprecated_config(existing_config, ['gitlab', 'foobar'], {}, "13.12", "14.0", "Support for foobar will be removed in GitLab 14.0")
        [
          {
            config_keys: %w(registry default_notifications_threshold),
            deprecation: '17.1',
            removal: '19.0',
            note: "`registry['default_notifications_threshold'] will be removed in 19.0. Please use `default_notifications_maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243."
          },
          {
            config_keys: %w(gitlab gitlab_shell migration),
            deprecation: '17.4',
            removal: '18.0',
            note: "`gitlab_shell['migration'] will be ignored from 17.3 and removed in 18.0. See https://gitlab.com/groups/gitlab-org/-/epics/14845."
          },
        ]
      end

      def identify_deprecated_config(existing_config, config_keys, allowed_keys, deprecation, removal, note = nil)
        # Method to simplify deprecating a bulk of configuration related to a
        # component. In short, it generates and returns a list of deprecated
        # configuration from the complete list using a smaller list of
        # supported keys. The output is formatted as a list of hashes, similar
        # to the one from `GitLab::Deprecations.list` above.
        # The parameters are
        # 1. existing_config: The high level configuration from fqdn.json file
        # 2. config_keys: The keys that make up the hash which contains
        #                 configuration to be deprecated. Check comment inside
        #                 `list` method above for more details.
        # 3. allowed_keys: List of allowed keys
        # 4. deprecation: Version since which were the configurations deprecated
        # 5. removal: Version in which were the configurations removed
        # 6. note: General note regarding removal
        return [] unless existing_config

        matching_config = existing_config.dig(*config_keys)
        return [] unless matching_config

        deprecated_config = matching_config.reject { |config| allowed_keys.include?(config) }
        deprecated_config.keys.map do |key|
          {
            config_keys: config_keys + [key],
            deprecation: deprecation,
            removal: removal,
            note: note
          }
        end
      end

      def next_major_version
        version_manifest = JSON.load_file("/opt/gitlab/version-manifest.json")
        major_version = version_manifest['build_version'].split(".")[0]
        (major_version.to_i + 1).to_s
      rescue StandardError
        puts "Error reading /opt/gitlab/version-manifest.json. Please check if the file exists and JSON content in it is not malformed."
        puts "Checking for deprecated configuration failed."
      end

      def applicable_deprecations(incoming_version, existing_config, type)
        # Return the list of deprecations or removals that are applicable with
        # a given list of configuration for a specific version.
        incoming_version = next_major_version if incoming_version.empty?
        return [] unless incoming_version

        version = Gem::Version.new(incoming_version)

        # Getting settings from gitlab.rb that are in deprecations list and
        # has been removed in incoming or a previous version.
        current_deprecations = list(existing_config).select { |deprecation| version >= Gem::Version.new(deprecation[type]) }

        # If the value of the configuration is `nil` or an empty hash (in case
        # of root configurations where ConfigMash logic in SettingsDSL will set
        # an empty Hash as the default value), then the configuration is a
        # valid deprecation that user has to be warned about.
        current_deprecations.select { |deprecation| !(existing_config.dig(*deprecation[:config_keys]).nil? || (existing_config.dig(*deprecation[:config_keys]).is_a?(Hash) && existing_config.dig(*deprecation[:config_keys])&.empty?)) }
      end

      def check_config(incoming_version, existing_config, type = :removal)
        messages = []
        deprecated_config = applicable_deprecations(incoming_version, existing_config, type)
        deprecated_config.each do |deprecation|
          config_keys = deprecation[:config_keys].dup
          config_keys.shift if ATTRIBUTE_BLOCKS.include?(config_keys[0])
          key = if config_keys.length == 1
                  SettingsDSL::Utils.node_attribute_key(config_keys[0])
                elsif config_keys.first.eql?('roles')
                  "#{SettingsDSL::Utils.node_attribute_key(config_keys[1])}_role"
                else
                  "#{SettingsDSL::Utils.node_attribute_key(config_keys[0])}['#{config_keys.drop(1).join("']['")}']"
                end

          if type == :deprecation
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and will be removed in #{deprecation[:removal]}."
          elsif type == :removal
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and was removed in #{deprecation[:removal]}."
          end
          message += " " + deprecation[:note] if deprecation[:note]
          messages << message
        end

        messages += additional_deprecations(incoming_version, existing_config, type)

        messages
      end

      def additional_deprecations(incoming_version, existing_config, type)
        messages = []

        messages += deprecate_registry_notifications(incoming_version, existing_config, type, ['registry', 'notifications'], 'threshold', 17.1, 19.0)

        messages += remove_git_data_dirs(incoming_version, existing_config, type, '17.8', '18.0')

        messages += remove_gitaly_use_bundled_binaries(incoming_version, existing_config, type, '18.3', '19.0')
        messages += remove_gitaly_bin_path(incoming_version, existing_config, type, '18.3', '19.0')

        messages
      end

      def deprecate_only_if_value(incoming_version, existing_config, type, config_keys, key, value, deprecated_version, removed_version, note: nil, ignore_deprecation: false) # rubocop:disable Metrics/ParameterLists
        setting = existing_config.dig(*config_keys) || {}

        return [] unless setting.key?(key)

        # Return empty array if the setting is either nil or an empty collection (Array, Hash, etc.).
        # `to_h` will convert `nil` to an empty array.
        return [] if setting[key].respond_to?(:to_h) && setting[key].to_h.empty?

        # Do not add messages for removals. We only handle deprecations here.
        return [] if type == :removal && setting[key] != value

        config_keys.shift if ATTRIBUTE_BLOCKS.include?(config_keys[0])
        messages = []

        if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
          message = "* #{config_keys[0]}[#{key}] has been deprecated since #{deprecated_version} and was removed in #{removed_version}."
          message += " #{note}" if note
          messages << message
        elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation && !ignore_deprecation
          message =  "* #{config_keys[0]}[#{key}] has been deprecated since #{deprecated_version} and will be removed in #{removed_version}."
          message += " #{note}" if note
          messages << message
        end

        messages
      end

      def remove_git_data_dirs(incoming_version, existing_config, type, deprecated_version, removed_version)
        applied_config = existing_config.dig('gitlab', 'git_data_dirs')
        return [] if applied_config.nil? || applied_config.empty?

        messages = []

        if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
          messages << "* git_data_dirs has been deprecated since #{deprecated_version} and was removed in #{removed_version}. See https://docs.gitlab.com/omnibus/settings/configuration.html#migrating-from-git_data_dirs for migration instructions."
        elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation
          messages << "* git_data_dirs has been deprecated since #{deprecated_version} and will be removed in #{removed_version}. See https://docs.gitlab.com/omnibus/settings/configuration.html#migrating-from-git_data_dirs for migration instructions."
        end

        messages
      end

      def remove_gitaly_use_bundled_binaries(incoming_version, config, type, deprecated_version, removed_version)
        messages = []

        unless config.dig('gitaly', 'configuration', 'git', 'use_bundled_binaries').nil?
          if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
            messages << "* gitaly['configuration']['git']['use_bundled_binaries'] has been deprecated since #{deprecated_version} and is ignored by Gitaly. Bundled Git is now the default and only supported method. Support for this setting in `gitlab.rb` was removed in #{removed_version}."
          elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation
            messages << "* gitaly['configuration']['git']['use_bundled_binaries'] has been deprecated since #{deprecated_version} and is ignored by Gitaly. Bundled Git is now the default and only supported method. Support for this setting in `gitlab.rb` will be removed in #{removed_version}."
          end
        end

        messages
      end

      def remove_gitaly_bin_path(incoming_version, config, type, deprecated_version, removed_version)
        messages = []

        unless config.dig('gitaly', 'configuration', 'git', 'bin_path').nil?
          if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
            messages << "* gitaly['configuration']['git']['bin_path'] has been deprecated since #{deprecated_version} and is ignored by Gitaly. Bundled Git is now the default and only supported method. Support for this setting in `gitlab.rb` was removed in #{removed_version}."
          elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation
            messages << "* gitaly['configuration']['git']['bin_path'] has been deprecated since #{deprecated_version} and is ignored by Gitaly. Bundled Git is now the default and only supported method. Support for this setting in `gitlab.rb` will be removed in #{removed_version}."
          end
        end

        messages
      end

      def deprecate_registry_notifications(incoming_version, existing_config, type, config_keys, key, deprecated_version, removed_version)
        settings = existing_config.dig(*config_keys) || []

        return [] if settings.empty?

        notifications_note =
          case key
          when "threshold"
            <<~EOS
              Starting with GitLab 19.0, `registry['notifications'][{'threshold'=> value}] will be removed.
              Please use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
            EOS
          else
            ""
          end

        messages = []
        settings.to_a.each do |setting|
          next unless setting.key?(key)

          if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
            message = "* #{config_keys[0]}['#{config_keys[1]}'][{#{key} => value}] has been deprecated since #{deprecated_version} and was removed in #{removed_version}."
            message += " #{notifications_note}"
            messages << message
          elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation
            message =  "*#{config_keys[0]}['#{config_keys[1]}'][{#{key} => value}] has been deprecated since #{deprecated_version} and will be removed in #{removed_version}."
            message += " #{notifications_note}"
            messages << message
          end
        end

        messages
      end
    end

    class NodeAttribute < ObjectProxy
      def self.log_deprecations?
        @log_deprecations || false
      end

      def self.log_deprecations=(value = true)
        @log_deprecations = !!value
      end

      def initialize(target, var_name, new_var_name)
        @target = target
        @var_name = var_name
        @new_var_name = new_var_name
      end

      def method_missing(method_name, *args, &block) # rubocop:disable Style/MissingRespondToMissing
        deprecated_msg(caller[0..2]) if NodeAttribute.log_deprecations?
        super
      end

      private

      def deprecated_msg(*called_from)
        called_from = called_from.flatten
        msg = "Accessing #{@var_name} is deprecated. Support will be removed in a future release. \n" \
              "Please update your cookbooks to use #{@new_var_name} in place of #{@var_name}. Accessed from: \n"
        called_from.each { |l| msg << "#{l}\n" }
        LoggingHelper.deprecation(msg)
      end
    end
  end
end
