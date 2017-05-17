require_relative 'base_pg_helper'

# Helper class to interact with bundled PostgreSQL instance
class PgHelper < BasePgHelper
  # internal name for the service (node['gitlab'][service_name])
  def service_name
    'postgresql'
  end

  # command wrapper name
  def service_cmd
    'gitlab-psql'
  end
end
