require 'chef_helper'

RSpec.describe 'consul' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:consul_conf) { '/var/opt/gitlab/consul/config.json' }
  let(:consul_conf_chef_file) { chef_run.file(consul_conf) }
  let(:consul_conf_file_content) { ChefSpec::Renderer.new(chef_run, consul_conf_chef_file).content }
  let(:consul_conf_json) { JSON.parse(consul_conf_file_content) }

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
      it_behaves_like 'enabled runit service', 'consul', 'gitlab-consul', 'gitlab-consul', 'gitlab-consul', 'gitlab-consul', true

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
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/run').with_content { |content|
          expect(content).to match(%r{-config-dir /fake/config.d})
          expect(content).to match(%r{-config-dir /custom/dir})
          expect(content).to match(%r{-data-dir /fake/data})
        }
      end

      it 'renders log run file with timestamp option' do
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/log/run').with_content { |content|
          expect(content).to match(%r{svlogd -tt /var/log/gitlab/consul})
        }
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
          expect(content).to match(%r{"enable_script_checks":false})
          expect(content).to match(%r{"enable_local_script_checks":true})
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
            configuration: {
              log_json: true
            },
            logging_filters: {
              label: 'filter'
            }
          }
        )
      end

      it 'allows the user to specify node name' do
        expect(chef_run).to render_file(consul_conf).with_content('"node_name":"fakenodename"')
      end

      it 'creates the consul system user and group' do
        expect(chef_run).to create_account('Consul user and group').with(username: 'foo', groupname: 'bar')
      end

      it 'renders log run file without timestamp option' do
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/log/run').with_content { |content|
          expect(content).to match(%r{svlogd /var/log/gitlab/consul})
        }
      end

      it 'renders log config with logging_filters keys/values as comments/values' do
        expect(chef_run).to render_file('/opt/gitlab/sv/consul/log/config').with_content { |content|
          expect(content).to match(%r{# label\nfilter})
        }
      end

      it_behaves_like 'enabled runit service', 'consul', 'foo', 'bar', 'foo', 'bar', true
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

  describe 'encryption' do
    it 'is not enabled by default' do
      stub_gitlab_rb(
        consul: {
          enable: true,
        }
      )

      expect(chef_run).to render_file(consul_conf).with_content { |content|
        expect(content).not_to match(%r{"encrypt":})
        expect(content).not_to match(%r{"encrypt_verify_incoming":})
        expect(content).not_to match(%r{"encrypt_verify_outgoing":})
      }
    end

    context 'new datacenter' do
      it 'uses encryption key and falls back to defaults' do
        stub_gitlab_rb(
          consul: {
            enable: true,
            encryption_key: 'fake_key'
          }
        )

        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).to match(%r{"encrypt":"fake_key"})
          expect(content).not_to match(%r{"encrypt_verify_incoming":})
          expect(content).not_to match(%r{"encrypt_verify_outgoing":})
        }
      end
    end

    context 'existing datacenter' do
      it 'uses encryption key and specified verification settings' do
        stub_gitlab_rb(
          consul: {
            enable: true,
            encryption_key: 'fake_key',
            encryption_verify_incoming: false,
            encryption_verify_outgoing: true,
          }
        )

        expect(chef_run).to render_file(consul_conf).with_content { |content|
          expect(content).to match(%r{"encrypt":"fake_key"})
          expect(content).to match(%r{"encrypt_verify_incoming":false})
          expect(content).to match(%r{"encrypt_verify_outgoing":true})
        }
      end
    end
  end

  describe 'TLS configuration' do
    context 'in client mode' do
      context 'by default' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true
            }
          )
        end

        it 'verifies outgoing connections only' do
          expected_output = {
            'defaults' => {
              'verify_incoming' => false,
              'verify_outgoing' => true
            }
          }

          expect(consul_conf_json['tls']).to eq(expected_output)
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true,
              tls_ca_file: '/fake/ca.crt.pem',
              tls_certificate_file: '/fake/server.crt.pem',
              tls_key_file: '/fake/server.key.pem',
              tls_verify_client: true,
              https_port: 8501
            }
          )
        end

        it 'verifies incoming and outgoing connections' do
          expected_output = {
            'defaults' => {
              'verify_incoming' => true,
              'verify_outgoing' => true,
              'ca_file' => '/fake/ca.crt.pem',
              'cert_file' => '/fake/server.crt.pem',
              'key_file' => '/fake/server.key.pem',
            }
          }

          expect(consul_conf_json['ports']).to eq({ 'https' => 8501 })
          expect(consul_conf_json['tls']).to eq(expected_output)
        end
      end
    end

    context 'in server mode' do
      context 'by default' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true,
              configuration: {
                server: true
              }
            }
          )
        end

        it 'verifies outgoing and incoming connections' do
          expected_output = {
            'defaults' => {
              'verify_incoming' => true,
              'verify_outgoing' => true
            }
          }

          expect(consul_conf_json['tls']).to eq(expected_output)
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true,
              tls_ca_file: '/fake/ca.crt.pem',
              tls_certificate_file: '/fake/server.crt.pem',
              tls_key_file: '/fake/server.key.pem',
              tls_verify_client: false,
              https_port: 8501
            }
          )
        end

        it 'verifies outgoing connection only' do
          expected_output = {
            'defaults' => {
              'verify_incoming' => false,
              'verify_outgoing' => true,
              'ca_file' => '/fake/ca.crt.pem',
              'cert_file' => '/fake/server.crt.pem',
              'key_file' => '/fake/server.key.pem',
            }
          }

          expect(consul_conf_json['ports']).to eq({ 'https' => 8501 })
          expect(consul_conf_json['tls']).to eq(expected_output)
        end
      end
    end

    context 'using both dedicated consul TLS configuration settings and general configuration hash' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            use_tls: true,
            tls_ca_file: '/fake/ca.crt.pem',
            tls_certificate_file: '/fake/server.crt.pem',
            tls_key_file: '/fake/server.key.pem',
            tls_verify_client: false,
            https_port: 8501,
            configuration: {
              tls: {
                defaults: {
                  cert_file: '/foo/server.crt',
                  key_file: '/foo/server.key',
                  ca_file: '/foo/ca.crt'
                }
              }
            }
          }
        )
      end

      it 'uses the settings given in general configuration hash' do
        expected_output = {
          'defaults' => {
            'verify_incoming' => false,
            'verify_outgoing' => true,
            'ca_file' => '/foo/ca.crt',
            'cert_file' => '/foo/server.crt',
            'key_file' => '/foo/server.key',
          }
        }

        expect(consul_conf_json['tls']).to eq(expected_output)
      end

      context 'using deprecated settings' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              use_tls: true,
              configuration: {
                cert_file: '/foo/server.crt',
                key_file: '/foo/server.key',
                ca_file: '/foo/ca.crt'
              }
            }
          )
        end

        it 'generates the configuration file properly' do
          expected_output = {
            'defaults' => {
              'verify_incoming' => false,
              'verify_outgoing' => true,
              'ca_file' => '/foo/ca.crt',
              'cert_file' => '/foo/server.crt',
              'key_file' => '/foo/server.key',
            }
          }

          expect(consul_conf_json['tls']).to eq(expected_output)
        end

        it 'generates deprecation notices' do
          chef_run

          expect_logged_deprecation(%r{`consul\['configuration'\]\['ca_file'\]` has been deprecated.*`consul\['configuration'\]\['tls'\]\['defaults'\]\['ca_file'\]`})
          expect_logged_deprecation(%r{`consul\['configuration'\]\['cert_file'\]` has been deprecated.*`consul\['configuration'\]\['tls'\]\['defaults'\]\['cert_file'\]`})
          expect_logged_deprecation(%r{`consul\['configuration'\]\['key_file'\]` has been deprecated.*`consul\['configuration'\]\['tls'\]\['defaults'\]\['key_file'\]`})
        end
      end
    end
  end

  describe 'using deprecated ACL token settings' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          configuration: {
            acl: {
              tokens: {
                master: 'foo',
                agent_master: 'bar'
              }
            }
          }
        }
      )
    end

    it 'generates the configuration file properly' do
      expected_output = {
        'tokens' => {
          'initial_management' => 'foo',
          'agent_recovery' => 'bar'
        }
      }

      expect(consul_conf_json['acl']).to eq(expected_output)
    end

    it 'generates deprecation notices' do
      chef_run

      expect_logged_deprecation(%r{`consul\['configuration'\]\['acl'\]\['tokens'\]\['master'\]` has been deprecated.*`consul\['configuration'\]\['acl'\]\['tokens'\]\['initial_management'\]`})
      expect_logged_deprecation(%r{`consul\['configuration'\]\['acl'\]\['tokens'\]\['agent_master'\]` has been deprecated.*`consul\['configuration'\]\['acl'\]\['tokens'\]\['agent_recovery'\]`})
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
          }
        )
      end
      it_behaves_like 'enabled logged service', 'consul', true, { log_directory_owner: 'gitlab-consul', log_directory_mode: '0755' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'consul', true, { log_directory_owner: 'gitlab-consul', log_group: 'fugee' }
    end
  end
end
