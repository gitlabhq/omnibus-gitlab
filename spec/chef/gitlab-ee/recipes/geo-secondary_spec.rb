require 'chef_helper'

describe 'gitlab-ee::geo-secondary' do
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
                     unicorn: { enable: false },
                     sidekiq: { enable: false },
                     sidekiq_cluster: { enable: false },
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
                       unicorn: { enable: false },
                       sidekiq: { enable: false },
                       sidekiq_cluster: { enable: false },
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
                       unicorn: { enable: false },
                       sidekiq: { enable: false },
                       sidekiq_cluster: { enable: false },
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

      context 'when geo_secondary["auto_migrate"] is false' do
        it 'does not run the migrations' do
          stub_gitlab_rb(geo_secondary: { auto_migrate: false })

          expect(chef_run).not_to run_bash('migrate gitlab-geo tracking database')
        end
      end

      context 'when geo_secondary["auto_migrate"] is true' do
        it 'runs the migrations' do
          expect(chef_run).to run_bash('migrate gitlab-geo tracking database')
        end
      end
    end

    describe 'database.yml' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'creates the template' do
        expect(chef_run).to create_templatesymlink('Create a database_geo.yml and create a symlink to Rails root').with_variables(
          hash_including(
            "db_database" => "gitlabhq_geo_production",
            "db_host" => "1.1.1.1",
            "db_port" => "5431",
            "db_sslcompression" => 0
          )
        )
      end

      context 'when SSL compression is enabled' do
        before do
          stub_gitlab_rb(geo_secondary: { db_sslcompression: 1 })
        end

        it 'uses provided value in database.yml' do
          expect(chef_run).to create_templatesymlink('Create a database_geo.yml and create a symlink to Rails root').with_variables(
            hash_including(
              "db_sslcompression" => 1
            )
          )
        end
      end
    end
  end

  context 'when geo_secondary_role is enabled' do
    before do
      stub_gitlab_rb(geo_secondary_role: { enable: true })

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
        sidekiq-cluster
        unicorn
        puma
        gitaly
        geo-postgresql
        gitlab-pages
        geo-logcursor
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    describe 'database.yml' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      let(:templatesymlink) { chef_run.templatesymlink('Create a database_geo.yml and create a symlink to Rails root') }

      it 'creates the template' do
        expect(chef_run).to create_templatesymlink('Create a database_geo.yml and create a symlink to Rails root').with_variables(
          hash_including(
            "db_database" => "gitlabhq_geo_production",
            "db_host" => "/var/opt/gitlab/geo-postgresql"
          )
        )
      end

      it 'template triggers dependent services notifications' do
        expect(templatesymlink).to notify('ruby_block[Restart geo-secondary dependent services]').to(:run).delayed
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
          unicorn
          sidekiq
          geo-logcursor
        ).each do |svc|
          expect(ruby_block).to have_received(:notifies).with(:restart, "runit_service[#{svc}]")
        end
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
                       unicorn: { enable: false },
                       sidekiq: { enable: false },
                       postgresql: { enable: false },
                       geo_logcursor: { enable: false },
                       redis: { enable: true })

        expect(chef_run).not_to include_recipe('gitlab-ee::geo_database_migrations')
      end
    end

    describe 'migrations' do
      let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

      it 'runs the migrations' do
        expect(chef_run).to run_bash('migrate gitlab-geo tracking database')
      end
    end
  end

  context 'unicorn worker_processes' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.automatic['cpu']['total'] = 16
        node.automatic['memory']['total'] = '8388608KB' # 8GB
      end.converge('gitlab-ee::default')
    end

    it 'reduces the number of unicorn workers on secondary node' do
      stub_gitlab_rb(geo_secondary_role: { enable: true })

      expect(chef_run.node['gitlab']['unicorn']['worker_processes']).to eq 9
    end

    it 'uses the specified number of unicorn workers' do
      stub_gitlab_rb(geo_secondary_role: { enable: true },
                     unicorn: { worker_processes: 1 })

      expect(chef_run.node['gitlab']['unicorn']['worker_processes']).to eq 1
    end

    it 'does not reduce the number of unicorn workers on primary node' do
      stub_gitlab_rb(geo_primary_role: { enable: true })

      expect(chef_run.node['gitlab']['unicorn']['worker_processes']).to eq 11
    end
  end
end
