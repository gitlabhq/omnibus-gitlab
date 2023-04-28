require 'chef_helper'

RSpec.describe 'gitlab-ee::geo-secondary' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }
  let(:database_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
  let(:database_yml_file_content) { ChefSpec::Renderer.new(chef_run, database_yml_template).content }
  let(:database_yml) { YAML.safe_load(database_yml_file_content, [], [], true, symbolize_names: true) }

  let(:default_content) do
    {
      main: {
        adapter: 'postgresql',
        application_name: nil,
        collation: nil,
        connect_timeout: nil,
        database: "gitlabhq_production",
        database_tasks: true,
        encoding: "unicode",
        host: "/var/opt/gitlab/postgresql",
        keepalives: nil,
        keepalives_count: nil,
        keepalives_idle: nil,
        keepalives_interval: nil,
        load_balancing: {
          hosts: []
        },
        password: nil,
        port: 5432,
        prepared_statements: false,
        socket: nil,
        sslca: nil,
        sslcompression: 0,
        sslmode: nil,
        sslrootcert: nil,
        statement_limit: 1000,
        tcp_user_timeout: nil,
        username: "gitlab",
        variables: {
          statement_timeout: nil
        }
      }
    }
  end

  let(:default_geo_content) do
    {
      geo: {
        adapter: 'postgresql',
        application_name: nil,
        collation: nil,
        connect_timeout: nil,
        database: "gitlabhq_geo_production",
        database_tasks: true,
        migrations_paths: "ee/db/geo/migrate",
        schema_migrations_path: "ee/db/geo/schema_migrations",
        encoding: "unicode",
        host: "/var/opt/gitlab/geo-postgresql",
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
        username: "gitlab_geo",
        variables: {
          statement_timeout: nil
        }
      }
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  shared_examples 'renders database.yml without geo database' do
    context 'database.yml' do
      it 'renders database.yml without geo database' do
        expect(database_yml[:production].keys).not_to include(:geo)
      end

      context 'with geo database specified' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                geo: {
                  enable: true,
                  db_connect_timeout: 50
                }
              }
            }
          )
        end

        it 'renders database.yml without geo database' do
          expect(database_yml[:production].keys).not_to include(:geo)
        end
      end
    end
  end

  shared_examples 'renders database.yml with both main and geo databases' do
    context 'database.yml' do
      context 'with default settings' do
        it 'renders database.yml with main stanza first' do
          expect(database_yml_file_content).to match("production:\n  main:")
        end

        it 'renders database.yml with both main and geo databases using default values' do
          expected_output = default_content.merge(default_geo_content)

          expect(database_yml[:production]).to eq(expected_output)
        end
      end

      context 'with user provided settings' do
        context "via top level geo_secondary['db_*'] keys" do
          before do
            stub_gitlab_rb(
              geo_secondary: {
                db_database: 'foo',
                db_sslcompression: 1
              }
            )
          end

          it 'renders database.yml with user specified values for geo database' do
            expect(database_yml[:production][:geo][:database]).to eq('foo')
            expect(database_yml[:production][:geo][:sslcompression]).to eq(1)
          end
        end

        context "via gitlab_rails['databases']['geo'] settings" do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                databases: {
                  geo: {
                    enable: true,
                    db_database: 'bar',
                    db_sslcompression: 1
                  }
                }
              }
            )
          end

          it 'renders database.yml with user specified values for geo database' do
            expect(database_yml[:production][:geo][:database]).to eq('bar')
            expect(database_yml[:production][:geo][:sslcompression]).to eq(1)
          end
        end
      end

      context 'with geo database specified but not enabled' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              databases: {
                main: {
                  db_connect_timeout: 30
                },
                geo: {
                  db_connect_timeout: 50
                }
              }
            }
          )
        end

        it 'renders database.yml without geo database' do
          expect(database_yml[:production].keys).not_to include(:geo)
        end
      end

      context 'dependent services' do
        let(:templatesymlink) { chef_run.templatesymlink('Add the geo database settings to database.yml and create a symlink to Rails root') }

        it 'triggers dependent services notifications' do
          expect(templatesymlink).to notify('ruby_block[Restart geo-secondary dependent services]').to(:run).delayed
        end
      end
    end
  end

  describe 'when geo_secondary_role is disabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: false })
    end

    it_behaves_like 'renders database.yml without geo database'
  end

  describe 'when geo_secondary_role is disabled but geo-postgresql enabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: false },
                     geo_postgresql: { enable: true })
    end

    it_behaves_like 'renders database.yml without geo database'
  end

  describe 'when gitlab_rails is disabled, but geo_secondary_role is enabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     gitlab_rails: { enable: false })
    end

    it 'does not render the geo-secondary files' do
      expect(chef_run).not_to create_templatesymlink('Add the geo database settings to database.yml and create a symlink to Rails root')
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
      expect(chef_run.node['gitlab']['gitlab_rails']['enable']).to be true
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
                     geo_postgresql: { enable: false })
    end

    context 'migrations' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'includes the database migration recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::geo_database_migrations')
      end
    end

    it_behaves_like 'renders database.yml with both main and geo databases'
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

    it_behaves_like 'renders database.yml with both main and geo databases'

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

    describe 'restart geo-secondary dependent services' do
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
