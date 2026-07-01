require 'spec_helper'
require 'omnibus-ctl'
require 'gitlab_ctl'

RSpec.describe 'gitlab-ctl pg-upgrade' do
  subject(:ctl) { Omnibus::Ctl.new('testing-ctl') }

  let(:output) { StringIO.new }

  before do
    # pg-upgrade.rb defines SUPPORTED_VERSIONS at load time via
    # version_from_manifest -> JSON.load_file
    allow(JSON).to receive(:load_file).and_return({ 'software' => {} })
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl/lib/gitlab_ctl'
    ) { nil }
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl/lib/gitlab_ctl/postgresql'
    ) { nil }

    ctl.fh_output = output
    ctl.load_file('files/gitlab-ctl-commands/pg-upgrade.rb')
  end

  it 'appends a pg-upgrade command' do
    expect(ctl.get_all_commands_hash).to include('pg-upgrade')
  end

  describe '#skip_multi_node_check' do
    let(:db_worker) { instance_double(GitlabCtl::PgUpgrade) }

    before do
      allow(db_worker).to receive(:pg_upgrade_disabled?).and_return(false)
      allow(db_worker).to receive(:patroni_service_enabled?).and_return(false)
      allow(db_worker).to receive(:geo_postgres_service_enabled?).and_return(false)
      allow(db_worker).to receive(:geo_primary_role?).and_return(false)
      allow(db_worker).to receive(:geo_secondary_role?).and_return(false)

      allow(Kernel).to receive(:exit) { |code| raise SystemExit, code.to_s }
    end

    it 'returns without logging on a plain single-node install' do
      expect { ctl.skip_multi_node_check(db_worker) }.not_to raise_error
      expect(output.string).to be_empty
    end

    context 'when pg upgrade is explicitly disabled' do
      before { allow(db_worker).to receive(:pg_upgrade_disabled?).and_return(true) }

      it 'logs the disabled reason and exits' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Skipping the check')
        expect(output.string).to include('disable-postgresql-upgrade')
      end
    end

    context 'when patroni is enabled' do
      before { allow(db_worker).to receive(:patroni_service_enabled?).and_return(true) }

      it 'logs the patroni reason and exits' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Skipping the check')
        expect(output.string).to include('Patroni is enabled')
      end
    end

    context 'when geo is detected via geo-postgresql service' do
      before { allow(db_worker).to receive(:geo_postgres_service_enabled?).and_return(true) }

      it 'logs the geo reason and exits' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Geo configuration is detected')
      end
    end

    context 'when geo is detected via geo_primary_role?' do
      before { allow(db_worker).to receive(:geo_primary_role?).and_return(true) }

      it 'logs the geo reason and exits' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Geo configuration is detected')
      end
    end

    context 'when geo is detected via geo_secondary_role?' do
      before { allow(db_worker).to receive(:geo_secondary_role?).and_return(true) }

      it 'logs the geo reason and exits' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Geo configuration is detected')
      end
    end

    context 'when disabled takes priority over patroni' do
      before do
        allow(db_worker).to receive(:pg_upgrade_disabled?).and_return(true)
        allow(db_worker).to receive(:patroni_service_enabled?).and_return(true)
      end

      it 'logs the disabled reason, not the patroni reason' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('disable-postgresql-upgrade')
        expect(output.string).not_to include('Patroni is enabled')
      end
    end

    context 'when patroni takes priority over geo' do
      before do
        allow(db_worker).to receive(:patroni_service_enabled?).and_return(true)
        allow(db_worker).to receive(:geo_postgres_service_enabled?).and_return(true)
      end

      it 'logs the patroni reason, not the geo reason' do
        expect { ctl.skip_multi_node_check(db_worker) }.to raise_error(SystemExit)
        expect(output.string).to include('Patroni is enabled')
        expect(output.string).not_to include('Geo configuration is detected')
      end
    end
  end
end
