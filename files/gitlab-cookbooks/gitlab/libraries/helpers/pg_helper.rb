require 'json'
require_relative 'base_pg_helper'

# Helper class to interact with bundled PostgreSQL instance
class PgHelper < BasePgHelper
  # Allow-list of component_databases sub-fields safe to surface in
  # public_attributes.json. The file is world-readable and `password`
  # is md5(password+username), brute-forceable offline.
  COMPONENT_DATABASE_PUBLIC_FIELDS = %w(enable database).freeze

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
      component_databases
    )

    filtered = node[service_name].select { |key, _| attributes.include?(key) }
    filtered['component_databases'] = sanitize_component_databases if node[service_name].key?('component_databases')

    # JSON round-trip deep-clones the values into plain Hash/Array, so the
    # report handler's deep_merge! does not blow up on immutable Mashes when
    # a selected attribute is nested (e.g. component_databases).
    { service_name => JSON.parse(JSON.dump(filtered)) }
  end

  # Overridden the definition in BasePgHelper to handle scenarios where
  # PostgreSQL is delegated to Patroni.
  def is_running?
    omnibus_helper = OmnibusHelper.new(node)
    omnibus_helper.service_up?(service_name) || (delegated? && omnibus_helper.service_up?(delegate_service_name) && is_ready?)
  end

  private

  def sanitize_component_databases
    node[service_name]['component_databases'].each_with_object({}) do |(key, entry), acc|
      next unless entry.is_a?(Hash)

      acc[key] = entry.select { |k, _| COMPONENT_DATABASE_PUBLIC_FIELDS.include?(k) }
    end
  end

  def connection_info
    build_connection_info(
      node['gitlab']['gitlab_rails']['db_database'],
      node['postgresql']['unix_socket_directory'],
      node['postgresql']['port'],
      node['postgresql']['sql_user']
    )
  end
end
