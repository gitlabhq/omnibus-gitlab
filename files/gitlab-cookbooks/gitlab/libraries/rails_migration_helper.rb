# frozen_string_literal: true

class RailsMigrationHelper
  REVISION_FILE ||= '/opt/gitlab/embedded/service/gitlab-rails/REVISION'

  attr_reader :node, :status_file_prefix, :attributes_node, :migration_task_name

  def initialize(node)
    @node = node
    @status_file_prefix = 'db-migrate'
    @attributes_node = node['gitlab']['gitlab-rails']
  end

  def migrated?
    check_status_file(db_migrate_status_file)
  end

  def db_migrate_status_file
    @db_migrate_status_file ||= begin
      upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], 'upgrade-status')
      ::File.join(upgrade_status_dir, "#{status_file_prefix}-#{connection_digest}-#{revision}")
    end
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
    ).collect { |attribute| attributes_node[attribute] }

    Digest::MD5.hexdigest(Marshal.dump(connection_attributes))
  end
end
