require 'chef_helper'

describe 'gitlab::gitlab-shell' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'calls into check permissions to create and validate the authorized_keys' do
    expect(chef_run).to run_execute('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-keys check-permissions')
  end

  it 'defaults the auth_file to be within the user\'s home directory' do
    stub_gitlab_rb(user: { home: '/tmp/user' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/user/.ssh/authorized_keys')
  end

  it 'uses custom auth_files set in gitlab.rb' do
    stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/authorized_keys')
  end

  context 'when NOT running on selinux' do
    before { stub_command('id -Z').and_return(false) }

    it 'should not run the semanage bash command' do
      expect(chef_run).not_to run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'when running on selinux' do
    before { stub_command('id -Z').and_return('') }

    let(:bash_block) { chef_run.bash('Set proper security context on ssh files for selinux') }

    def semanage_fcontext(filename)
      "semanage fcontext -a -t ssh_home_t '#{filename}'"
    end

    it 'should run the semanage bash command' do
      expect(chef_run).to run_bash('Set proper security context on ssh files for selinux')
    end

    it 'sets the security context of gitlab-shell files' do
      lines = bash_block.code.split("\n")
      files = %w(/var/opt/gitlab/.ssh(/.*)?
                 /var/opt/gitlab/.ssh/authorized_keys
                 /var/opt/gitlab/gitlab-shell/config.yml
                 /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret)
      managed_files = files.map { |file| semanage_fcontext(file) }

      expect(lines).to include(*managed_files)
      expect(lines).to include("restorecon -R -v '/var/opt/gitlab/.ssh'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/.ssh/authorized_keys' '/var/opt/gitlab/gitlab-shell/config.yml'")
      expect(lines).to include("restorecon -v -i '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'")
    end
  end

  context 'with default settings' do
    it 'create config file in default location with default values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          log_file: '/var/log/gitlab/gitlab-shell/gitlab-shell.log',
          log_format: nil,
          custom_hooks_dir: nil
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
      expect(chef_run).to create_storage_directory('/tmp/user/.ssh').with(owner: 'git', mode: '0700')
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
      expect(chef_run).to create_storage_directory('/tmp/user/.ssh').with(owner: 'git', mode: '0700')
    end

    it 'creates the auth_file\'s parent directory' do
      expect(chef_run).to create_storage_directory('/tmp/ssh').with(owner: 'git', mode: '0700')
    end

    it 'creates the config file with the auth_file at the specified location' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          authorized_keys: '/tmp/ssh/authorized_keys'
        )
      )
    end
  end

  context 'with custom settings' do
    before do
      stub_gitlab_rb(
        gitlab_shell: {
          custom_hooks_dir: '/fake/dir',
          log_format: 'json'
        }
      )
    end

    it 'creates the config file with custom values' do
      expect(chef_run).to create_templatesymlink('Create a config.yml and create a symlink to Rails root').with_variables(
        hash_including(
          custom_hooks_dir: '/fake/dir',
          log_format: 'json'
        )
      )
    end
  end
end
