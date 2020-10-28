require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'geo/replication_toggle_command'
require 'geo/promote_to_primary_node'
require 'gitlab_ctl/util'

RSpec.describe Geo::ReplicationToggleCommand do
  let(:status) { double('Command status', error?: false) }
  let(:arguments) { [] }
  let(:ctl_instance) { double('gitlab-ctl instance', base_path: '', data_path: 'data_path') }

  before do
    allow_any_instance_of(Geo::ReplicationToggleCommand).to receive(:current_lsn).and_return('16/B374D848')
  end

  describe 'pause' do
    subject { described_class.new(ctl_instance, 'pause', arguments) }

    it 'calls pause' do
      expect_any_instance_of(Geo::ReplicationProcess).to receive(:pause)
      expect(File).to receive(:write).with('data_path/postgresql/data/geo-pitr-file', '16/B374D848')

      expect { subject.execute! }.to output(/Create Geo point-in-time recovery file/).to_stdout
    end

    it 'rescues and exits if postgres has an error' do
      expect_any_instance_of(Geo::ReplicationProcess).to receive(:pause).and_raise(Geo::PsqlError, "Oh nose!")

      expect do
        expect { subject.execute! }.to raise_error(SystemExit)
      end.to output(/Postgres encountered an error: Oh nose!/).to_stdout
    end

    context 'database specified' do
      let(:arguments) { %w(--db_name=database_i_want) }

      it 'uses the specified database' do
        expect(Geo::ReplicationProcess).to receive(:new).with(any_args, { db_name: 'database_i_want' }).and_call_original
        expect_any_instance_of(Geo::ReplicationProcess).to receive(:pause)
        expect(File).to receive(:write).with('data_path/postgresql/data/geo-pitr-file', '16/B374D848')

        expect { subject.execute! }.to output(/Create Geo point-in-time recovery file/).to_stdout
      end
    end
  end

  describe 'resume' do
    subject { described_class.new(ctl_instance, 'resume', arguments) }

    it 'calls resume' do
      expect_any_instance_of(Geo::ReplicationProcess).to receive(:resume)

      expect { subject.execute! }.to output(/Remove Geo point-in-time recovery file/).to_stdout
    end

    it 'rescues and exits if postgres has an error' do
      expect_any_instance_of(Geo::ReplicationProcess).to receive(:resume).and_raise(Geo::PsqlError, "Oh nose!")

      expect do
        expect { subject.execute! }.to raise_error(SystemExit)
      end.to output(/Postgres encountered an error: Oh nose!/).to_stdout
    end

    it 'rescues and exits if rake has an error' do
      expect_any_instance_of(Geo::ReplicationProcess).to receive(:resume).and_raise(Geo::RakeError, "Oh nose!")

      expect do
        expect { subject.execute! }.to raise_error(SystemExit)
      end.to output(/Rake encountered an error: Oh nose!/).to_stdout
    end

    context 'database specified' do
      let(:arguments) { %w(--db_name=database_i_want) }

      it 'uses the specified database' do
        expect(Geo::ReplicationProcess).to receive(:new).with(any_args, { db_name: 'database_i_want' }).and_call_original
        expect_any_instance_of(Geo::ReplicationProcess).to receive(:resume)

        expect { subject.execute! }.to output(/Remove Geo point-in-time recovery file/).to_stdout
      end
    end
  end
end
