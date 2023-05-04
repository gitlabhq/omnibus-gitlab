require 'chef_helper'

RSpec.describe 'gitlab::gitlab-shell' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'defaults the auth_file to be within the user\'s home directory' do
    stub_gitlab_rb(user: { home: '/tmp/user' })
    expect(chef_run.node['gitlab']['gitlab_shell']['auth_file']).to eq('/tmp/user/.ssh/authorized_keys')
  end

  it 'uses custom auth_files set in gitlab.rb' do
    stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run.node['gitlab']['gitlab_shell']['auth_file']).to eq('/tmp/authorized_keys')
  end

  it 'creates authorized_keys file if missing' do
    stub_gitlab_rb(gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run).to create_file_if_missing('/tmp/authorized_keys')
  end

  context 'with default settings' do
    it 'create config file in default location with default values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          secret_file: '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret',
          log_file: '/var/log/gitlab/gitlab-shell/gitlab-shell.log',
          log_format: "json",
          migration: { enabled: true, features: [] },
          gitlab_url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
          gitlab_relative_path: '',
          ssl_cert_dir: '/opt/gitlab/embedded/ssl/certs/',
          gitlab_sshd: nil
        )
      )
    end

    it 'renders gitlab-shell config' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml').with_content { |content|
        data = YAML.safe_load(content)

        expect(data['secret_file']).to eq('/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret')
        expect(data['log_file']).to eq('/var/log/gitlab/gitlab-shell/gitlab-shell.log')
        expect(data['log_format']).to eq('json')
        expect(data['migration']).to eq({ "enabled" => true, "features" => [] })
        expect(data['gitlab_url']).to eq('http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket')
        expect(data['gitlab_relative_path']).to be_nil
        expect(data['ssl_cert_dir']).to eq('/opt/gitlab/embedded/ssl/certs/')
        expect(data['sshd']).to be_nil
      }
    end
  end

  context 'with a non-default directory' do
    before do
      stub_gitlab_rb(gitlab_shell: {
                       dir: '/export/gitlab/gitlab-shell',
                     })
    end

    it 'create config file in specified location with default values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_link_to('/export/gitlab/gitlab-shell/config.yml')
    end
  end

  context 'when using the default auth_file location' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to create_storage_directory('/tmp/user/.ssh').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the config file with the auth_file within user\'s ssh directory' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          authorized_keys: '/tmp/user/.ssh/authorized_keys'
        )
      )
    end
  end

  context 'when using a different location for auth_file' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/ssh/authorized_keys' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to create_storage_directory('/tmp/user/.ssh').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the auth_file\'s parent directory' do
      expect(chef_run).to create_storage_directory('/tmp/ssh').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the config file with the auth_file at the specified location' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          authorized_keys: '/tmp/ssh/authorized_keys'
        )
      )
    end
  end

  context 'when manage-storage-directories is disabled' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }, manage_storage_directories: { enable: false }) }

    it 'doesn\'t create the ssh dir in the user\'s home directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/user/.ssh')
    end
  end

  context 'with custom settings' do
    before do
      stub_gitlab_rb(
        gitlab_shell: {
          log_format: 'json',
          migration: {
            enabled: true,
            features: ['discover']
          }
        }
      )
    end

    it 'creates the config file with custom values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          log_format: 'json',
          migration: {
            enabled: true,
            features: ['discover']
          }
        )
      )
    end

    context 'migration is disabled (set to false)' do
      before do
        stub_gitlab_rb(
          gitlab_shell: {
            migration: {
              enabled: false,
              features: []
            }
          }
        )
      end

      it 'creates the config file with migration disabled' do
        expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
          hash_including(
            migration: {
              enabled: false,
              features: []
            }
          )
        )
      end
    end

    context 'with a non-default workhorse unix socket' do
      context 'without sockets_directory defined' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { listen_addr: '/fake/workhorse/socket' })
        end

        it 'create config file with provided values' do
          expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
            hash_including(
              gitlab_url: 'http+unix://%2Ffake%2Fworkhorse%2Fsocket',
              gitlab_relative_path: ''
            )
          )
        end
      end

      context 'with sockets_directory defined' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { 'sockets_directory': '/fake/workhorse/sockets/' })
        end

        it 'create config file with provided values' do
          expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
            hash_including(
              gitlab_url: 'http+unix://%2Ffake%2Fworkhorse%2Fsockets%2Fsocket',
              gitlab_relative_path: ''
            )
          )
        end
      end
    end

    context 'with a tcp workhorse listener' do
      before do
        stub_gitlab_rb(
          external_url: 'http://example.com/gitlab',
          gitlab_workhorse: {
            listen_network: 'tcp',
            listen_addr: 'localhost:1234'
          }
        )
      end

      it 'create config file with provided values' do
        expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
          hash_including(
            gitlab_url: 'http://localhost:1234/gitlab',
            gitlab_relative_path: nil,
            secret_file: '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'
          )
        )
      end
    end

    context 'with relative path in external_url' do
      before do
        stub_gitlab_rb(external_url: 'http://example.com/gitlab')
      end

      it 'create config file with provided values' do
        expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
          hash_including(
            gitlab_url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
            gitlab_relative_path: '/gitlab',
            secret_file: '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'
          )
        )
      end
    end

    context 'with internal_api_url specified' do
      before do
        stub_gitlab_rb(gitlab_rails: { internal_api_url: 'http://localhost:8080' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
          hash_including(
            gitlab_url: 'http://localhost:8080',
            gitlab_relative_path: ''
          )
        )
      end
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      it_behaves_like 'enabled logged service', 'gitlab-shell', false, { log_directory_owner: 'git' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          gitlab_shell: {
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'configured logrotate service', 'gitlab-shell', 'git', 'fugee'
      it_behaves_like 'enabled logged service', 'gitlab-shell', false, { log_directory_owner: 'git', log_group: 'fugee' }
    end
  end

  context 'with gitlab-sshd enabled' do
    let(:templatesymlink) { chef_run.templatesymlink('Create a config.yml and create a symlink to Rails root') }
    let(:expected_sshd_keys) do
      %w[listen proxy_protocol proxy_policy web_listen concurrent_sessions_limit client_alive_interval
         grace_period login_grace_time proxy_header_timeout macs kex_algorithms ciphers host_key_files host_key_certs]
    end

    before do
      stub_gitlab_rb(
        gitlab_sshd: {
          enable: true,
        }
      )
    end

    before do
      allow(Dir).to receive(:[]).and_call_original
    end

    context 'with default host key and cert globs' do
      let(:host_key) { %w(/tmp/host_keys/ssh_key) }
      let(:default_host_key_glob) { '/var/opt/gitlab/gitlab-sshd/ssh_host_*_key' }
      let(:default_host_cert_glob) { '/var/opt/gitlab/gitlab-sshd/ssh_host_*-cert.pub' }

      before do
        allow(Dir).to receive(:[]).with(default_host_key_glob).and_return(host_key)
        allow(Dir).to receive(:[]).with(default_host_cert_glob).and_return([])
      end

      it 'renders gitlab-sshd config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml').with_content { |content|
          data = YAML.safe_load(content)

          expect(data['sshd'].keys).to match_array(expected_sshd_keys)
          expect(data['sshd']['host_key_files']).to eq(host_key)
          expect(data['sshd']['host_key_certs']).to be_empty
          expect(data['sshd']['listen']).to eq('localhost:2222')
          expect(data['sshd']['web_listen']).to eq('localhost:9122')
          expect(data['sshd']['proxy_protocol']).to be false
        }
      end

      it 'template triggers notifications' do
        expect(templatesymlink).to notify('runit_service[gitlab-sshd]').to(:restart).delayed
      end

      it 'correctly renders out the gitlab_sshd service file' do
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-sshd/run")
          .with_content { |content|
            expect(content).to include('cd /var/opt/gitlab/gitlab-sshd')
            expect(content).to include('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-sshd')
            expect(content).to include('-config-dir /var/opt/gitlab/gitlab-shell')
          }
      end
    end

    context 'with custom host key path' do
      let(:host_key_glob) { '/tmp/host_keys/ssh_key*' }
      let(:host_cert_glob) { '/tmp/host_keys/ssh_cert*' }
      let(:host_keys) { %w(/tmp/host_keys/ssh_key1 /tmp/host_keys/ssh_key2) }
      let(:host_certs) { %w(/tmp/host_keys/ssh_cert1 /tmp/host_keys/ssh_cert2) }

      before do
        stub_gitlab_rb(
          gitlab_sshd: {
            enable: true,
            log_directory: '/tmp/log',
            host_keys_dir: '/tmp/host_keys',
            host_keys_glob: 'ssh_key*',
            host_certs_dir: '/tmp/host_keys',
            host_certs_glob: 'ssh_cert*'
          }
        )

        allow(Dir).to receive(:[]).with(host_key_glob).and_return(host_keys)
        allow(Dir).to receive(:[]).with(host_cert_glob).and_return(host_certs)
      end

      it 'renders gitlab-sshd config' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml').with_content { |content|
          data = YAML.safe_load(content)

          expect(data['sshd'].keys).to match_array(expected_sshd_keys)
          expect(data['sshd']['host_key_files']).to eq(host_keys)
          expect(data['sshd']['host_key_certs']).to eq(host_certs)
        }
      end
    end

    context 'log directory and runit group' do
      context 'default values' do
        it_behaves_like 'enabled logged service', 'gitlab-sshd', false, { log_directory_owner: 'git' }
      end

      context 'custom values' do
        before do
          stub_gitlab_rb(
            gitlab_sshd: {
              enable: true,
              log_group: 'fugee'
            }
          )
        end
        # it_behaves_like 'configured logrotate service', 'gitlab-sshd', 'git', 'fugee'
        it_behaves_like 'enabled logged service', 'gitlab-sshd', false, { log_directory_owner: 'git', log_group: 'fugee' }
      end
    end
  end
end
