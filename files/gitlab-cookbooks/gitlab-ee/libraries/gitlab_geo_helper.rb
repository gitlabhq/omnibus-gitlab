class GitlabGeoHelper
  REVISION_FILE ||= '/opt/gitlab/embedded/service/gitlab-rails/REVISION'.freeze

  attr_reader :node

  def initialize(node)
    @node = node
  end

  def migrated?
    ::File.exist?(db_migrate_status_file) && IO.read(db_migrate_status_file).chomp == '0'
  end

  def db_migrate_status_file
    @status_file ||= begin
      upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], 'upgrade-status')
      ::File.join(upgrade_status_dir, "geo-db-migrate-#{connection_digest}-#{revision}")
    end
  end

  private

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
end
