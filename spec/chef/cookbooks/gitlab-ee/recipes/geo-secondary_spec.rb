require 'chef_helper'

RSpec.describe 'gitlab-ee::geo-secondary' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }
  let(:database_geo_yml) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml') }
  let(:database_geo_yml_content) { ChefSpec::Renderer.new(chef_run, database_geo_yml).content }
  let(:generated_yml_content) { YAML.safe_load(database_geo_yml_content, [], [], true, symbolize_names: true) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when geo_secondary_role is disabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before { stub_gitlab_rb(geo_secondary_role: { enable: false }) }

    it 'does not render the geo-secondary files' do
      expect(chef_run).not_to render_file('/opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml')
      expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml')
    end
  end

  describe 'when geo_secondary_role is disabled but geo-postgresql enabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before do
      stub_gitlab_rb(geo_secondary_role: { enable: false },
                     geo_postgresql: { enable: true })
    end

    it 'does not render the geo-secondary files' do
      expect(chef_run).not_to render_file('/opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml')
      expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-rails/etc/database_geo.yml')
    end
  end

  describe 'when gitlab_rails is disabled, but geo_secondary_role is enabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     gitlab_rails: { enable: false })
    end

    it 'does not render the geo-secondary files' do
      expect(chef_run).not_to create_templatesymlink('Create a database_geo.yml and create a symlink to Rails root')
    end
  end

  describe 'when gitlab_rails is enabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     geo_postgresql: { enable: true },
                     puma: { enable: false },
                     sidekiq: { enable: false },
                     geo_logcursor: { enable: false },
                     gitlab_rails: { enable: true })
    end

    it 'allows gitlab_rails to be overriden' do
      expect(chef_run.node['gitlab']['gitlab-rails']['enable']).to be true
    end
  end

  context 'when gitaly is enabled' do
    describe 'when gitlab_rails enable is not set' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      before do
        stub_gitlab_rb(geo_secondary_role: { enable: true },
                       geo_secondary: { enable: true },
                       geo_postgresql: { enable: false },
                       puma: { enable: false },
                       sidekiq: { enable: false },
                       geo_logcursor: { enable: false },
                       gitaly: { enable: true })
      end

      it 'ensures gitlab_rails is enabled' do
        chef_run
        expect(Gitlab['gitlab_rails']['enable']).to be true
      end
    end

    describe 'when gitlab_rails enable is provided' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      before do
        stub_gitlab_rb(geo_secondary_role: { enable: true },
                       geo_secondary: { enable: true },
                       geo_postgresql: { enable: false },
                       puma: { enable: false },
                       sidekiq: { enable: false },
                       geo_logcursor: { enable: false },
                       gitaly: { enable: true },
                       gitlab_rails: { enable: false })
      end

      it 'does not override gitlab_rails enable' do
        chef_run
        expect(Gitlab['gitlab_rails']['enable']).to be false
      end
    end
  end

  context 'when geo_secondary_role is enabled but geo-postgresql is disabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     geo_postgresql: { enable: false },
                     geo_secondary: {
                       db_host: '1.1.1.1',
                       db_password: 'password',
                       db_port: '5431'
                     })
    end

    describe 'migrations' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'includes the database migration recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
      end
    end

    describe 'database.yml' do
      it 'creates the database_geo.yml template not using many database structure' do
        expect(generated_yml_content).to eq(
          production: {
            adapter: 'postgresql',
            application_name: nil,
            collation: nil,
            connect_timeout: nil,
            database: 'gitlabhq_geo_production',
            encoding: 'unicode',
            host: '1.1.1.1',
            keepalives: nil,
            keepalives_count: nil,
            keepalives_idle: nil,
            keepalives_interval: nil,
            load_balancing: {
              hosts: []
            },
            password: 'password',
            port: 5431,
            prepared_statements: false,
            socket: nil,
            sslca: nil,
            sslcompression: 0,
            sslmode: nil,
            sslrootcert: nil,
            statement_limit: nil,
            tcp_user_timeout: nil,
            username: 'gitlab_geo',
            variables: {
              statement_timeout: nil,
            }
          }
        )
      end

      context 'when SSL compression is enabled' do
        before do
          stub_gitlab_rb(geo_secondary: { db_sslcompression: 1 })
        end

        it 'uses provided value in database.yml' do
          expect(generated_yml_content[:production][:sslcompression]).to eq(1)
        end
      end
    end
  end

  context 'when geo_secondary_role is enabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true })

      # Make sure other calls to `File.symlink?` are allowed.
      allow(File).to receive(:symlink?).and_call_original
      %w(
        alertmanager
        gitlab-exporter
        gitlab-workhorse
        logrotate
        nginx
        node-exporter
        postgres-exporter
        postgresql
        prometheus
        redis
        redis-exporter
        sidekiq
        puma
        gitaly
        geo-postgresql
        gitlab-pages
        geo-logcursor
        patroni
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    describe 'database.yml' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a database_geo.yml and create a symlink to Rails root') }

      it 'creates the database_geo.yml template not using many database structure' do
        expect(generated_yml_content).to eq(
          production: {
            adapter: 'postgresql',
            application_name: nil,
            collation: nil,
            connect_timeout: nil,
            database: 'gitlabhq_geo_production',
            encoding: 'unicode',
            host: '/var/opt/gitlab/geo-postgresql',
            keepalives: nil,
            keepalives_count: nil,
            keepalives_idle: nil,
            keepalives_interval: nil,
            load_balancing: {
              hosts: []
            },
            password: nil,
            port: 5431,
            prepared_statements: false,
            socket: nil,
            sslca: nil,
            sslcompression: 0,
            sslmode: nil,
            sslrootcert: nil,
            statement_limit: nil,
            tcp_user_timeout: nil,
            username: 'gitlab_geo',
            variables: {
              statement_timeout: nil,
            }
          }
        )
      end

      it 'template triggers dependent services notifications' do
        expect(templatesymlink).to notify('ruby_block[Restart geo-secondary dependent services]').to(:run).delayed
      end
    end

    describe 'PostgreSQL gitlab-geo.conf' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
      let(:geo_conf) { '/var/opt/gitlab/postgresql/data/gitlab-geo.conf' }
      let(:postgresql_conf) { '/var/opt/gitlab/postgresql/data/postgresql.conf' }

      context 'when postgresql enabled on the node' do
        it 'renders gitlab-geo.conf' do
          expect(chef_run).to render_file(geo_conf)
        end
      end

      context 'when postgresql disabled on the node' do
        before { stub_gitlab_rb(postgresql: { enable: false }) }

        it 'does not render gitlab-geo.conf' do
          expect(chef_run).not_to render_file(geo_conf)
        end
      end
    end

    describe 'Restart geo-secondary dependent services' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      let(:ruby_block) { chef_run.ruby_block('Restart geo-secondary dependent services') }

      it 'does not run' do
        expect(chef_run).not_to run_ruby_block('Restart geo-secondary dependent services')
        expect(ruby_block).to do_nothing
      end

      it 'ruby_block triggers dependent services notifications' do
        allow(ruby_block).to receive(:notifies)
        ruby_block.block.call

        %w(
          puma
          geo-logcursor
        ).each do |svc|
          expect(ruby_block).to have_received(:notifies).with(:restart, "runit_service[#{svc}]")
        end
        expect(ruby_block).to have_received(:notifies).with(:restart, "sidekiq_service[sidekiq]")
      end
    end

    describe 'include_recipe' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'includes the Geo tracking DB recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::geo-postgresql')
      end

      it 'includes the Geo secondary recipes for Rails' do
        expect(chef_run).to include_recipe('gitlab-ee::geo-secondary')
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
      end

      it 'does not include the Geo database migrations recipe if Rails not needed' do
        stub_gitlab_rb(geo_secondary_role: { enable: true },
                       nginx: { enable: false },
                       puma: { enable: false },
                       sidekiq: { enable: false },
                       gitaly: { enable: false },
                       postgresql: { enable: false },
                       geo_logcursor: { enable: false },
                       redis: { enable: true })

        expect(chef_run).not_to include_recipe('gitlab-ee::geo_database_migrations')
      end
    end

    describe 'migrations' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'runs the migrations' do
        expect(chef_run).to run_rails_migration('gitlab-geo tracking')
      end
    end

    describe 'rails_needed?' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }

      context 'manually enabled services' do
        before do
          stub_gitlab_rb(
            # Everything but puma is disabled
            puma: { enable: true },
            sidekiq: { enable: false },
            geo_logcursor: { enable: false },
            gitaly: { enable: false }
          )
        end

        it 'should need rails' do
          expect(chef_run).to include_recipe('gitlab::gitlab-rails')
        end
      end

      context 'manually disabled services' do
        before do
          stub_gitlab_rb(
            gitaly: { enable: false },
            puma: { enable: false },
            sidekiq: { enable: false },
            geo_logcursor: { enable: false }
          )
        end

        it 'should not need rails' do
          expect(chef_run).not_to include_recipe('gitlab::gitlab-rails')
        end
      end
    end
  end

  context 'puma worker_processes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.automatic['cpu']['total'] = 16
        node.automatic['memory']['total'] = '8388608KB' # 8GB
      end.converge('gitlab-ee::default')
    end

    it 'reduces the number of puma workers on secondary node' do
      stub_gitlab_rb(geo_secondary_role: { enable: true })

      expect(chef_run.node['gitlab']['puma']['worker_processes']).to eq 5
    end

    it 'uses the specified number of puma workers' do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     puma: { worker_processes: 1 })

      expect(chef_run.node['gitlab']['puma']['worker_processes']).to eq 1
    end

    it 'does not reduce the number of puma workers on primary node' do
      stub_gitlab_rb(geo_primary_role: { enable: true })

      expect(chef_run.node['gitlab']['puma']['worker_processes']).to eq 6
    end
  end
end
