require_relative 'base_pg_helper'

# Helper class to interact with bundled PostgreSQL instance
class PgHelper < BasePgHelper
  # internal name for the service (node[service_name])
  def service_name
    'postgresql'
  end

  # command wrapper name
  def service_cmd
    'gitlab-psql'
  end

  def public_attributes
    # Attributes which should be considered ok for other services to know
    attributes = %w(
      dir
      unix_socket_directory
      port
    )

    {
      service_name => node[service_name].select do |key, value|
        attributes.include?(key)
      end
    }
  end

  # Overridden the definition in BasePgHelper to handle scenarios where
  # PostgreSQL is delegated to Patroni.
  def is_running?
    omnibus_helper = OmnibusHelper.new(node)
    omnibus_helper.service_up?(service_name) || (delegated? && omnibus_helper.service_up?(delegate_service_name) && is_ready?)
  end

  private

  def connection_info
    build_connection_info(
      node['gitlab']['gitlab-rails']['db_database'],
      node['postgresql']['unix_socket_directory'],
      node['postgresql']['port'],
      node['postgresql']['sql_user']
    )
  end
end
