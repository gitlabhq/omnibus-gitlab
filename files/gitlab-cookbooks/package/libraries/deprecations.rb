module Gitlab
  class Deprecations
    class << self
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
            config_keys: %w(gitlab nginx listen_address),
            deprecation: '8.10',
            removal: '11.0',
            note: "Use nginx['listen_addresses'] instead."
          },
          {
            config_keys: %w(gitlab gitlab-rails stuck_ci_builds_worker_cron),
            deprecation: '9.0',
            removal: '11.0',
            note: "Use gitlab_rails['stuck_ci_jobs_worker_cron'] instead."
          },
          {
            config_keys: %w(gitlab gitlab-shell git_data_directories),
            deprecation: '8.10',
            removal: '11.0',
            note: "Use git_data_dirs instead."
          },
          {
            config_keys: %w(gitlab git-data-dir),
            deprecation: '8.10',
            removal: '11.0',
            note: "Use git_data_dirs instead."
          },
          {
            config_keys: %w(gitlab postgresql data_dir),
            deprecation: '11.6',
            removal: '14.0',
            note: "Please see https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory for how to use postgresql['dir']"
          }
        ]

        deprecations += identify_deprecated_config(existing_config, ['mattermost'], mattermost_supported_keys, "10.2", "11.0") if existing_config
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

      def mattermost_supported_keys
        %w(enable
           username
           group
           uid
           gid
           home
           database_name
           env
           host
           port
           svlogd_prefix
           service_site_url
           service_address
           service_port
           service_use_ssl
           service_allowed_untrusted_internal_connections
           service_enable_api_team_deletion
           team_site_name
           sql_driver_name
           sql_data_source
           sql_data_source_replicas
           sql_at_rest_encrypt_key
           log_file_directory
           file_directory
           gitlab_enable
           gitlab_secret
           gitlab_id
           gitlab_scope
           gitlab_auth_endpoint
           gitlab_token_endpoint
           gitlab_user_api_endpoint
           email_invite_salt
           file_public_link_salt
           plugin_directory
           plugin_client_directory)
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
        current_deprecations.select { |deprecation| existing_config.dig(*deprecation[:config_keys]) }
      end

      def check_config(incoming_version, existing_config, type = :removal)
        messages = []
        deprecated_config = applicable_deprecations(incoming_version, existing_config, type)
        deprecated_config.each do |deprecation|
          config_keys = deprecation[:config_keys].dup
          config_keys.shift if config_keys[0] == 'gitlab'
          key = if config_keys.length == 1
                  config_keys[0].tr("-", "_")
                else
                  "#{config_keys[0].tr('-', '_')}['#{config_keys.drop(1).join("']['")}']"
                end

          if type == :deprecation
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and will be removed in #{deprecation[:removal]}"
          elsif type == :removal
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and was removed in #{deprecation[:removal]}."
          end
          message += " " + deprecation[:note] if deprecation[:note]
          messages << message
        end
        messages
      end
    end
  end
end
