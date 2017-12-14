require 'chef_helper'

describe 'gitlab::gitlab-shell' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'calls into check permissions to create and validate the authorized_keys' do
    expect(chef_run).to run_execute('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-keys check-permissions')
  end

  context 'when NOT running on selinux' do
    before { stub_command('id -Z').and_return(false) }

    it 'should not run the semanage bash command' do
      expect(chef_run).not_to run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'when running on selinux' do
    before { stub_command('id -Z').and_return('') }

    it 'should run the semanage bash command' do
      expect(chef_run).to run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'with default settings' do
    it 'populates the default values' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
        .with_content { |content|
          expect(content).to match(
            %r{log_file: "/var/log/gitlab/gitlab-shell/gitlab-shell.log"}
          )
          expect(content).not_to match(/^custom_hooks_dir: /)
        }
    end
  end

  context 'with a non-default directory' do
    before do
      stub_gitlab_rb(gitlab_shell: {
                       dir: '/export/gitlab/gitlab-shell',
                     })
    end
    it 'creates config file in specified location' do
      expect(chef_run).to render_file('/export/gitlab/gitlab-shell/config.yml')
    end
  end

  context 'with a non-default log directory' do
    before do
      stub_gitlab_rb(gitlab_shell: {
                       log_directory: '/tmp/log',
                       git_trace_log_file: '/tmp/log/gitlab-shell-git-trace.log'
                     })
    end

    it 'populates the correct values' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
        .with_content(/git_trace_log_file: "\/tmp\/log\/gitlab-shell-git-trace.log"/)
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
        .with_content(/log_file: "\/tmp\/log\/gitlab-shell.log"/)
    end
  end

  context 'when using the default auth_file location' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/user/.ssh')
    end

    it 'creates the config file with the auth_file within user\'s ssh directory' do
      config = chef_run.find_resource(:template, '/var/opt/gitlab/gitlab-shell/config.yml').variables
      expect(config[:authorized_keys]).to eq('/tmp/user/.ssh/authorized_keys')
    end
  end

  context 'when using a different location for auth_file' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/ssh/authorized_keys' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/user/.ssh')
    end

    it 'creates the auth_file\'s parent directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/ssh')
    end

    it 'creates the config file with the auth_file at the specified location' do
      config = chef_run.find_resource(:template, '/var/opt/gitlab/gitlab-shell/config.yml').variables
      expect(config[:authorized_keys]).to eq('/tmp/ssh/authorized_keys')
    end
  end

  context 'with redis settings' do
    context 'and default configuration' do
      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/host: 127.0.0.1/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/port: /)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/socket: \/var\/opt\/gitlab\/redis\/redis.socket/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/database: /)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/namespace: resque:gitlab/)
        expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/sentinels: /)
      end
    end

    context 'and custom configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_database: 1,
            redis_password: 'PASSWORD!'
          }
        )
      end

      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/host: redis.example.com/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/port: 8888/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/database: 1/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/namespace: resque:gitlab/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/pass: PASSWORD!/)
        expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/socket: \/var\/opt\/gitlab\/redis\/redis.socket/)
      end
    end

    context 'with sentinels configured' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_sentinels: [
              { 'host' => 'redis1.sentinel', 'port' => 26370 },
              { 'host' => 'redis2.sentinel', 'port' => 26371 }
            ]
          },
          redis: {
            master_name: 'sentinel-master',
            master_password: 'PASSWORD!'
          }
        )
      end

      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/host: sentinel-master/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/port: 6379/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/namespace: resque:gitlab/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/pass: PASSWORD!/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/- {"host":"redis1.sentinel","port":26370}/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/- {"host":"redis2.sentinel","port":26371}/)
        expect(chef_run).not_to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/socket: \/var\/opt\/gitlab\/redis\/redis.socket/)
      end
    end
  end
  context 'with non-default gitlab_hooks setting' do
    before do
      stub_gitlab_rb(
        gitlab_shell: {
          custom_hooks_dir: '/fake/dir'
        }
      )
    end

    it 'populates with custom values' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
        .with_content(%r{custom_hooks_dir: "/fake/dir"})
    end
  end
end

describe 'gitlab_shell::git_data_dirs' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when git_data_dir is set as a single directory' do
    before { stub_gitlab_rb(git_data_dir: '/tmp/user/git-data') }

    it 'correctly sets the shell git data directories' do
      # Allow warn to be called for other messages without failing the test
      allow(Chef::Log).to receive(:warn)
      expect(Chef::Log).to receive(:warn).with(/Your git_data_dir settings are deprecated/)
      expect(chef_run.node['gitlab']['gitlab-shell']['git_data_directories'])
        .to eql('default' => { 'path' => '/tmp/user/git-data' })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/tmp/user/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
    end
  end

  context 'when gitaly is set to use a listen_addr instead of a socket' do
    before { stub_gitlab_rb(git_data_dirs: { 'default' => { 'path' => '/tmp/user/git-data' } }, gitaly: { socket_path: '', listen_addr: 'localhost:8123' }) }

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/tmp/user/git-data/repositories', 'gitaly_address' => 'tcp://localhost:8123' })
    end
  end

  context 'when git_data_dirs is set to multiple directories' do
    before do
      stub_gitlab_rb({
                       git_data_dirs: {
                         'default' => { 'path' => '/tmp/default/git-data' },
                         'overflow' => { 'path' => '/tmp/other/git-overflow-data' }
                       }
                     })
    end

    it 'correctly sets the shell git data directories' do
      expect(chef_run.node['gitlab']['gitlab-shell']['git_data_directories']).to eql({
                                                                                       'default' => { 'path' => '/tmp/default/git-data' },
                                                                                       'overflow' => { 'path' => '/tmp/other/git-overflow-data' }
                                                                                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'path' => '/tmp/default/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'path' => '/tmp/other/git-overflow-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
                                                                                      })
    end
  end

  context 'when git_data_dirs is set to multiple directories with different gitaly addresses' do
    before do
      stub_gitlab_rb({
                       git_data_dirs: {
                         'default' => { 'path' => '/tmp/default/git-data' },
                         'overflow' => { 'path' => '/tmp/other/git-overflow-data', 'gitaly_address' => 'tcp://localhost:8123', 'gitaly_token' => '123secret456gitaly' }
                       }
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'path' => '/tmp/default/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'path' => '/tmp/other/git-overflow-data/repositories', 'gitaly_address' => 'tcp://localhost:8123', 'gitaly_token' => '123secret456gitaly' }
                                                                                      })
    end
  end

  context 'when git_data_dirs is set with deprecated settings structure' do
    before do
      stub_gitlab_rb({
                       git_data_dirs: {
                         'default' => '/tmp/default/git-data',
                         'overflow' => '/tmp/other/git-overflow-data'
                       }
                     })
    end

    it 'correctly sets the shell git data directories' do
      # Allow warn to be called for other messages without failing the test
      allow(Chef::Log).to receive(:warn)
      expect(Chef::Log).to receive(:warn).with(/Your git_data_dirs settings are deprecated/)
      expect(chef_run.node['gitlab']['gitlab-shell']['git_data_directories']).to eql({
                                                                                       'default' => { 'path' => '/tmp/default/git-data' },
                                                                                       'overflow' => { 'path' => '/tmp/other/git-overflow-data' }
                                                                                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'path' => '/tmp/default/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'path' => '/tmp/other/git-overflow-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
                                                                                      })
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
end
