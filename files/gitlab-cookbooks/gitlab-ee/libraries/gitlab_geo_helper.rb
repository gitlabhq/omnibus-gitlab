# frozen_string_literal: true

class GitlabGeoHelper < RailsMigrationHelper
  def initialize(node)
    @node = node
    @status_file_prefix = 'geo-db-migrate'
    @attributes_node = node['gitlab']['geo_secondary']
  end
end
