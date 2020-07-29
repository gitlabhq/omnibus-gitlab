class FdwHelper
  FOREIGN_SCHEMA = 'gitlab_secondary'.freeze
  DEFAULT_SCHEMA = 'public'.freeze

  attr_reader :node

  def initialize(node)
    @node = node
  end

  def fdw_enabled?
    node['gitlab']['geo-secondary']['db_fdw']
  end

  def fdw_can_refresh?
    fdw_enabled? &&
      gitlab_geo_helper.geo_database_configured? &&
      !pg_helper.is_managed_and_offline? &&
      !pg_helper.database_empty?(fdw_dbname) &&
      !geo_pg_helper.is_offline_or_readonly? &&
      geo_pg_helper.schema_exists?(FOREIGN_SCHEMA, tracking_dbname) &&
      !foreign_schema_tables_match?
  end

  # Check if foreign schema has exact the same tables and fields defined on secondary database
  #
  # @return [Boolean] whether schemas match
  def foreign_schema_tables_match?
    retrieve_gitlab_schema_tables == retrieve_foreign_schema_tables
  end

  def retrieve_foreign_schema_tables
    geo_pg_helper.retrieve_schema_tables(FOREIGN_SCHEMA, tracking_dbname)
  end

  def retrieve_gitlab_schema_tables
    pg_helper.retrieve_schema_tables(DEFAULT_SCHEMA, fdw_dbname)
  end

  def tracking_dbname
    node['gitlab']['geo-secondary']['db_database']
  end

  def fdw_dbname
    node['gitlab']['gitlab-rails']['db_database']
  end

  def fdw_user
    node['gitlab']['geo-postgresql']['fdw_external_user']
  end

  def fdw_password
    node['gitlab']['geo-postgresql']['fdw_external_password']
  end

  def fdw_host
    node['gitlab']['gitlab-rails']['db_host']
  end

  def fdw_port
    node['gitlab']['gitlab-rails']['db_port']
  end

  def pg_hba_entries
    entries = []
    node['postgresql']['md5_auth_cidr_addresses'].each do |cidr|
      entries.push({
                     type: 'host',
                     database: fdw_dbname,
                     user: fdw_user,
                     cidr: cidr,
                     method: 'md5'
                   })
    end
    entries
  end

  private

  def gitlab_geo_helper
    @gitlab_geo_helper ||= GitlabGeoHelper.new(node)
  end

  def geo_pg_helper
    @geo_pg_helper ||= GeoPgHelper.new(node)
  end

  def pg_helper
    @pg_helper ||= PgHelper.new(node)
  end
end unless defined?(FdwHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
