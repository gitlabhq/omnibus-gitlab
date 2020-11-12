require 'chef_helper'

RSpec.describe PgbouncerHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  describe '#running?' do
    it 'returns true when pgbouncer is running' do
      stub_service_success_status('pgbouncer', true)
      expect(subject.running?).to be_truthy
    end

    it 'returns false when pgbouncer is not running' do
      stub_service_success_status('pgbouncer', false)
      expect(subject.running?).to be_falsey
    end
  end

  describe '#pg_auth_type_prefix' do
    using RSpec::Parameterized::TableSyntax
    where(:type, :prefix) do
      'md5' | 'md5'
      'scram-sha-256' | 'SCRAM-SHA-256$'
      'MD5' | 'md5'
      'SCRAM-SHA-256' | 'SCRAM-SHA-256$'
      'plain' | nil
      'ScRaM-ShA-256' | 'SCRAM-SHA-256$'
    end

    with_them do
      it 'responds to default values' do
        expect(subject.pg_auth_type_prefix(type)).to eq(prefix)
      end
    end
  end
end
