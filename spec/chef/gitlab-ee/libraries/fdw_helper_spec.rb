require_relative '../../../../files/gitlab-cookbooks/gitlab-ee/libraries/fdw_helper.rb'
require 'chef_helper'

describe FdwHelper do
  let(:chef_run) { converge_config(is_ee: true) }
  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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
end
