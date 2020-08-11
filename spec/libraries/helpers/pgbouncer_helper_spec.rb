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
end
