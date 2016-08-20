require 'chef_helper'

describe 'gitlab::gitlab-shell' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  it 'calls into check permissions to create and validate the authorized_keys' do
    expect(chef_run).to run_execute('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-keys check-permissions')
  end

  context 'when NOT running on selinux' do
    before { stub_command('id -Z').and_return(false) }

    it 'should not run the chcon bash command' do
      expect(chef_run).to_not run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'when running on selinux' do
    before { stub_command('id -Z').and_return('') }

    it 'should run the chcon bash command' do
      expect(chef_run).to run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'when using the default auth_file location' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to create_directory('/tmp/user/.ssh').with(
        user: 'git',
        group: 'git',
        mode: '0700'
      )
    end

    it 'creates the config file with the auth_file within user\'s ssh directory' do
      config = chef_run.find_resource(:template, '/var/opt/gitlab/gitlab-shell/config.yml').variables
      expect(config[:authorized_keys]).to eq('/tmp/user/.ssh/authorized_keys')
    end
  end

  context 'when using a different location' do
    before { stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/ssh/authorized_keys' }) }

    it 'creates the ssh dir in the user\'s home directory' do
      expect(chef_run).to create_directory('/tmp/user/.ssh').with(
        user: 'git',
        group: 'git',
        mode: '0700'
      )
    end

    it 'creates the auth_file\'s parent directory with the correct permissions' do
      expect(chef_run).to create_directory('/tmp/ssh').with(
        user: 'git',
        group: 'git',
        mode: '0700'
      )
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
          .with_content(/bin: \/opt\/gitlab\/embedded\/bin\/redis-cli/)
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
        expect(chef_run).to_not render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/sentinels: /)
      end
    end

    context 'and custom configuration' do
      before {
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_database: 1,
            redis_password: "PASSWORD!",
            redis_sentinels: [
              {'host' => 'redis1.sentinel', 'port' => 26370},
              {'host' => 'redis2.sentinel', 'port' => 26371}
            ]
          }
        )
      }

      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/bin: \/opt\/gitlab\/embedded\/bin\/redis-cli/)
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
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/- {"host":"redis1.sentinel","port":26370}/)
        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/- {"host":"redis2.sentinel","port":26371}/)
        expect(chef_run).to_not render_file('/var/opt/gitlab/gitlab-shell/config.yml')
          .with_content(/socket: \/var\/opt\/gitlab\/redis\/redis.socket/)
      end
    end
  end
end
