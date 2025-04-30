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

  def pinned_postgresql_version
    pinned_version = node['postgresql']['version']
    return unless pinned_version

    # Check the pinned version is valid
    db_path = Dir.glob("#{postgresql_install_dir}/#{pinned_version}*").min
    return unless db_path

    PGVersion.parse(pinned_version.to_s)
  end

  private

  def connection_info
    build_connection_info(
      node['gitlab']['geo_secondary']['db_database'],
      node['gitlab']['geo_postgresql']['unix_socket_directory'],
      node['gitlab']['geo_postgresql']['port'],
      node['gitlab']['geo_postgresql']['sql_user']
    )
  end
end
