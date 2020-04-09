require_relative 'object_proxy'
require_relative 'helpers/logging_helper'

module Gitlab
  class Deprecations
    class << self
      ATTRIBUTE_BLOCKS ||= %w[gitlab monitoring].freeze

      def list(existing_config = nil)
        # List of deprecations. Remember to convert underscores to hyphens for
        # the first level configurations (eg: gitlab_rails => gitlab-rails)
        #
        # `config_keys` represents a list of keys, which can be used to traverse
        # the configuration hash available from /opt/gitlab/embedded/nodes/{fqdn}json
        # to reach a specific configuration. For example %w(mattermost
        # log_file_directory) means `mattermost['log_file_directory']` setting.
        # Similarly, %w(gitlab nginx listen_addresses) means
        # `gitlab['nginx']['listen_addresses']`. We internally convert it to
        # nginx['listen_addresses'], which is what we use in /etc/gitlab/gitlab.rb
        deprecations = [
          {
            config_keys: %w(gitlab postgresql data_dir),
            deprecation: '11.6',
            removal: '14.0',
            note: "Please see https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory for how to use postgresql['dir']"
          },
          {
            config_keys: %w(gitlab gitlab-pages auth_server),
            deprecation: '12.0',
            removal: '13.0',
            note: "Use gitlab_server instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor enable),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['enable'] instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor log_directory),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['log_directory'] instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor home),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['home'] instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor listen_address),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['listen_address'] instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor listen_port),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['listen_port'] instead."
          },
          {
            config_keys: %w(monitoring gitlab-monitor probe_sidekiq),
            deprecation: '12.3',
            removal: '13.0',
            note: "Use gitlab_exporter['probe_sidekiq'] instead."
          },
          {
            config_keys: %w(gitlab gitlab-rails rack_attack_protected_paths),
            deprecation: '12.4',
            removal: '13.0',
            note: 'It is now configured via the admin area. Please see https://docs.gitlab.com/ee/user/admin_area/settings/protected_paths.html for details.'
          },
          {
            config_keys: %w(repmgr user),
            deprecation: '12.10',
            removal: '13.0',
            note: "Use repmgr['username'] instead."
          },
          {
            config_keys: %w(consul user),
            deprecation: '12.10',
            removal: '13.0',
            note: "Use consul['username'] instead."
          }
        ]

        deprecations
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
        matching_config = existing_config.dig(*config_keys)
        return [] unless matching_config

        deprecated_config = matching_config.select { |config| !allowed_keys.include?(config) }
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
        version_manifest = JSON.parse(File.read("/opt/gitlab/version-manifest.json"))
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
        current_deprecations.select { |deprecation| !existing_config.dig(*deprecation[:config_keys]).nil? }
      end

      def check_config(incoming_version, existing_config, type = :removal)
        messages = []
        deprecated_config = applicable_deprecations(incoming_version, existing_config, type)
        deprecated_config.each do |deprecation|
          config_keys = deprecation[:config_keys].dup
          config_keys.shift if ATTRIBUTE_BLOCKS.include?(config_keys[0])
          key = if config_keys.length == 1
                  config_keys[0].tr("-", "_")
                else
                  "#{config_keys[0].tr('-', '_')}['#{config_keys.drop(1).join("']['")}']"
                end

          if type == :deprecation
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and will be removed in #{deprecation[:removal]}."
          elsif type == :removal
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and was removed in #{deprecation[:removal]}."
          end
          message += " " + deprecation[:note] if deprecation[:note]
          messages << message
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
