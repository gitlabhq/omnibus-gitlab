require 'chef_helper'

describe 'gitlab::actioncable with Ubuntu 16.04' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(actioncable: { enable: true })
    stub_default_should_notify?(true)
    stub_should_notify?('actioncable', true)
  end

  context 'when actioncable is enabled' do
    it_behaves_like 'enabled runit service', 'actioncable', 'root', 'root', 'git', 'git'

    describe 'logrotate settings' do
      context 'default values' do
        it_behaves_like 'configured logrotate service', 'actioncable', 'git', 'git'
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

        it_behaves_like 'configured logrotate service', 'actioncable', 'foo', 'bar'
      end
    end

    it 'creates runtime directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/actioncable').with(
        owner: 'git',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/opt/gitlab/var/actioncable').with(
        owner: 'git',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/gitlab-rails/sockets').with(
        owner: 'git',
        group: 'gitlab-www',
        mode: '0750'
      )
    end

    it 'renders the runit configuration with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/actioncable/run')
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/rm \/run\/gitlab\/actioncable/)
          expect(content).to match(/-u git:git/)
          expect(content).to match(/-U git:git/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/actioncable/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/actioncable/)
          expect(content).to match(/chown git \/run\/gitlab\/actioncable/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/actioncable\'/)
          expect(content).to match(%r(/opt/gitlab/embedded/bin/bundle exec puma -C /var/opt/gitlab/gitlab-rails/etc/puma_actioncable.rb))
        }
    end

    it 'renders the puma_actioncable.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma_actioncable.rb').with(
        tag: 'gitlab-puma-actioncable-worker',
        rackup: 'cable/config.ru',
        environment: 'production',
        pid: '/opt/gitlab/var/actioncable/actioncable.pid',
        state_path: '/opt/gitlab/var/actioncable/actioncable.state',
        listen_socket: '/var/opt/gitlab/gitlab-rails/sockets/gitlab_actioncable.socket',
        listen_tcp: '127.0.0.1:8280',
        working_directory: '/var/opt/gitlab/gitlab-rails/working',
        worker_processes: 2,
        min_threads: 4,
        max_threads: 4
      )
    end
  end

  context 'with custom ActionCable settings' do
    before do
      stub_gitlab_rb(
        actioncable: {
          enable: true,
          worker_timeout: 120,
          worker_processes: 4,
          min_threads: 5,
          max_threads: 10,
          listen: '10.0.0.1',
          port: 9000,
          socket: '/tmp/actioncable.socket',
          state_path: '/tmp/actioncable.state',
          per_worker_max_memory_mb: 1000
        }
      )
    end

    it 'renders the puma_actioncable.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma_actioncable.rb').with(
        state_path: '/tmp/actioncable.state',
        listen_socket: '/tmp/actioncable.socket',
        listen_tcp: '10.0.0.1:9000',
        worker_processes: 4,
        min_threads: 5,
        max_threads: 10,
        per_worker_max_memory_mb: 1000
      )
    end
  end

  context 'with custom user and group' do
    before do
      stub_gitlab_rb(
        actioncable: {
          enable: true
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'actioncable', 'root', 'root', 'foo', 'bar'
  end

  context 'with custom runtime_dir' do
    before do
      stub_gitlab_rb(
        runtime_dir: '/tmp/test-dir',
        actioncable: {
          enable: true
        }
      )
    end

    it 'uses the user-specific runtime_dir' do
      expect(chef_run).to render_file('/opt/gitlab/sv/actioncable/run')
        .with_content { |content|
          expect(content).to match(%r(export prometheus_run_dir='/tmp/test-dir/gitlab/actioncable'))
          expect(content).to match(%r(mkdir -p /tmp/test-dir/gitlab/actioncable))
        }
    end
  end
end

describe 'gitlab::actioncable Ubuntu 16.04 with no tmpfs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-no-run-tmpfs.json',
      step_into: %w(runit_service)
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(actioncable: { enable: true })
  end

  context 'when ActionCable is enabled on a node with no /run or /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'actioncable', 'root', 'root', 'git', 'git'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/actioncable/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/run\/gitlab\/actioncable/)
        }
    end
  end
end

describe 'gitlab::actioncable Ubuntu 16.04 Docker' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-docker.json',
      step_into: %w(runit_service)
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      actioncable: {
        enable: true
      }
    )
  end

  context 'when actioncable is enabled on a node with a /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'actioncable', 'root', 'root', 'git', 'git'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/actioncable/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\/dev\/shm\/gitlab\/actioncable\'/)
          expect(content).to match(/mkdir -p \/dev\/shm\/gitlab\/actioncable/)
        }
    end
  end
end
