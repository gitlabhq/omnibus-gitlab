class FdwHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(GitlabGeoHelper)` at the end of the class definition)
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def fdw_can_refresh?
    fdw_enabled? &&
      gitlab_geo_helper.geo_database_configured? &&
      !pg_helper.is_managed_and_offline? &&
      !pg_helper.database_empty?(fdw_dbname) &&
      !geo_pg_helper.is_offline_or_readonly? &&
      !gitlab_geo_helper.fdw_synced?
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

  def fdw_enabled?
    node['gitlab']['geo-secondary']['db_fdw']
  end

  def fdw_dbname
    node['gitlab']['gitlab-rails']['db_database']
  end
end unless defined?(FdwHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
