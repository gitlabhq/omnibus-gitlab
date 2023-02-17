require 'tomlib'

module Praefect
  class << self
    def parse_variables
      parse_virtual_storages

      remap_legacy_values
      check_array_entries
    end

    # remap_legacy_values moves configuration values from their legacy locations to where they are
    # in Praefect's own configuration. All of the configuration was previously grouped under Gitlab['praefect']
    # but now Praefect's own config is under Gitlab['praefect']['configuration']. This then allows us to
    # simply encode the map as TOML to get the resulting Praefect configuration file without having to manually
    # template every key. As existing configuration files may can still have the configuration in its old place,
    # this method provides backwards compatibility by moving the old values to their new locations. This can
    # compatibility wrapper can be removed in 16.0
    def remap_legacy_values
      Gitlab['praefect']['configuration'] = {} unless Gitlab['praefect']['configuration']

      remap_recursive(
        {
          listen_addr: 'listen_addr',
          socket_path: 'socket_path',
          prometheus_listen_addr: 'prometheus_listen_addr',
          tls_listen_addr: 'tls_listen_addr',
          prometheus_exclude_database_from_default_metrics: 'separate_database_metrics',
          auth: {
            token: 'auth_token',
            transitioning: 'auth_transitioning',
          },
          logging: {
            format: 'logging_format',
            level: 'logging_level',
          },
          failover: {
            enabled: 'failover_enabled',
          },
          background_verification: {
            delete_invalid_records: 'background_verification_delete_invalid_records',
            verification_interval: 'background_verification_verification_interval',
          },
          reconciliation: {
            scheduling_interval: 'reconciliation_scheduling_interval',
            histogram_buckets: lambda {
              return [] unless Gitlab['praefect'].key?('reconciliation_histogram_buckets')
              raise "Legacy configuration key 'reconciliation_histogram_buckets' can't be set when its new key 'configuration.reconciliation.histogram_buckets' is set." if (Gitlab['praefect'].dig('configuration', 'reconciliation') || {}).key?('histogram_buckets')

              # The legacy key is not actually an array but a string like '[0, 1, 2]'.
              # The template evaluated Ruby code, so the array string got evaluated to
              # an array. Parse the array into a Ruby array here.
              JSON.parse(Gitlab['praefect']['reconciliation_histogram_buckets'])
            },
          },
          tls: {
            certificate_path: 'certificate_path',
            key_path: 'key_path',
          },
          database: {
            host: 'database_host',
            port: 'database_port',
            user: 'database_user',
            password: 'database_password',
            dbname: 'database_dbname',
            sslmode: 'database_sslmode',
            sslcert: 'database_sslcert',
            sslkey: 'database_sslkey',
            sslrootcert: 'database_sslrootcert',
            session_pooled: {
              host: 'database_direct_host',
              port: 'database_direct_port',
              user: 'database_direct_user',
              password: 'database_direct_password',
              dbname: 'database_direct_dbname',
              sslmode: 'database_direct_sslmode',
              sslcert: 'database_direct_sslcert',
              sslkey: 'database_direct_sslkey',
              sslrootcert: 'database_direct_sslrootcert',
            }
          },
          sentry: {
            sentry_dsn: 'sentry_dsn',
            sentry_environment: 'sentry_environment',
          },
          prometheus: {
            grpc_latency_buckets: lambda {
              return [] unless Gitlab['praefect'].key?('prometheus_grpc_latency_buckets')
              raise "Legacy configuration key 'prometheus_grpc_latency_buckets' can't be set when its new key 'configuration.prometheus.grpc_latency_buckets' is set." if (Gitlab['praefect'].dig('configuration', 'prometheus') || {}).key?('grpc_latency_buckets')

              # The legacy key is not actually an array but a string like '[0, 1, 2]'.
              # The template evaluated Ruby code, so the array string got evaluated to
              # an array. Parse the array into a Ruby array here.
              JSON.parse(Gitlab['praefect']['prometheus_grpc_latency_buckets'])
            },
          },
          graceful_stop_timeout: 'graceful_stop_timeout',
          virtual_storage: lambda {
            return [] unless Gitlab['praefect']['virtual_storages']
            raise "Legacy configuration key 'virtual_storages' can't be set when its new key 'configuration.virtual_storage' is set." if Gitlab['praefect']['configuration'].key?('virtual_storage')

            Gitlab['praefect']['virtual_storages'].map do |name, details|
              virtual_storage = {
                name: name,
                node: details['nodes'].map do |name, details|
                  {
                    storage: name,
                    address: details['address'],
                    token: details['token'],
                  }
                end
              }

              virtual_storage['default_replication_factor'] = details['default_replication_factor'] if details['default_replication_factor']
              virtual_storage
            end
          }
        },
        Gitlab['praefect']['configuration'],
        ['configuration']
      )
    end

    # remap_recursive goes over the mappings to remap the configuration from the old format into the new
    # format:
    #   - Hash values indicate a subsection in the destination configuration. Hashes are recursed into to
    #     build the expected configuration structure.
    #   - Proc values are mapping functions that return the new value when executed.
    #   - String values indicate an old configuration key that should be copied into the new configuration
    #     under the new key.
    #
    # new_parent contains the parent key path on each level of recursion.
    def remap_recursive(mappings, new_configuration, new_parent)
      mappings.each do |new_key, mapping|
        # If this is a hash, recurse the tree to create the correct structure.
        if mapping.is_a?(Hash)
          new_value = remap_recursive(
            mappings[new_key],
            # If there is already a section in the new configuration under the key, use that. If not,
            # initialize and empty hash for the section.
            Gitlab['praefect'].dig(*[new_parent, new_key].flatten) || {},
            [new_parent, new_key].flatten
          )

          new_configuration[new_key] = new_value unless new_value.empty?
          next
        end

        # If this is a Proc, it's a mapping function that returns the value for the
        # new key.
        if mapping.is_a?(Proc)
          new_value = mapping.call
          new_configuration[new_key] = new_value unless new_value.empty?
          next
        end

        # If the mapping is not a hash nor a lambda, then it is a String. The value gets copied from the
        # mapping to the new_key as is.
        #
        # If there is no old key, then there's nothing to map. Proceed to the next key.
        next unless Gitlab['praefect'].key?(mapping)

        # Raise an error if both the old key and the new key are present in the configuration as it would be
        # ambigious which key is ued in the final configuration.
        raise "Legacy configuration key '#{mapping}' can't be set when its new key '#{[new_parent, new_key].flatten.join('.')}' is set." if new_configuration.key?(new_key)

        new_configuration[new_key] = Gitlab['praefect'][mapping]
      end

      new_configuration
    end

    # check_array_entries checks that array values in the new configuration are actually arrays.
    # These values were historically configured as strings. This check guards against copy paster mistakes
    # users may do while migrating to the new configuration. This check can be removed along the
    # backwards compatibility code in 16.0.
    def check_array_entries
      [
        [:prometheus, :grpc_latency_buckets],
        [:reconciliation, :histogram_buckets]
      ].each do |key_path|
        value = Gitlab['praefect']['configuration'].dig(*key_path)
        raise "praefect['configuration']#{key_path.map { |e| "[:#{e}]" }.join('')} must be an array, not a string" unless value.nil? || value.is_a?(Array)
      end
    end

    def parse_virtual_storages
      return if Gitlab['praefect']['virtual_storages'].nil?

      raise "Praefect virtual_storages must be a hash" unless Gitlab['praefect']['virtual_storages'].is_a?(Hash)

      Gitlab['praefect']['virtual_storages'].each do |virtual_storage, config_keys|
        next unless config_keys.key?('nodes')

        raise "Nodes of Praefect virtual storage `#{virtual_storage}` must be a hash" unless config_keys['nodes'].is_a?(Hash)
      end
    end
  end
end
