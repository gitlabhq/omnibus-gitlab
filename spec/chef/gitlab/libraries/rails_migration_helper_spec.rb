require 'chef_helper'

RSpec.describe RailsMigrationHelper do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  subject(:helper) { described_class.new(chef_run.node) }

  context '#migrated?' do
    it 'returns true if status file exists and content is "0"' do
      allow(helper).to receive(:db_migrate_status_file) { File.join(fixture_path, 'migration/successful-migration-status-file') }

      expect(helper.migrated?).to be_truthy
    end

    it 'returns false when status file doesnt exist' do
      allow(helper).to receive(:db_migrate_status_file) { File.join(fixture_path, 'migration/non-existent-migration') }

      expect(helper.migrated?).to be_falsey
    end

    it 'returns false when content in status file is different from "0"' do
      allow(helper).to receive(:db_migrate_status_file) { File.join(fixture_path, 'migration/failed-migration-status-file') }

      expect(helper.migrated?).to be_falsey
    end
  end

  context '#db_migrate_status_file' do
    it 'returns a path including status_file_prefix connection_digest and revision' do
      fake_connection_digest = '63467bb60aa187d2a6830aa8f1b5cbe0'
      fake_revision = 'f9631484e7f'
      expected_status_file = "/var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-#{fake_connection_digest}-#{fake_revision}"

      allow(helper).to receive(:connection_digest) { fake_connection_digest }
      allow(helper).to receive(:revision) { fake_revision }

      expect(helper.db_migrate_status_file).to eq(expected_status_file)
    end
  end
end
