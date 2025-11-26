class RegistryHelper < BaseHelper
  attr_reader :node

  def redis_enabled?
    !!node.dig('registry', 'redis', 'loadbalancing', 'enabled')
  end

  def public_attributes
    {
      'registry' => {
        'dir' => node['registry']['dir'],
        'username' => node['registry']['username'],
        'group' => node['registry']['group']
      }
    }
  end

  # Check if prefer mode was overridden during attribute parsing
  def must_override_database_prefer_mode?
    !!node.dig('registry', 'database', '_prefer_mode_overridden')
  end

  # Determines if database migrations should run.
  # Migrations run if:
  # 1. database.enabled is explicitly true (works with external PostgreSQL)
  # 2. database.enabled is "prefer" AND embedded PostgreSQL is enabled
  # 3. auto_migrate is enabled
  # 4. PostgreSQL is ready
  def should_run_migrations?
    registry_pg_helper = RegistryPgHelper.new(node)
    database_enabled = node.dig('registry', 'database', 'enabled')

    ['prefer', 'true', true].include?(database_enabled) &&
      node['registry']['auto_migrate'] &&
      registry_pg_helper.is_ready?
  end
end
