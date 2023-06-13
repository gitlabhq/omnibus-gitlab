module GeoSecondary
  GEO_DB_MIGRATIONS_PATH = 'ee/db/geo/migrate'.freeze
  GEO_SCHEMA_MIGRATIONS_PATH = 'ee/db/geo/schema_migrations'.freeze

  class << self
    def parse_variables
      parse_database
      parse_geo_secondary_db_host
    end

    def node
      Gitlab[:node]
    end

    private

    def parse_database
      # If user hasn't specified a geo database, for now, we will use the
      # geo_secondary[`db_*`] keys to populate one. In the future, we can
      # deprecate geo_secondary[`db_*`] keys and ask users to  explicitly
      # set `gitlab_rails['databases']['geo']['db_*']` settings instead.
      Gitlab['gitlab_rails']['databases'] ||= {}
      Gitlab['gitlab_rails']['databases']['geo'] ||= { 'enable' => true }

      if geo_secondary_enabled? && geo_database_enabled?
        # Set default value for attributes of geo database based on
        # geo_secondary[`db_*`] settings.
        geo_database_attributes.each do |attribute|
          Gitlab['gitlab_rails']['databases']['geo'][attribute] ||= Gitlab['geo_secondary'][attribute] || node['gitlab']['geo_secondary'][attribute]
        end

        # Set db_migrations_path since Geo migration lives in a non-default place
        Gitlab['gitlab_rails']['databases']['geo']['db_migrations_paths'] = GEO_DB_MIGRATIONS_PATH
        Gitlab['gitlab_rails']['databases']['geo']['db_schema_migrations_path'] = GEO_SCHEMA_MIGRATIONS_PATH
      else
        # Weed out the geo database settings if both Geo and database is not enabled
        Gitlab['gitlab_rails']['databases'].delete('geo')
      end
    end

    def geo_secondary_enabled?
      Gitlab['geo_secondary_role']['enable'] || Gitlab['geo_secondary']['enable']
    end

    def geo_database_attributes
      node['gitlab']['geo_secondary'].to_h.keys.select { |k| k.start_with?('db_') }
    end

    def parse_geo_secondary_db_host
      return unless geo_secondary_enabled? && geo_database_enabled?

      db_host = Gitlab['gitlab_rails']['databases']['geo']['db_host']
      if db_host&.include?(',')
        Gitlab['gitlab_rails']['databases']['geo']['db_host'] = db_host.split(',')[0]
        warning = [
          "Received multiple geo_secondary['db_host'] values: #{db_host.to_json}.",
          "First listen_address '#{Gitlab['gitlab_rails']['databases']['geo']['db_host']}' will be used."
        ].join("\n  ")
        warn(warning)
      end

      # In case no other setting was provided for db_host,
      # we use the socket directory
      Gitlab['gitlab_rails']['databases']['geo']['db_host'] ||= Gitlab['geo_postgresql']['unix_socket_directory']
    end

    def geo_database_enabled?
      Gitlab['gitlab_rails'].dig('databases', 'geo', 'enable') == true
    end
  end
end
