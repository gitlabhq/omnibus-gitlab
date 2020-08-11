require_relative '../../../../files/gitlab-cookbooks/gitlab-ee/libraries/gitlab_geo_helper.rb'
require 'chef_helper'

RSpec.describe GitlabGeoHelper do
  cached(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }

  describe '#migrated?' do
    let(:state_file) { '/tmp/geo-db-migrate-xyz-123' }

    before do
      allow(subject).to receive(:db_migrate_status_file) { state_file }
    end

    it 'returns true when migration file exists and content is zero' do
      stub_file_content(state_file, '0')

      expect(subject.migrated?).to eq true
    end

    it 'returns false when migration file doesnt exist' do
      allow(File).to receive(:exist?).with(state_file) { false }

      expect(subject.migrated?).to eq false
    end

    it 'returns false when content is not zero' do
      stub_file_content(state_file, '1')

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

  def stub_file_content(fullpath, content)
    allow(File).to receive(:exist?).with(fullpath) { true }
    allow(IO).to receive(:read).with(fullpath) { content }
  end
end
