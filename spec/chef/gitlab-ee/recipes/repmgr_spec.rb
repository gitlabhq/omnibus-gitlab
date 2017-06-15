require 'chef_helper'

describe 'repmgr' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
  let(:pg_hba_conf) { '/var/opt/gitlab/postgresql/data/pg_hba.conf' }

  context 'disabled by default' do
    it 'does not have anything in pg_hba.conf' do
      expect(chef_run).to render_file(pg_hba_conf).with_content { |content|
        expect(content).not_to match(/repmgr/)
      }
    end
  end

  context 'when enabled' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(
        postgresql: {
          repmgr: {
            enable: true,
            trust_auth_cidr_addresses: ['123.456.789.0/24']
          }
        }
      )
    end

    it 'creates appropriate entries in pg_hba.conf' do
      expect(chef_run).to render_file(pg_hba_conf).with_content { |content|
        expect(content).to include('local   replication   repmgr                            trust')
        expect(content).to include('host    replication   repmgr      127.0.0.1/32          trust')
        expect(content).to include('host    replication   repmgr      123.456.789.0/24           trust')
        expect(content).to include('local   repmgr   repmgr                            trust')
        expect(content).to include('host    repmgr   repmgr      127.0.0.1/32          trust')
        expect(content).to include('host    repmgr   repmgr      123.456.789.0/24           trust')
      }
    end
  end
end
