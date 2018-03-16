require_relative '../../../../files/gitlab-cookbooks/gitlab-ee/libraries/fdw_helper.rb'
require 'chef_helper'

describe FdwHelper do
  let(:chef_run) { converge_config(ee: true) }
  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#fdw_can_refresh?' do
    before do
      stub_gitlab_rb(
        geo_postgresql: {
          enable: true,
          sql_user: 'mygeodbuser'
        },
        geo_secondary: {
          enable: true,
          db_database: 'gitlab_geodb',
          db_fdw: true
        },
        gitlab_rails: {
          db_host: '10.0.0.1',
          db_port: 5430,
          db_username: 'mydbuser',
          db_database: 'gitlab_myorg',
          db_password: 'custompass'
        }
      )
    end

    context 'when fdw has all required states to be refreshed' do
      before do
        allow_any_instance_of(PgHelper).to receive(:is_managed_and_offline?).and_return(false)
        allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
        allow_any_instance_of(PgHelper).to receive(:database_empty?).and_return(false)
        allow_any_instance_of(GeoPgHelper).to receive(:is_offline_or_readonly?).and_return(false)
        allow_any_instance_of(GitlabGeoHelper).to receive(:geo_database_configured?).and_return(true)
      end

      it 'returns true' do
        expect(subject.fdw_can_refresh?).to be_truthy
      end
    end
  end

  describe '#pg_hba_entries' do
    before do
      stub_gitlab_rb(
        geo_postgresql: {
          enable: true,
          sql_user: 'mygeodbuser'
        },
        geo_secondary: {
          enable: true,
          db_database: 'gitlab_geodb',
          db_fdw: true
        },
        gitlab_rails: {
          db_host: '10.0.0.1',
          db_port: 5430,
          db_username: 'mydbuser',
          db_database: 'gitlab_myorg',
          db_password: 'custompass'
        },
        postgresql: {
          md5_auth_cidr_addresses: %w(10.0.0.1/32 10.0.0.2/32)
        }
      )
    end

    it 'returns array of hashes with expected keys' do
      pg_hba_entries = [
        {
          type: 'host',
          database: 'gitlab_myorg',
          user: 'mydbuser',
          cidr: '10.0.0.1/32',
          method: 'md5'
        },
        {
          type: 'host',
          database: 'gitlab_myorg',
          user: 'mydbuser',
          cidr: '10.0.0.2/32',
          method: 'md5'
        }
      ]
      expect(subject.pg_hba_entries).to eq(pg_hba_entries)
    end
  end

  context 'when fdw has a lack of any of the required states to be refreshed' do
    it 'returns false' do
      expect(subject.fdw_can_refresh?).to be_falsey
    end
  end
end
