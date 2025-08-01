require 'chef_helper'

RSpec.describe 'monitoring::postgres-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:node) { chef_run.node }
  let(:default_vars) do
    {
      'DATA_SOURCE_NAME' => 'host=/var/opt/gitlab/postgresql user=gitlab-psql database=gitlabhq_production',
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'GODEBUG' => 'tlsmlkem=0',
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
      expect(node['monitoring']['postgres_exporter']['enable']).to eq false
    end

    it 'allows postgres-exporter to be explicitly enabled' do
      stub_gitlab_rb(postgres_exporter: { enable: true })

      expect(node['monitoring']['postgres_exporter']['enable']).to eq true
    end

    it 'uses gitlab-rails db_host for the database host if postgres-exporter is explicitly enabled' do
      stub_gitlab_rb(
        postgres_exporter: { enable: true },
        gitlab_rails: {
          db_host: '10.0.0.1',
          db_port: '4242',
          db_username: 'foo',
          db_password: 'bar',
          db_database: 'baz'
        }
      )

      expect(node['monitoring']['postgres_exporter']['env']['DATA_SOURCE_NAME'])
        .to eq "host=10.0.0.1 port=4242 user=foo password=bar database=baz"
    end
  end

  context 'when postgres is enabled locally' do
    before do
      stub_gitlab_rb(
        postgresql: { enable: true }
      )
    end

    it 'uses the local postgres dir for the database host' do
      stub_gitlab_rb(
        postgres_exporter: { enable: true },
        gitlab_rails: { db_host: '10.0.0.1' },
        postgresql: { dir: '/dir/to/postgresql' }
      )

      expect(node['monitoring']['postgres_exporter']['env']['DATA_SOURCE_NAME'])
        .to eq "host=/dir/to/postgresql user=gitlab-psql database=gitlabhq_production"
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
        .with_content(/svlogd -tt \/var\/log\/gitlab\/postgres-exporter/)
    end

    it 'creates the queries.yaml file' do
      expect(chef_run).to render_file('/var/opt/gitlab/postgres-exporter/queries.yaml')
        .with_content { |content|
          expect(content).to match(/pg_total_relation_size:/)
          expect(content).to match(/pg_blocked:/)
        }
    end

    it 'sets default flags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content { |content|
          expect(content).to match(/web.listen-address=localhost:9187/)
          expect(content).to match(/extend.query-path=\/var\/opt\/gitlab\/postgres-exporter\/queries.yaml/)
        }
    end

    it 'does disable user stats' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content { |content|
          expect(content).to match(/no-collector.stat_user_tables/)
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
        .with_content(/svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        postgres_exporter: {
          flags: {
            'some.flag' => 'foo',
            'collector.stat_user_tables' => true,
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
            'DATA_SOURCE_NAME' => 'host=/var/opt/gitlab/postgresql user=gitlab-psql '\
                                  'database=gitlabhq_production sslmode=require',
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end

    it 'does not disable user stats' do
      expect(chef_run).to render_file('/opt/gitlab/sv/postgres-exporter/run')
        .with_content { |content|
          expect(content).not_to match(/no-collector.stat_user_tables/)
        }
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb(postgres_exporter: { enable: true })
      end
      it_behaves_like 'enabled logged service', 'postgres-exporter', true, { log_directory_owner: 'gitlab-psql' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          postgres_exporter: {
            enable: true,
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'postgres-exporter', true, { log_directory_owner: 'gitlab-psql', log_group: 'fugee' }
    end
  end

  include_examples "consul service discovery", "postgres_exporter", "postgres-exporter"
end
