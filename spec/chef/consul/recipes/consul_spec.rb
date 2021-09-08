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
          custom_config_dir: '/custom/dir'
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

      it 'includes the configure_services recipe' do
        expect(chef_run).to include_recipe('consul::configure_services')
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

      it 'notifies other resources on configuration change' do
        config_json = chef_run.file('/var/opt/gitlab/consul/config.json')
        expect(config_json).to notify('execute[reload consul]').to(:run)
        expect(config_json).to notify('ruby_block[consul config change]').to(:run)
      end

      it 'renders run file with specified options' do
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/run').with_content(%r{-config-dir /fake/config.d})
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/run').with_content(%r{-config-dir /custom/dir})
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/run').with_content(%r{-data-dir /fake/data})
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

    describe 'pending restart check' do
      context 'when running version is same as installed version' do
        before do
          allow_any_instance_of(ConsulHelper).to receive(:running_version).and_return('1.9.6')
          allow_any_instance_of(ConsulHelper).to receive(:installed_version).and_return('1.9.6')
        end

        it 'does not raise a warning' do
          expect(chef_run).not_to run_ruby_block('warn pending consul restart')
        end
      end

      context 'when running version is different than installed version' do
        before do
          allow_any_instance_of(ConsulHelper).to receive(:running_version).and_return('1.6.4')
          allow_any_instance_of(ConsulHelper).to receive(:installed_version).and_return('1.9.6')
        end

        it 'raises a warning' do
          expect(chef_run).to run_ruby_block('warn pending consul restart')
        end
      end
    end
  end
end
