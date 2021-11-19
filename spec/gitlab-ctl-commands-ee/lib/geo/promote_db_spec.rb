require 'spec_helper'
require 'geo/promote_db'
require 'gitlab_ctl/util'

RSpec.describe Geo::PromoteDb, '#execute' do
  let(:instance) { double(base_path: '/opt/gitlab/embedded') }

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

  context 'postgres dir is in non-default location' do
    it 'uses the specified postgres directory when writing ' do
      expected_dir = '/non/default/location'
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({ 'postgresql' => { 'dir' => expected_dir } })

      expect(described_class.new(instance).postgresql_dir_path).to eq(expected_dir)
    end
  end

  context 'when PITR file exists' do
    let(:lsn) { '16/B374D848' }

    before do
      allow(command).to receive(:lsn_from_pitr_file).and_return(lsn)
      allow(command).to receive(:write_geo_config_file).and_return(true)
    end

    it 'writes out the recovery settings' do
      expect(command).to receive(:write_recovery_settings).with(lsn)

      expect { command.execute }.to output(
        /Recovery to point #{lsn} and promoting.../).to_stdout
    end

    it 'writes out the geo configuration file' do
      expect(command).to receive(:write_geo_config_file).once

      command.execute
    end
  end
end
