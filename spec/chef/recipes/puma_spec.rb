require 'chef_helper'

describe 'gitlab::puma with Ubuntu 16.04' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true }, unicorn: { enable: false })
    stub_default_should_notify?(true)
    stub_should_notify?('puma', true)
  end

  context 'when puma is enabled' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    describe 'logrotate settings' do
      context 'default values' do
        it_behaves_like 'configured logrotate service', 'puma', 'git', 'git'
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

        it_behaves_like 'configured logrotate service', 'puma', 'foo', 'bar'
      end
    end

    it 'creates runtime directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/puma').with(
        owner: 'git',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/opt/gitlab/var/puma').with(
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
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/rm \/run\/gitlab\/puma/)
          expect(content).to match(/-u git:git/)
          expect(content).to match(/-U git:git/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/puma/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/puma/)
          expect(content).to match(/chown git \/run\/gitlab\/puma/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/puma\'/)
          expect(content).to match(%r(/opt/gitlab/embedded/bin/bundle exec puma -C /var/opt/gitlab/gitlab-rails/etc/puma.rb))
        }
    end

    it 'renders the puma.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
        tag: 'gitlab-puma-worker',
        rackup: 'config.ru',
        environment: 'production',
        pid: '/opt/gitlab/var/puma/puma.pid',
        state_path: '/opt/gitlab/var/puma/puma.state',
        listen_socket: '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket',
        listen_tcp: '127.0.0.1:8080',
        working_directory: '/var/opt/gitlab/gitlab-rails/working',
        worker_processes: 2,
        min_threads: 4,
        max_threads: 4
      )
    end
  end

  context 'with custom Puma settings' do
    before do
      stub_gitlab_rb(
        puma: {
          enable: true,
          worker_timeout: 120,
          worker_processes: 4,
          min_threads: 5,
          max_threads: 10,
          listen: '10.0.0.1',
          port: 9000,
          socket: '/tmp/puma.socket',
          state_path: '/tmp/puma.state',
          per_worker_max_memory_mb: 1000
        },
        unicorn: {
          enable: false
        }
      )
    end

    it 'renders the puma.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
        state_path: '/tmp/puma.state',
        listen_socket: '/tmp/puma.socket',
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
        puma: {
          enable: true
        },
        unicorn: {
          enable: false
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'
  end

  context 'with custom runtime_dir' do
    before do
      stub_gitlab_rb(
        runtime_dir: '/tmp/test-dir',
        puma: {
          enable: true
        },
        unicorn: {
          enable: false
        }
      )
    end

    it 'uses the user-specific runtime_dir' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(%r(export prometheus_run_dir='/tmp/test-dir/gitlab/puma'))
          expect(content).to match(%r(mkdir -p /tmp/test-dir/gitlab/puma))
        }
    end
  end
end

describe 'gitlab::puma Ubuntu 16.04 with no tmpfs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-no-run-tmpfs.json',
      step_into: %w(runit_service)
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true }, unicorn: { enable: false })
  end

  context 'when puma is enabled on a node with no /run or /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/run\/gitlab\/puma/)
        }
    end
  end
end

describe 'gitlab::puma Ubuntu 16.04 Docker' do
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
      puma: {
        enable: true
      },
      unicorn: {
        enable: false
      }
    )
  end

  context 'when puma is enabled on a node with a /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\/dev\/shm\/gitlab\/puma\'/)
          expect(content).to match(/mkdir -p \/dev\/shm\/gitlab\/puma/)
        }
    end
  end
end

describe 'gitlab::puma with more CPUs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-more-cpus.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      puma: {
        enable: true
      },
      unicorn: {
        enable: false
      }
    )
  end

  context 'when puma is enabled' do
    it 'renders the puma.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
        environment: 'production',
        pid: '/opt/gitlab/var/puma/puma.pid',
        state_path: '/opt/gitlab/var/puma/puma.state',
        listen_socket: '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket',
        listen_tcp: '127.0.0.1:8080',
        working_directory: '/var/opt/gitlab/gitlab-rails/working',
        worker_processes: 16
      )
    end
  end
end
