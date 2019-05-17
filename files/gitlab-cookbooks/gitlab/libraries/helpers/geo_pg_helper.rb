require_relative 'base_pg_helper'

# Helper class to interact with bundled Geo PostgreSQL instance
class GeoPgHelper < BasePgHelper
  # internal name for the service (node[service_name])
  def service_name
    'geo-postgresql'
  end

  # command wrapper name
  def service_cmd
    'gitlab-geo-psql'
  end
end
