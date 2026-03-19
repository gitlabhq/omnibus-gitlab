require_relative '../../gitlab/libraries/helpers/pg_helper'

# Helper class to interact with PostgreSQL instance for Registry database
class RegistryPgHelper < PgHelper
  # Check if registry database is enabled
  def database_enabled?
    db_enabled = node.dig('registry', 'database', 'enabled')
    ['prefer', 'true', true].include?(db_enabled)
  end

  private

  def connection_info
    build_connection_info(
      node['registry']['database']['dbname'],
      node['registry']['database']['host'],
      node['registry']['database']['port'],
      node['registry']['database']['user']
    )
  end
end
