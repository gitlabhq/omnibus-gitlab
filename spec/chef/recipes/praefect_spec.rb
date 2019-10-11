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
    let(:virtual_storage_name) { nil }
    let(:auth_token) { nil }
    let(:auth_transitioning) { false }
    let(:virtual_storage_name) { nil }
    let(:listen_addr) { nil }
    let(:prom_addr) { nil }
    let(:log_level) { nil }
    let(:log_format) { nil }
    let(:nodes) { nil }

    before do
      stub_gitlab_rb(praefect: {
                       enable: true,
                       socket_path: socket_path,
                       virtual_storage_name: virtual_storage_name,
                       auth_token: auth_token,
                       auth_transitioning: auth_transitioning,
                       listen_addr: listen_addr,
                       prometheus_listen_addr: prom_addr,
                       logging_level: log_level,
                       logging_format: log_format,
                       storage_nodes: nodes
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
      expect(chef_run).to render_file(config_path)
        .with_content("listen_addr = 'localhost:2305'")
      expect(chef_run).to render_file(config_path)
        .with_content("prometheus_listen_addr = 'localhost:9652'")
      expect(chef_run).not_to render_file(config_path)
        .with_content('level =')
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[logging\]\s+format = 'json'\n})

      expect(chef_run).not_to render_file(config_path)
        .with_content('[[node]]')
    end

    context 'with custom settings' do
      let(:socket_path) { '/var/opt/gitlab/praefect/praefect.socket' }
      let(:virtual_storage_name) { 'praefect' }
      let(:auth_token) { 'secrettoken123' }
      let(:auth_transitioning) { false }
      let(:listen_addr) { 'localhost:4444' }
      let(:prom_addr) { 'localhost:1234' }
      let(:log_level) { 'debug' }
      let(:log_format) { 'text' }
      let(:nodes) do
        [
          { storage: 'praefect1', address: 'tcp://node1.internal', primary: true, token: "praefect1-token" },
          { storage: 'praefect2', address: 'tcp://node2.internal', primary: 'true', token: "praefect2-token" },
          { storage: 'praefect3', address: 'tcp://node3.internal', primary: false, token: "praefect3-token" },
          { storage: 'praefect4', address: 'tcp://node4.internal', primary: 'false', token: "praefect4-token" },
          { storage: 'praefect5', address: 'tcp://node5.internal', token: "praefect5-token" }
        ]
      end
      let(:primaries) { %w[praefect1 praefect2] }

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

        nodes.each do |node|
          expect_primary = primaries.include?(node[:storage])

          expect(chef_run).to render_file(config_path)
            .with_content(%r{^\[\[node\]\]\nstorage = '#{node[:storage]}'\naddress = '#{node[:address]}'\ntoken = '#{node[:token]}'\nprimary = #{expect_primary}\n})
        end
      end
    end
  end
end
