require_relative '../../gitlab/libraries/helpers/pg_helper'

# Helper class to interact with PostgreSQL instance for Registry database
class RegistryPgHelper < PgHelper
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
