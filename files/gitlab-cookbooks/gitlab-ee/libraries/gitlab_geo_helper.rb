class GitlabGeoHelper # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(GitlabGeoHelper)` at the end of the class definition)
  REVISION_FILE ||= '/opt/gitlab/embedded/service/gitlab-rails/REVISION'.freeze

  attr_reader :node

  def initialize(node)
    @node = node
  end

  def migrated?
    check_status_file(db_migrate_status_file)
  end

  def db_migrate_status_file
    @db_migrate_status_file ||= begin
      upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], 'upgrade-status')
      ::File.join(upgrade_status_dir, "geo-db-migrate-#{connection_digest}-#{revision}")
    end
  end

  def geo_database_configured?
    database_geo_yml = ::File.join(node['gitlab']['gitlab-rails']['dir'], 'etc', 'database_geo.yml')
    ::File.exist?(database_geo_yml)
  end

  private

  def check_status_file(file)
    ::File.exist?(file) && IO.read(file).chomp == '0'
  end

  def revision
    @revision ||= IO.read(REVISION_FILE).chomp if ::File.exist?(REVISION_FILE)
  end

  def connection_digest
    connection_attributes = %w(
      db_adapter
      db_database
      db_host
      db_port
      db_socket
    ).collect { |attribute| node['gitlab']['geo-secondary'][attribute] }

    Digest::MD5.hexdigest(Marshal.dump(connection_attributes))
  end
end unless defined?(GitlabGeoHelper) # Prevent reloading in chefspec: https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
