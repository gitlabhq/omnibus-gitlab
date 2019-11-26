require 'chef_helper'
describe 'praefect' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when the defaults are used' do
    it_behaves_like 'disabled runit service', 'praefect'
  end

  context 'when praefect is enabled' do
    let(:config_path) { '/var/opt/gitlab/praefect/config.toml' }
    let(:socket_path) { nil }
    let(:auth_token) { nil }
    let(:auth_transitioning) { false }
    let(:listen_addr) { nil }
    let(:prom_addr) { nil }
    let(:log_level) { nil }
    let(:log_format) { nil }
    let(:virtual_storages) { nil }

    before do
      stub_gitlab_rb(praefect: {
                       enable: true,
                       socket_path: socket_path,
                       auth_token: auth_token,
                       auth_transitioning: auth_transitioning,
                       listen_addr: listen_addr,
                       prometheus_listen_addr: prom_addr,
                       logging_level: log_level,
                       logging_format: log_format,
                       virtual_storages: virtual_storages,
                     })
    end

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/praefect').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file' do
      expect(chef_run).to create_file('/var/opt/gitlab/praefect/VERSION').with(
        user: nil,
        group: nil
      )
    end

    it 'renders the config.toml' do
      rendered = {
        'auth' => { 'token' => '', 'transitioning' => false },
        'listen_addr' => 'localhost:2305',
        'logging' => { 'format' => 'json' },
        'prometheus_listen_addr' => 'localhost:9652',
      }

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(Tomlrb.parse(content)).to eq(rendered)
      }
    end

    context 'with custom settings' do
      let(:socket_path) { '/var/opt/gitlab/praefect/praefect.socket' }
      let(:auth_token) { 'secrettoken123' }
      let(:auth_transitioning) { false }
      let(:listen_addr) { 'localhost:4444' }
      let(:prom_addr) { 'localhost:1234' }
      let(:log_level) { 'debug' }
      let(:log_format) { 'text' }
      let(:primaries) { %w[praefect1 praefect2] }
      let(:virtual_storages) do
        {
          'default' => {
            'praefect1' => { address: 'tcp://node1.internal', primary: true, token: "praefect1-token" },
            'praefect2' => { address: 'tcp://node2.internal', primary: 'true', token: "praefect2-token" },
            'praefect3' => { address: 'tcp://node3.internal', primary: false, token: "praefect3-token" },
            'praefect4' => { address: 'tcp://node4.internal', primary: 'false', token: "praefect4-token" },
            'praefect5' => { address: 'tcp://node5.internal', token: "praefect5-token" }
          }
        }
      end

      it 'renders the config.toml' do
        expect(chef_run).to render_file(config_path)
          .with_content("listen_addr = '#{listen_addr}'")
        expect(chef_run).to render_file(config_path)
          .with_content("socket_path = '#{socket_path}'")
        expect(chef_run).to render_file(config_path)
          .with_content("prometheus_listen_addr = '#{prom_addr}'")
        expect(chef_run).to render_file(config_path)
          .with_content("level = '#{log_level}'")
        expect(chef_run).to render_file(config_path)
          .with_content("format = '#{log_format}'")

        expect(chef_run).to render_file(config_path)
          .with_content(%r{^\[auth\]\ntoken = '#{auth_token}'\ntransitioning = #{auth_transitioning}\n})

        virtual_storages.each do |name, nodes|
          expect(chef_run).to render_file(config_path).with_content(%r{^\[\[virtual_storage\]\]\nname = '#{name}'\n})
          nodes.each do |storage, node|
            expect_primary = primaries.include?(storage)

            expect(chef_run).to render_file(config_path)
              .with_content(%r{^\[\[virtual_storage.node\]\]\nstorage = '#{storage}'\naddress = '#{node[:address]}'\ntoken = '#{node[:token]}'\nprimary = #{expect_primary}\n})
          end
        end
      end

      context 'with virtual_storages as an array' do
        let(:virtual_storages) { [{ name: 'default', 'nodes' => [{ storage: 'praefect1', address: 'tcp://node1.internal', primary: true, token: "praefect1-token" }] }] }

        it 'raises an error' do
          expect { chef_run }.to raise_error("Praefect virtual_storages must be a hash")
        end
      end

      context 'with nodes within virtual_storages as an array' do
        let(:virtual_storages) { { 'default' => [{ storage: 'praefect1', address: 'tcp://node1.internal', primary: true, token: "praefect1-token" }] } }

        it 'raises an error' do
          expect { chef_run }.to raise_error("nodes of a Praefect virtual_storage must be a hash")
        end
      end
    end
  end
end
