require 'chef_helper'

RSpec.describe 'gitlab::puma with Ubuntu 16.04' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service puma_config),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(/lowlevel_error_handler/)
        expect(content).to include('Raven.capture_exception')
      }
    end

    it 'creates sysctl files' do
      expect(chef_run).to create_gitlab_sysctl('net.core.somaxconn').with_value(1024)
    end
  end

  context 'with custom Puma settings' do
    before do
      stub_gitlab_rb(
        puma: {
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
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
        state_path: '/tmp/puma.state',
        listen_socket: '/tmp/puma.socket',
        listen_tcp: '10.0.0.1:9000',
        worker_processes: 4,
        min_threads: 5,
        max_threads: 10,
        per_worker_max_memory_mb: 1000
      )
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
        expect(content).to match(%r(-authSocket /tmp/puma.socket))
      }
      expect(Gitlab['gitlab_workhorse']['auth_socket']).to eq('/tmp/puma.socket')
    end
  end

  context 'with SSL enabled' do
    let(:base_params) do
      {
        puma: {
          worker_timeout: 120,
          worker_processes: 4,
          min_threads: 5,
          max_threads: 10,
          socket: '/tmp/puma.socket',
          listen: '10.0.0.1',
          port: 9000,
          ssl_listen: '192.168.0.1',
          ssl_port: 9999,
          ssl_certificate: '/tmp/test.crt',
          ssl_certificate_key: '/tmp/test.key'
        }
      }
    end
    let(:params) { base_params }

    before do
      stub_gitlab_rb(params)
    end

    it 'renders the puma.rb file' do
      expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
        ssl_listen_host: '192.168.0.1',
        ssl_port: 9999,
        listen_socket: '/tmp/puma.socket',
        listen_tcp: '10.0.0.1:9000',
        worker_processes: 4,
        min_threads: 5,
        max_threads: 10
      )

      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(/ssl_bind '192.168.0.1', 9999, {\n  cert: '\/tmp\/test.crt',\n  key: '\/tmp\/test.key',\n  verify_mode: 'none'\n}/m)
      }
    end

    it 'uses HTTPS instead of a UNIX socket for the Workhorse auth backend' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
        expect(content).to match(%r(-authBackend https://192.168.0.1:9999))
        expect(content).not_to match(%r(-authSocket /tmp/puma.socket))
      }
      expect(Gitlab['gitlab_workhorse']['auth_socket']).to be_nil
      expect(Gitlab['gitlab_workhorse']['auth_backend']).to eq('https://192.168.0.1:9999')
    end

    context 'with UNIX socket and HTTP disabled' do
      let(:params) do
        {
          puma: {
            worker_timeout: 120,
            worker_processes: 4,
            min_threads: 5,
            max_threads: 10,
            socket: '',
            listen: '',
            port: 9000,
            ssl_listen: '192.168.0.1',
            ssl_port: 9999,
            ssl_certificate: '/tmp/test.crt',
            ssl_certificate_key: '/tmp/test.key'
          }
        }
      end

      it 'omits the UNIX socket and TCP binds from the Puma config' do
        expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
          ssl_listen_host: '192.168.0.1',
          ssl_port: 9999,
          listen_socket: '',
          listen_tcp: nil,
          worker_processes: 4,
          min_threads: 5,
          max_threads: 10
        )

        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
          expect(content).not_to match(%r(bind 'unix://))
          expect(content).not_to match(%r(bind 'tcp://))
          expect(content).to match(/ssl_bind '192.168.0.1', 9999, {\n  cert: '\/tmp\/test.crt',\n  key: '\/tmp\/test.key',\n  verify_mode: 'none'\n}/m)
        }
      end
    end

    context 'with other SSL options configured' do
      let(:filter) { '!aNULL:AES+SHA' }
      let(:client_cert) { '/tmp/client.crt' }

      let(:params) do
        base_params.tap do |config|
          config[:puma][:ssl_client_certificate] = client_cert
          config[:puma][:ssl_cipher_filter] = filter
          config[:puma][:ssl_verify_mode] = 'peer'
        end
      end

      it 'renders the puma.rb file' do
        expect(chef_run).to create_puma_config('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with(
          ssl_listen_host: '192.168.0.1',
          ssl_port: 9999,
          listen_socket: '/tmp/puma.socket',
          listen_tcp: '10.0.0.1:9000',
          ssl_cipher_filter: filter,
          worker_processes: 4,
          min_threads: 5,
          max_threads: 10
        )

        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
          expect(content).to match(/ssl_bind '192.168.0.1', 9999, {\n  cert: '\/tmp\/test.crt',\n  key: '\/tmp\/test.key',\n  ca: '#{client_cert}',\n  ssl_cipher_filter: '#{Regexp.escape(filter)}',\n  verify_mode: 'peer'\n}/m)
        }
      end
    end
  end

  context 'with custom user and group' do
    before do
      stub_gitlab_rb(
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
        runtime_dir: '/tmp/test-dir'
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

  context 'with ActionCable enabled' do
    before do
      stub_gitlab_rb(
        actioncable: {
          worker_pool_size: 7
        }
      )
    end

    it 'renders the runit configuration with ActionCable environment variables' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/ACTION_CABLE_WORKER_POOL_SIZE=7/)
          expect(content).to match(%r(/opt/gitlab/embedded/bin/bundle exec puma -C /var/opt/gitlab/gitlab-rails/etc/puma.rb))
        }
    end
  end

  include_examples "consul service discovery", "puma", "rails"
end

RSpec.describe 'gitlab::puma Ubuntu 16.04 with no tmpfs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04-no-run-tmpfs.json',
      step_into: %w(runit_service)
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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

RSpec.describe 'gitlab::puma Ubuntu 16.04 Docker' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04-docker.json',
      step_into: %w(runit_service)
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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

RSpec.describe 'gitlab::puma with more CPUs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04-more-cpus.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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

RSpec.describe 'gitlab::puma with no total CPUs' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04-no-total-cpus.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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

RSpec.describe 'gitlab::puma with Raspberry Pi 4' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/22.04-rpi4.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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
        worker_processes: 2
      )
    end
  end
end
