# frozen_string_literal: true

class GitlabGeoHelper < RailsMigrationHelper
  def initialize(node)
    @node = node
    @status_file_prefix = 'geo-db-migrate'
    @attributes_node = node['gitlab']['geo-secondary']
  end

  def geo_database_configured?
    database_geo_yml = ::File.join(node['gitlab']['gitlab-rails']['dir'], 'etc', 'database_geo.yml')
    ::File.exist?(database_geo_yml)
  end
end
