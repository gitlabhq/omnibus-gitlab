module Praefect
  class << self
    def parse_variables
      parse_election_strategy
      parse_virtual_storages
    end

    # parse_election_strategy determines which election strategy to use by default if the election strategy has not
    # been explicitly configured. If this is the first time Praefect is being configured, the configuration file does
    # not yet exist. In such cases, we'll enable per_repository elector directly. If the configuration file exists,
    # and does not contain per_repository elector, then the installation has been using the previous default value of
    # sql elector. In such cases, we'll keep using it. Deprecation message is logged if the election strategy is
    # determined to be anything other than per_repository elector.
    def parse_election_strategy
      unless Gitlab['praefect']['failover_election_strategy']
        praefect_dir = Gitlab['praefect']['dir'] || Gitlab['node']['praefect']['dir']
        config_path = File.join(praefect_dir, 'config.toml')

        begin
          per_repository_configured = !File.foreach(config_path).grep(/election_strategy = 'per_repository'/).empty?
          # The previous behavior was to use 'sql' election strategy unless something else was explicitly configured.
          # Given that, it's fine to fallback to 'sql' if the config does not contain 'per_repository'
          # election strategy. If the config contains 'per_repository' but the value was not explicitly set, then we've
          # enabled 'per_repository' elector on first reconfigure of Praefect.
          Gitlab['praefect']['failover_election_strategy'] = per_repository_configured ? 'per_repository' : 'sql'
        rescue Errno::ENOENT
          # This is the first reconfigure of Praefect and the configuration file does not exist. If the
          # election strategy has not been configured explicitly, we should default to using the recommended one.
          Gitlab['praefect']['failover_election_strategy'] = 'per_repository'
        end
      end

      return if Gitlab['praefect']['failover_election_strategy'] == 'per_repository'

      LoggingHelper.deprecation(
        <<~EOS
          From GitLab 14.0 onwards, the `per_repository` will be the only available election strategy.
          Migrate to repository-specific primary nodes following
          https://docs.gitlab.com/ee/administration/gitaly/praefect.html#migrate-to-repository-specific-primary-gitaly-nodes.
        EOS
      )
    end

    # parse_virtual_storages converts the virtual storage's config object in to a format that better represents
    # the structure of Praefect's virtual storage configuration. Historically, virtual storages were configured
    # in omnibus as a hash of virtual storage names to nodes by name. parse_virtual_storages retains backwards
    # compatibility with this by moving unknown keys in a virtual storage's config under the 'nodes' key.
    def parse_virtual_storages
      return if Gitlab['praefect']['virtual_storages'].nil?

      raise "Praefect virtual_storages must be a hash" unless Gitlab['praefect']['virtual_storages'].is_a?(Hash)

      # These are the known keys of virtual storage's configuration. Values under
      # these keys are placed in to the root of the virtual storage's configuration. Unknown
      # keys are assumed to be nodes of the virtual storage and are moved under the 'nodes'
      # key.
      known_keys = ['default_replication_factor']
      deprecation_logged = false

      virtual_storages = {}
      Gitlab['praefect']['virtual_storages'].map do |virtual_storage, config_keys|
        raise "nodes of a Praefect virtual_storage must be a hash" unless config_keys.is_a?(Hash)

        config = { 'nodes' => config_keys['nodes'] || {} }
        config_keys.map do |key, value|
          next if key == 'nodes'

          if known_keys.include? key
            config[key] = value
            next
          end

          unless deprecation_logged
            LoggingHelper.deprecation(
              <<~EOS
                Configuring the Gitaly nodes directly in the virtual storage's root configuration object has
                been deprecated in GitLab 13.12 and will no longer be supported in GitLab 15.0. Move the Gitaly
                nodes under the 'nodes' key as described in step 6 of https://docs.gitlab.com/ee/administration/gitaly/praefect.html#praefect.
              EOS
            )
            deprecation_logged = true
          end

          raise "Virtual storage '#{virtual_storage}' contains duplicate configuration for node '#{key}'" if config['nodes'][key]

          config['nodes'][key] = value
        end

        virtual_storages[virtual_storage] = config
      end

      Gitlab['praefect']['virtual_storages'] = virtual_storages
    end
  end
end
