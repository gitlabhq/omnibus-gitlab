require 'spec_helper'
require 'geo/promote_db'
require 'gitlab_ctl/util'

RSpec.describe Geo::PromoteDb, '#execute' do
  let(:instance) { double(base_path: '/opt/gitlab/embedded', data_path: '/var/opt/gitlab/postgresql/data') }

  subject(:command) { described_class.new(instance) }

  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)

    allow(command).to receive(:run_command).with(any_args)

    allow(command).to receive(:run_command).and_return(double('error!' => nil))
  end

  context 'when PITR file does not exist' do
    it 'does not run PITR recovery' do
      expect(command).not_to receive(:write_recovery_settings)

      command.execute
    end
  end

  context 'when PITR file exists' do
    let(:lsn) { '16/B374D848' }

    before do
      allow(command).to receive(:lsn_from_pitr_file).and_return(lsn)
    end

    it 'runs PITR recovery' do
      expect(command).to receive(:write_recovery_settings).with(lsn)

      expect { command.execute }.to output(
        /Recovery to point #{lsn} and promoting.../).to_stdout
    end

    context 'PG version 11' do
      it 'runs PITR recovery' do
        allow(command).to receive(:postgresql_version).and_return(11)
        expect(command).to receive(:write_recovery_conf)

        expect { command.execute }.to output(
          /Writing recovery.conf/).to_stdout
      end
    end

    context 'PG version 12' do
      it 'runs PITR recovery' do
        allow(command).to receive(:postgresql_version).and_return(12)
        expect(command).to receive(:write_geo_config_file)

        expect { command.execute }.to output(
          /PostgreSQL 12 or newer. Writing settings to postgresql.conf/).to_stdout
      end
    end
  end
end
