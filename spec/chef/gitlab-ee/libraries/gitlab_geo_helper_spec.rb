require_relative '../../../../files/gitlab-cookbooks/gitlab-ee/libraries/gitlab_geo_helper.rb'
require 'chef_helper'

describe GitlabGeoHelper do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  subject { described_class.new(chef_run.node) }

  describe '#migrated?' do
    before do
      allow(subject).to receive(:db_migrate_status_file) { '/tmp/geo-db-migrate-xyz-123' }
    end

    it 'returns true when migration file exists and content is zero' do
      allow(File).to receive(:exist?).with('/tmp/geo-db-migrate-xyz-123') { true }
      allow(IO).to receive(:read).with('/tmp/geo-db-migrate-xyz-123') { '0' }

      expect(subject.migrated?).to eq true
    end

    it 'returns false when migration file doesnt exist' do
      allow(File).to receive(:exist?).with('/tmp/geo-db-migrate-xyz-123') { false }

      expect(subject.migrated?).to eq false
    end

    it 'returns false when content is not zero' do
      allow(File).to receive(:exist?).with('/tmp/geo-db-migrate-xyz-123') { true }
      allow(IO).to receive(:read).with('/tmp/geo-db-migrate-xyz-123') { '1' }

      expect(subject.migrated?).to eq false
    end
  end

  describe '#db_migrate_status_file' do
    let(:connection_digest) { '32596e8376077c3ef8d5cf52f15279ba' }
    let(:revision) { '8b21d70' }

    before do
      allow(subject).to receive(:connection_digest) { connection_digest }
      allow(subject).to receive(:revision) { revision }
    end

    it 'contains connection digest' do
      expect(subject.db_migrate_status_file).to include(connection_digest)
    end

    it 'contains revision number' do
      expect(subject.db_migrate_status_file).to include(revision)
    end

    it 'follows specific pattern' do
      expect(subject.db_migrate_status_file).to include("geo-db-migrate-#{connection_digest}-#{revision}")
    end
  end
end
