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
        deprecations = [
          {
            config_keys: %w(gitlab postgresql data_dir),
            deprecation: '11.6',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4806
            note: "Please see https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory for how to use postgresql['dir']"
          },
          {
            config_keys: %w(gitlab sidekiq cluster),
            deprecation: '13.0',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6136
            note: "Running sidekiq directly is deprecated. Please see https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html for how to use sidekiq-cluster."
          },
          {
            config_keys: %w(roles redis-slave enable),
            deprecation: '13.0',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5349
            note: 'Use redis_replica_role instead.'
          },
          {
            config_keys: %w(redis client_output_buffer_limit_slave),
            deprecation: '13.0',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5349
            note: 'Use client_output_buffer_limit_replica instead'
          },
          {
            config_keys: %w(gitlab gitlab-pages http_proxy),
            deprecation: '13.1',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6137
            note: "Set gitlab_pages['env']['http_proxy'] instead. See https://docs.gitlab.com/omnibus/settings/environment-variables.html"
          },
          {
            config_keys: %w(praefect failover_read_only_after_failover),
            deprecation: '13.3',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5571
            note: "Read-only mode is repository specific and always enabled after suspected data loss. See https://docs.gitlab.com/ee/administration/gitaly/praefect.html#read-only-mode"
          },
          {
            config_keys: %w(gitlab geo-secondary db_fdw),
            deprecation: '13.3',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6138
            note: "Geo does not require Foreign Data Wrapper (FDW) to be configured to replicate data."
          },
          {
            config_keys: %w(gitlab geo-postgresql fdw_external_user),
            deprecation: '13.3',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6138
            note: "Geo does not require Foreign Data Wrapper (FDW) to be configured to replicate data."
          },
          {
            config_keys: %w(gitlab geo-postgresql fdw_external_password),
            deprecation: '13.3',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6138
            note: "Geo does not require Foreign Data Wrapper (FDW) to be configured to replicate data."
          },
          {
            config_keys: %w(gitlab gitlab-rails extra_piwik_site_id),
            deprecation: '13.7',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6139
            note: "Piwik config keys have been renamed to reflect the rebranding to Matomo. Please update gitlab_rails['extra_piwik_site_id'] to gitlab_rails['extra_matomo_site_id']."
          },
          {
            config_keys: %w(gitlab gitlab-rails extra_piwik_url),
            deprecation: '13.7',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6139
            note: "Piwik config keys have been renamed to reflect the rebranding to Matomo. Please update gitlab_rails['extra_piwik_url'] to gitlab_rails['extra_matomo_url']."
          },
          {
            config_keys: %w(gitlab sidekiq-cluster experimental_queue_selector),
            deprecation: '13.6',
            removal: '14.0', # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/646
            note: 'The experimental_queue_selector option is now called queue_selector.'
          },
          {
            config_keys: %w(gitlab sidekiq experimental_queue_selector),
            deprecation: '13.6',
            removal: '14.0', # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/646
            note: 'The experimental_queue_selector option is now called queue_selector.'
          },
          {
            config_keys: %w(gitlab gitlab-rails analytics_instance_statistics_count_job_trigger_worker_cron),
            deprecation: '13.10',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6003
            note: 'The config have been renamed, use analytics_usage_trends_count_job_trigger_worker_cron option.'
          },
          {
            config_keys: %w(gitlab-pages domain_config_source),
            deprecation: '13.9',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6033
            note: "Starting with GitLab 14.0, GitLab Pages only supports API-based configuration. Check https://docs.gitlab.com/ee/administration/pages/#deprecated-domain_config_source for details."
          },
          {
            config_keys: %w(gitlab nginx gzip),
            deprecation: '13.12',
            removal: '14.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6122
            note: "The config has been deprecated. Value for this directive in NGINX configuration will be controlled by `nginx['gzip_enabled']` setting in `/etc/gitlab/gitlab.rb`."
          },
          {
            config_keys: %w(gitlab-pages use_legacy_storage),
            deprecation: '14.0',
            removal: '14.3', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6166
            note: "This parameter was introduced as a temporary solution in case of unforseen problems with new storage format. It will be removed in 14.3. If you use this parameter, please comment on https://gitlab.com/gitlab-org/gitlab/-/issues/331699"
          },
          {
            config_keys: %w(gitlab-pages daemon-inplace-chroot),
            deprecation: '14.4',
            removal: '15.0',
            note: "Starting with GitLab 14.3, chroot has been removed along with disk-based configuration source. Because of this, the flag is a no-op and can be removed."
          },
          {
            config_keys: %w(praefect database_host_no_proxy),
            deprecation: '14.0',
            removal: '15.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6150
            note: "Use `praefect['database_direct_host']` instead."
          },
          {
            config_keys: %w(praefect database_port_no_proxy),
            deprecation: '14.0',
            removal: '15.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6150
            note: "Use `praefect['database_direct_port']` instead."
          },
          {
            config_keys: %w(gitlab gitlab-shell custom_hooks_dir),
            deprecation: '14.3',
            removal: '15.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6393
            note: "Use `gitaly['custom_hooks_dir']` instead."
          },
          {
            config_keys: %w(gitlab actioncable enable),
            deprecation: '14.5',
            removal: '15.0',
            note: "Starting with GitLab 14.5, Action Cable is enabled all the time. Because of this, the flag is a no-op and can be removed."
          },
          {
            config_keys: %w(gitaly internal_socket_dir),
            deprecation: '14.10',
            removal: '15.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6758
            note: "Use `gitaly['runtime_dir']` instead."
          },
          {
            config_keys: %w(gitlab gitlab-rails object_store connection openstack_username),
            deprecation: '14.9',
            removal: '15.0',
            note: "Update object storage configuration to use S3 API instead of SWIFT."
          },
          {
            config_keys: %w(gitlab gitlab-rails object_store connection rackspace_username),
            deprecation: '14.9',
            removal: '15.0',
            note: "Migrate object storage to another provider other than Rackspace."
          },
          {
            config_keys: %w(gitlab gitlab-rails pseudonymizer_manifest),
            deprecation: '14.7',
            removal: '15.0',
            note: "Starting with GitLab 14.7, Pseudonymizer has been deprecated and will be removed."
          },
          {
            config_keys: %w(gitlab gitlab-rails pseudonymizer_upload_remote_directory),
            deprecation: '14.7',
            removal: '15.0',
            note: "Starting with GitLab 14.7, Pseudonymizer has been deprecated and will be removed."
          },
          {
            config_keys: %w(gitlab gitlab-rails pseudonymizer_upload_connection),
            deprecation: '14.7',
            removal: '15.0',
            note: "Starting with GitLab 14.7, Pseudonymizer has been deprecated and will be removed."
          },
          {
            config_keys: %w(gitlab gitlab-rails pseudonymizer_worker_cron),
            deprecation: '14.7',
            removal: '15.0',
            note: "Starting with GitLab 14.7, Pseudonymizer has been deprecated and will be removed."
          },
          {
            config_keys: %w(gitlab gitlab-shell http_settings self_signed_cert),
            deprecation: '14.8',
            removal: '15.0', # https://gitlab.com/gitlab-org/gitlab-shell/-/issues/120
            note: "Starting with GitLab 14.8, SelfSignedCert has been deprecated and will be removed. Install self-signed certificates into `/etc/gitlab/trusted-certs` instead."
          },
          {
            config_keys: %w(gitlab gitlab-rails artifacts_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails artifacts_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails external_diffs_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails external_diffs_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails lfs_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails lfs_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails uploads_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails uploads_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails packages_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails packages_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails dependency_proxy_object_store_direct_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitlab gitlab-rails dependency_proxy_object_store_background_upload),
            deprecation: '14.9',
            removal: '15.0',
            note: "Starting with GitLab 15.0, only direct uploads will be permitted deprecating this configuration key."
          },
          {
            config_keys: %w(gitaly cgroups_count),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_repositories_count']` instead."
          },
          {
            config_keys: %w(gitaly cgroups_memory_enabled),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_memory_bytes'] or gitaly['cgroups_repositories_memory_bytes'] instead."
          },
          {
            config_keys: %w(gitaly cgroups_memory_limit),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_memory_bytes'] or gitaly['cgroups_repositories_memory_bytes'] instead."
          },
          {
            config_keys: %w(gitaly cgroups_cpu_enabled),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_cpu_shares'] or gitaly['cgroups_repositories_cpu_shares'] instead."
          },
          {
            config_keys: %w(gitaly ruby_rugged_git_config_search_path),
            deprecation: '15.1',
            removal: '15.1',
            note: "Starting with GitLab 15.1, Rugged does not read the Git configuration anymore. Instead, Gitaly knows to configure Rugged as required."
          },
          {
            config_keys: %w(praefect separate_database_metrics),
            deprecation: '15.5',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7072
            note: "Starting with GitLab 16.0, Praefect DB metrics will no longer be available on `/metrics` and must be scraped from `/db_metrics`."
          },
          {
            config_keys: %w(gitlab gitlab-rails enable_jemalloc),
            deprecation: '15.5',
            removal: '15.5',
            note: "Starting with GitLab 15.5, jemalloc is compiled in with the Ruby interpreter and can no longer be disabled."
          },
          {
            config_keys: %w(gitlab gitlab-rails gitlab_default_can_create_group),
            deprecation: '15.5',
            removal: '16.0',
            note: "Starting with GitLab 15.5, this setting cannot be controlled via the configuration file anymore. Follow the steps at https://docs.gitlab.com/ee/user/admin_area/settings/account_and_limit_settings.html#prevent-users-from-creating-top-level-groups, to configure this setting via the Admin UI or the API"
          }
        ]

        deprecations += identify_deprecated_config(existing_config, ['gitlab', 'unicorn'], ['enable', 'svlogd_prefix'], "13.10", "14.0", "Starting with GitLab 14.0, Unicorn is no longer supported and users must switch to Puma, following https://docs.gitlab.com/ee/administration/operations/puma.html.")
        deprecations += identify_deprecated_config(existing_config, ['repmgr'], ['enable'], "13.3", "14.0", "Starting with GitLab 14.0, Repmgr is no longer supported and users must switch to Patroni, following https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#switching-from-repmgr-to-patroni.")
        deprecations += identify_deprecated_config(existing_config, ['repmgrd'], ['enable'], "13.3", "14.0", "Starting with GitLab 14.0, Repmgr is no longer supported and users must switch to Patroni, following https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#switching-from-repmgr-to-patroni.")

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
                  SettingsDSL::Utils.underscored_form(config_keys[0])
                elsif config_keys.first.eql?('roles')
                  "#{SettingsDSL::Utils.underscored_form(config_keys[1])}_role"
                else
                  "#{SettingsDSL::Utils.underscored_form(config_keys[0])}['#{config_keys.drop(1).join("']['")}']"
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
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['gitlab', 'unicorn'], 'enable', true, '13.10', '14.0')
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['repmgr'], 'enable', true, '13.3', '14.0')
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['repmgrd'], 'enable', true, '13.3', '14.0')

        praefect_note = <<~EOS
          From GitLab 14.0 onwards, the `per_repository` will be the only available election strategy.
          Migrate to repository-specific primary nodes following
          https://docs.gitlab.com/ee/administration/gitaly/praefect.html#migrate-to-repository-specific-primary-gitaly-nodes.
        EOS
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['praefect'], 'failover_election_strategy', 'sql', '13.12', '14.0', note: praefect_note, ignore_deprecation: true)
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['praefect'], 'failover_election_strategy', 'local', '13.12', '14.0', note: praefect_note, ignore_deprecation: true)

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
