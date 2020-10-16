require 'chef_helper'

RSpec.describe 'gitlab::gitlab-shell' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'logrotate settings' do
    context 'default values' do
      it_behaves_like 'configured logrotate service', 'gitlab-shell', 'git', 'git'
    end

    context 'specified username and group' do
      before do
        stub_gitlab_rb(
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'configured logrotate service', 'gitlab-shell', 'foo', 'bar'
    end
  end

  it 'defaults the auth_file to be within the user\'s home directory' do
    stub_gitlab_rb(user: { home: '/tmp/user' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/user/.ssh/authorized_keys')
  end

  it 'uses custom auth_files set in gitlab.rb' do
    stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/authorized_keys')
  end

  it 'creates authorized_keys file if missing' do
    stub_gitlab_rb(gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run).to create_file_if_missing('/tmp/authorized_keys')
  end

  context 'with default settings' do
    it 'create config file in default location with default values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          log_file: '/var/log/gitlab/gitlab-shell/gitlab-shell.log',
          log_format: "json",
          custom_hooks_dir: nil,
          migration: { enabled: true, features: [] },
          gitlab_url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
          gitlab_relative_path: ''
        )
      )
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

  context 'with a non-default log directory' do
    before do
      stub_gitlab_rb(gitlab_shell: {
                       log_directory: '/tmp/log',
                       git_trace_log_file: '/tmp/log/gitlab-shell-git-trace.log'
                     })
    end

    it 'create config file with provided values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          log_file: '/tmp/log/gitlab-shell.log',
          git_trace_log_file: '/tmp/log/gitlab-shell-git-trace.log'
        )
      )
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
          custom_hooks_dir: '/fake/dir',
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
          custom_hooks_dir: '/fake/dir',
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
            gitlab_relative_path: nil
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
            gitlab_relative_path: '/gitlab'
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
end
