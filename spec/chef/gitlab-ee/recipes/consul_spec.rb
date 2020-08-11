require 'chef_helper'

RSpec.describe 'consul' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:consul_conf) { '/var/opt/gitlab/consul/config.json' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'disabled by default' do
    it 'includes the disable recipe' do
      expect(chef_run).to include_recipe('consul::disable')
    end
  end

  describe 'consul::disable' do
    it_behaves_like 'disabled runit service', 'consul'
  end

  context 'when enabled' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          config_dir: '/fake/config.d',
          data_dir: '/fake/data',
          services: %w(postgresql)
        }
      )
    end

    it 'includes the enable recipe' do
      expect(chef_run).to include_recipe('consul::enable')
    end

    describe 'consul::enable' do
      it_behaves_like 'enabled runit service', 'consul', 'gitlab-consul', 'gitlab-consul', 'gitlab-consul', 'gitlab-consul'

      it 'creates the consul system user and group' do
        expect(chef_run).to create_account('Consul user and group').with(username: 'gitlab-consul', groupname: 'gitlab-consul')
      end

      it 'includes the postgresql_service recipe' do
        expect(chef_run).to include_recipe('consul::service_postgresql')
      end

      it 'only enables the agent by default' do
        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).to match(%r{"server":false})
        }
      end

      it 'does not include nil values in its configuration' do
        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).not_to match(%r{"encryption":})
        }
      end

      it 'does not include server default values in its configuration' do
        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).not_to match(%r{"bootstrap_expect":3})
        }
      end

      it 'creates the necessary directories' do
        expect(chef_run).to create_directory('/fake/config.d')
        expect(chef_run).to create_directory('/fake/data')
        expect(chef_run).to create_directory('/var/log/gitlab/consul')
      end

      it 'notifies the reload action' do
        config_json = chef_run.file('/var/opt/gitlab/consul/config.json')
        expect(config_json).to notify('execute[reload consul]').to(:run)
      end
    end

    context 'with default options' do
      it 'allows the user to specify node name' do
        stub_gitlab_rb(
          consul: {
            enable: true
          }
        )
        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).to match(%r{"datacenter":"gitlab_consul"})
          expect(content).to match(%r{"disable_update_check":true})
          expect(content).to match(%r{"enable_script_checks":true})
          expect(content).to match(%r{"node_name":"fauxhai.local"})
          expect(content).to match(%r{"rejoin_after_leave":true})
          expect(content).to match(%r{"server":false})
        }
      end
    end

    context 'with non-default options' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            node_name: 'fakenodename',
            username: 'foo',
            group: 'bar',
          }
        )
      end

      it 'allows the user to specify node name' do
        expect(chef_run).to render_file(consul_conf).with_content('"node_name":"fakenodename"')
      end

      it 'creates the consul system user and group' do
        expect(chef_run).to create_account('Consul user and group').with(username: 'foo', groupname: 'bar')
      end

      it_behaves_like 'enabled runit service', 'consul', 'foo', 'bar', 'foo', 'bar'
    end

    context 'server enabled' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            configuration: {
              server: true
            }
          }
        )
      end

      it 'enables the server functionality' do
        expect(chef_run.node['consul']['configuration']['server']).to eq true
        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).to match(%r{"server":true})
          expect(content).to match(%r{"bootstrap_expect":3})
        }
      end
    end
  end

  describe 'consul::service_postgresql' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    context 'default' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            services: %w(postgresql)
          }
        )
      end

      it 'renders the service configuration file' do
        rendered = {
          'service' => {
            'name' => 'postgresql',
            'address' => '',
            'port' => 5432,
            'check' => {
              'id' => 'service:postgresql',
              'args' => ["/opt/gitlab/bin/gitlab-ctl", "repmgr-check-master"],
              'interval' => '10s',
              'status' => 'failing'
            }
          },
          'watches' => [
            {
              'type' => 'keyprefix',
              'prefix' => 'gitlab/ha/postgresql/failed_masters/',
              'args' => ["/opt/gitlab/bin/gitlab-ctl", "consul", "watchers", "handle-failed-master"]
            }
          ]
        }
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/postgresql_service.json').with_content { |content|
          expect(JSON.parse(content)).to eq(rendered)
        }
      end
    end

    context 'when patroni is enabled' do
      before do
        stub_gitlab_rb(
          patroni: {
            enable: true
          },
          consul: {
            enable: true,
            services: %w(postgresql)
          }
        )
      end

      it 'renders the service configuration file' do
        rendered = {
          'service' => {
            'name' => 'postgresql',
            'address' => '',
            'port' => 5432,
            'check' => {
              'id' => 'service:postgresql',
              'args' => ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-leader'],
              'interval' => '10s',
              'status' => 'failing'
            }
          }
        }
        expect(chef_run).to render_file('/var/opt/gitlab/consul/config.d/postgresql_service.json').with_content { |content|
          expect(JSON.parse(content)).to eq(rendered)
        }
      end
    end
  end

  describe 'consul::watchers' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
    let(:watcher_conf) { '/var/opt/gitlab/consul/config.d/watcher_postgresql.json' }
    let(:watcher_check) { '/var/opt/gitlab/consul/scripts/failover_pgbouncer' }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(
        consul: {
          enable: true,
          watchers: %w(
            postgresql
          )
        }
      )
    end

    it 'includes the watcher recipe' do
      expect(chef_run).to include_recipe('consul::watchers')
    end

    it 'creates the watcher config file' do
      rendered = {
        'watches' => [
          {
            'type' => 'service',
            'service' => 'postgresql',
            'args' => [watcher_check]
          }
        ]
      }

      expect(chef_run).to render_file(watcher_conf).with_content { |content|
        expect(JSON.parse(content)).to eq(rendered)
      }
    end

    it 'creates the watcher handler file' do
      expect(chef_run).to render_file(watcher_check)
    end
  end
end
