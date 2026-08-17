require 'chef_helper'

RSpec.describe 'postgresql_role' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(postgresql_role)) }
  let(:chef_run) { runner.converge('test_postgresql::postgresql_role_create') }

  before do
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:is_ready?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(false)
    allow_any_instance_of(PgHelper).to receive(:role_exists?).and_return(false)
  end

  context 'when the role does not exist' do
    it 'creates a NOLOGIN role' do
      expect(chef_run).to run_execute('create example_connect postgresql role')
        .with(command: /CREATE ROLE .*example_connect.* NOLOGIN/)
    end
  end

  context 'when the role already exists' do
    before do
      allow_any_instance_of(PgHelper).to receive(:role_exists?).and_return(true)
    end

    it 'does not create the role' do
      expect(chef_run).not_to run_execute('create example_connect postgresql role')
    end
  end

  context 'when the database is offline or read-only' do
    before do
      allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(true)
    end

    it 'does not create the role' do
      expect(chef_run).not_to run_execute('create example_connect postgresql role')
    end
  end

  context 'when the node is a replica' do
    before do
      allow_any_instance_of(PgHelper).to receive(:is_standby?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:is_offline_or_readonly?).and_return(true)
    end

    it 'does not create the role (writes replicate via WAL)' do
      expect(chef_run).not_to run_execute('create example_connect postgresql role')
    end
  end
end
