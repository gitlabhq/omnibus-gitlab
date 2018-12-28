require 'chef_helper'

describe 'gitlab::puma with Ubuntu 16.04' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service puma_config),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true })
    stub_default_should_notify?(true)
    stub_should_notify?('puma', true)
  end

  context 'when puma is enabled' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root', 'git', 'git'

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
      expect(chef_run.template('/var/opt/gitlab/gitlab-rails/etc/puma.rb')).to notify('service[puma]').to(:restart)
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(%r(^environment 'production'))
        expect(content).to match(%r(^rackup '/opt/gitlab/embedded/service/gitlab-rails/config.ru'))
        expect(content).to match(%r(^pidfile '/opt/gitlab/var/puma/puma.pid'))
        expect(content).to match(%r(^state_path '/opt/gitlab/var/puma/puma.state'))
        expect(content).to match(%r(^bind 'unix:///var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'))
        expect(content).to match(%r(^bind 'tcp://127.0.0.1:8080'))
        expect(content).to match(%r(^directory '/var/opt/gitlab/gitlab-rails/working'))
        expect(content).to match(%r(^require_relative "/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/cluster/lifecycle_events"$))
        expect(content).to match(/^options = { workers: 2 }$/)
        expect(content).to match(%r(Gitlab::Cluster::PumaWorkerKillerInitializer.start\(options, puma_per_worker_max_memory_mb: 650\)))
        expect(content).to match(/^preload_app!$/)
      }
    end
  end

  context 'with custom Puma settings' do
    before do
      stub_gitlab_rb(puma: {
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
                     }
                    )
    end

    it 'renders the puma.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(%r(state_path '/tmp/puma.state'))
        expect(content).to match(%r(bind 'unix:///tmp/puma.socket'))
        expect(content).to match(%r(bind 'tcp://10.0.0.1:9000'))
        expect(content).to match(%r(threads 5, 10))
        expect(content).to match(/^options = { workers: 4 }$/)
        expect(content).to match(%r(Gitlab::Cluster::PumaWorkerKillerInitializer.start\(options, puma_per_worker_max_memory_mb: 1000\)))
      }
    end
  end

  context 'with custom user and group' do
    before do
      stub_gitlab_rb(
        puma: { enable: true },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'puma', 'root', 'root', 'foo', 'bar'
  end

  context 'with custom runtime_dir' do
    before do
      stub_gitlab_rb(runtime_dir: '/tmp/test-dir',
                     puma: { enable: true })
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
    stub_gitlab_rb(puma: { enable: true })
  end

  context 'when puma is enabled on a node with no /run or /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root', 'git', 'git'

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
    stub_gitlab_rb(puma: { enable: true })
  end

  context 'when puma is enabled on a node with a /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root', 'git', 'git'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/dev\/shm\/gitlab\/puma/)
        }
    end
  end
end
