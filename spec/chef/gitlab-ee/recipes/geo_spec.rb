require 'chef_helper'

RSpec.describe 'gitlab-ee::geo' do
  let(:node) { chef_run.node }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  shared_examples 'default services' do
    it 'remain enabled', :aggregate_failures do
      chef_run

      default_services = Services.find_by_group(Services::DEFAULT_GROUP).keys
      omnibus_helper = OmnibusHelper.new(node)

      expect(default_services.count).to be > 0
      default_services.each do |service|
        expect(omnibus_helper.service_enabled?(service.tr('_', '-'))).to be(true), "#{service} was not enabled"
      end
    end
  end

  context 'when geo_primary_role enabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(geo_primary_role: { enable: true })
      end
      ChefSpec::SoloRunner.converge('gitlab-ee::default')
    end

    it_behaves_like 'default services'

    context 'in geo_logcursor settings' do
      it 'is not enabled' do
        expect(node['gitlab']['geo-logcursor']['enable']).to eq(nil)
      end
    end

    context 'in postgres settings' do
      let(:config_attrs) { node['postgresql'] }

      it 'defines sql_replication_user' do
        expect(config_attrs['sql_replication_user']).to eq('gitlab_replicator')
      end

      it 'defines wal_level' do
        expect(config_attrs['wal_level']).to eq('hot_standby')
      end

      it 'defines max_wal_senders' do
        expect(config_attrs['max_wal_senders']).to eq(10)
      end

      it 'defines wal_keep_segments' do
        expect(config_attrs['wal_keep_segments']).to eq(50)
      end

      it 'defines max_replication_slots' do
        expect(config_attrs['max_replication_slots']).to eq(1)
      end

      it 'defines hot_standby' do
        expect(config_attrs['hot_standby']).to eq('on')
      end
    end
  end

  context 'geo_secondary_role enabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(geo_secondary_role: { enable: true })
      end
      ChefSpec::SoloRunner.converge('gitlab-ee::default')
    end

    it_behaves_like 'default services'

    context 'in geo_postgres settings' do
      it 'is enabled' do
        expect(node['gitlab']['geo-postgresql']['enable']).to eq(true)
      end
    end

    context 'in geo_logcursor settings' do
      it 'is enabled' do
        expect(node['gitlab']['geo-logcursor']['enable']).to eq(true)
      end
    end

    context 'in postgres settings' do
      let(:config_attrs) { node['postgresql'] }

      it 'defines wal_level' do
        expect(config_attrs['wal_level']).to eq('hot_standby')
      end

      it 'defines max_wal_senders' do
        expect(config_attrs['max_wal_senders']).to eq(10)
      end

      it 'defines wal_keep_segments' do
        expect(config_attrs['wal_keep_segments']).to eq(10)
      end

      it 'defines max_replication_slots' do
        expect(config_attrs['max_replication_slots']).to eq(0)
      end

      it 'defines hot_standby' do
        expect(config_attrs['hot_standby']).to eq('on')
      end

      it 'defines standby settings' do
        expect(config_attrs['max_standby_archive_delay']).to eq('60s')
        expect(config_attrs['max_standby_streaming_delay']).to eq('60s')
      end
    end

    context 'in gitlab-rails' do
      it 'disables auto_migrate' do
        expect(node['gitlab']['gitlab-rails']['auto_migrate']).to eq(false)
      end
    end
  end
end
