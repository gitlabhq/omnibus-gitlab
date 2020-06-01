require 'chef_helper'

describe 'monitoring::postgres-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:node) { chef_run.node }
  let(:default_vars) do
    {
      'DATA_SOURCE_NAME' => 'user=gitlab-psql host=/var/opt/gitlab/postgresql database=postgres',
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when postgres is disabled locally' do
    before do
      stub_gitlab_rb(
        postgresql: { enable: false }
      )
    end

    it 'defaults the postgres-exporter to being disabled' do
      expect(node['monitoring']['postgres-exporter']['enable']).to eq false
    end

    it 'allows postgres-exporter to be explicitly enabled' do
      stub_gitlab_rb(postgres_exporter: { enable: true })

      expect(node['monitoring']['postgres-exporter']['enable']).to eq true
    end
  end

  context 'when postgres-exporter is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/postgres-exporter/log/config') }

    before do
      stub_gitlab_rb(
        postgres_exporter: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'postgres-exporter', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/postgres-exporter/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst /)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/postgres_exporter/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/postgres-exporter/)
    end

    it 'creates the queries.yaml file' do
      expect(chef_run).to render_file('/var/opt/gitlab/postgres-exporter/queries.yaml')
        .with_content(/pg_replication:/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/postgres-exporter').with(
        owner: 'gitlab-psql',
        group: nil,
        mode: '0700'
      )
    end

    it 'sets default flags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content { |content|
          expect(content).to match(/web.listen-address=localhost:9187/)
          expect(content).to match(/extend.query-path=\/var\/opt\/gitlab\/postgres-exporter\/queries.yaml/)
        }
    end
  end

  context 'when enabled and run as an isolated recipe' do
    let(:chef_run) { converge_config('monitoring::postgres-exporter') }
    before do
      stub_gitlab_rb(postgres_exporter: { enable: true })
    end

    it 'includes the postgresql_user recipe' do
      expect(chef_run).to include_recipe('postgresql::user')
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        postgres_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        postgres_exporter: {
          flags: {
            'some.flag' => 'foo'
          },
          listen_address: 'localhost:9700',
          enable: true,
          sslmode: 'require',
          env: {
            'USER_SETTING' => 'asdf1234'
          }
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content(/web.listen-address=localhost:9700/)
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content(/some.flag=foo/)
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/postgres-exporter/env').with_variables(
        default_vars.merge(
          {
            'DATA_SOURCE_NAME' => 'user=gitlab-psql host=/var/opt/gitlab/postgresql database=postgres sslmode=require',
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end
  end
end
