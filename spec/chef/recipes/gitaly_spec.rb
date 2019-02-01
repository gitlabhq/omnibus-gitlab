require 'chef_helper'

describe 'gitaly' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:config_path) { '/var/opt/gitlab/gitaly/config.toml' }
  let(:gitaly_config) { chef_run.template(config_path) }
  let(:socket_path) { '/tmp/gitaly.socket' }
  let(:listen_addr) { 'localhost:7777' }
  let(:tls_listen_addr) { 'localhost:8888' }
  let(:certificate_path) { '/path/to/cert.pem' }
  let(:key_path) { '/path/to/key.pem' }
  let(:prometheus_listen_addr) { 'localhost:9000' }
  let(:logging_level) { 'warn' }
  let(:logging_format) { 'json' }
  let(:logging_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project' }
  let(:logging_ruby_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project-ruby' }
  let(:prometheus_grpc_latency_buckets) do
    '[0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]'
  end
  let(:auth_token) { '123secret456' }
  let(:auth_transitioning) { true }
  let(:ruby_max_rss) { 1000000 }
  let(:ruby_graceful_restart_timeout) { '30m' }
  let(:ruby_restart_delay) { '10m' }
  let(:ruby_num_workers) { 5 }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'TZ' => ':/etc/localtime',
      'HOME' => '/var/opt/gitlab',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.4/site-packages',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it_behaves_like "enabled runit service", "gitaly", "root", "root", "git", "git"

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly').with(user: 'git', mode: '0700')
      expect(chef_run).to create_directory('/var/log/gitlab/gitaly').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file' do
      expect(chef_run).to create_file('/var/opt/gitlab/gitaly/VERSION').with(
        user: nil,
        group: nil
      )
    end

    it 'populates gitaly config.toml with defaults' do
      expect(chef_run).to render_file(config_path)
        .with_content("socket_path = '/var/opt/gitlab/gitaly/gitaly.socket'")
      expect(chef_run).to render_file(config_path)
        .with_content("bin_dir = '/opt/gitlab/embedded/bin'")
      expect(chef_run).not_to render_file(config_path)
        .with_content("listen_addr = '#{listen_addr}'")
      expect(chef_run).not_to render_file(config_path)
        .with_content("tls_listen_addr =")
      expect(chef_run).not_to render_file(config_path)
       .with_content("certificate_path  =")
      expect(chef_run).not_to render_file(config_path)
       .with_content("key_path  =")
      expect(chef_run).not_to render_file(config_path)
        .with_content("prometheus_listen_addr = '#{prometheus_listen_addr}'")
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level = '#{logging_level}'\s+format = '#{logging_format}'\s+sentry_dsn = '#{logging_sentry_dsn}'})
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level = '#{logging_level}'\s+format = '#{logging_format}'\s+ruby_sentry_dsn = '#{logging_ruby_sentry_dsn}'})
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[prometheus\]\s+grpc_latency_buckets = #{Regexp.escape(prometheus_grpc_latency_buckets)}})
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[auth\]\s+token = })
      expect(chef_run).not_to render_file(config_path)
        .with_content('transitioning =')
      expect(chef_run).not_to render_file(config_path)
        .with_content('max_rss =')
      expect(chef_run).not_to render_file(config_path)
        .with_content('graceful_restart_timeout =')
      expect(chef_run).not_to render_file(config_path)
        .with_content('restart_delay =')
      expect(chef_run).not_to render_file(config_path)
        .with_content('num_workers =')
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level})
    end

    it 'populates gitaly config.toml with default storages' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = 'default'\s+path = '/var/opt/gitlab/git-data/repositories'})
    end

    it 'populates sv related log files' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/gitaly/)
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        gitaly: {
          socket_path: socket_path,
          listen_addr: listen_addr,
          tls_listen_addr: tls_listen_addr,
          certificate_path: certificate_path,
          key_path: key_path,
          prometheus_listen_addr: prometheus_listen_addr,
          logging_level: logging_level,
          logging_format: logging_format,
          logging_sentry_dsn: logging_sentry_dsn,
          logging_ruby_sentry_dsn: logging_ruby_sentry_dsn,
          prometheus_grpc_latency_buckets: prometheus_grpc_latency_buckets,
          auth_token: auth_token,
          auth_transitioning: auth_transitioning,
          ruby_max_rss: ruby_max_rss,
          ruby_graceful_restart_timeout: ruby_graceful_restart_timeout,
          ruby_restart_delay: ruby_restart_delay,
          ruby_num_workers: ruby_num_workers,
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like "enabled runit service", "gitaly", "root", "root", "foo", "bar"

    it 'populates gitaly config.toml with custom values' do
      expect(chef_run).to render_file(config_path)
        .with_content("socket_path = '#{socket_path}'")
      expect(chef_run).to render_file(config_path)
        .with_content("bin_dir = '/opt/gitlab/embedded/bin'")
      expect(chef_run).to render_file(config_path)
        .with_content("listen_addr = 'localhost:7777'")
      expect(chef_run).to render_file(config_path)
        .with_content { |content|
          expect(content).to include("tls_listen_addr = 'localhost:8888'")
          expect(content).to include("certificate_path = '/path/to/cert.pem'")
          expect(content).to include("key_path = '/path/to/key.pem'")
        }
      expect(chef_run).to render_file(config_path)
        .with_content("prometheus_listen_addr = 'localhost:9000'")

      gitaly_logging_section = Regexp.new([
        %r{\[logging\]},
        %r{level = '#{logging_level}'},
        %r{format = '#{logging_format}'},
        %r{sentry_dsn = '#{logging_sentry_dsn}'},
        %r{ruby_sentry_dsn = '#{logging_ruby_sentry_dsn}'},
      ].map(&:to_s).join('\s+'))
      expect(chef_run).to render_file(config_path)
        .with_content(gitaly_logging_section)

      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[prometheus\]\s+grpc_latency_buckets = #{Regexp.escape(prometheus_grpc_latency_buckets)}})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[auth\]\s+token = '#{Regexp.escape(auth_token)}'\s+transitioning = true})

      gitaly_ruby_section = Regexp.new([
        %r{\[gitaly-ruby\]},
        %r{dir = "/opt/gitlab/embedded/service/gitaly-ruby"},
        %r{max_rss = #{ruby_max_rss}},
        %r{graceful_restart_timeout = '#{Regexp.escape(ruby_graceful_restart_timeout)}'},
        %r{restart_delay = '#{Regexp.escape(ruby_restart_delay)}'},
        %r{num_workers = #{ruby_num_workers}},
      ].map(&:to_s).join('\s+'))
      expect(chef_run).to render_file(config_path)
        .with_content(gitaly_ruby_section)
    end

    it 'does not append timestamp in logs if logging format is json' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/exec svlogd \/var\/log\/gitlab\/gitaly/)
    end

    context 'when using gitaly storage configuration' do
      before do
        stub_gitlab_rb(
          gitaly: {
            storage: [
              {
                'name' => 'default',
                'path' => '/tmp/path-1'
              },
              {
                'name' => 'nfs1',
                'path' => '/mnt/nfs1'
              }
            ]
          }
        )
      end

      it 'populates gitaly config.toml with custom storages' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[\[storage\]\]\s+name = 'default'\s+path = '/tmp/path-1'})
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[\[storage\]\]\s+name = 'nfs1'\s+path = '/mnt/nfs1'})
      end
    end

    context 'when using git_data_dirs storage configuration' do
      before do
        stub_gitlab_rb(
          {
            git_data_dirs:
            {
              'default' => { 'path' => '/tmp/default/git-data' },
              'nfs1' => { 'path' => '/mnt/nfs1' }
            }
          }
        )
      end

      it 'populates gitaly config.toml with custom storages' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[\[storage\]\]\s+name = 'default'\s+path = '/tmp/default/git-data/repositories'})
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[\[storage\]\]\s+name = 'nfs1'\s+path = '/mnt/nfs1/repositories'})
        expect(chef_run).not_to render_file(config_path)
          .with_content('gitaly_address: "/var/opt/gitlab/gitaly/gitaly.socket"')
      end
    end
  end

  context 'when gitaly is disabled' do
    before do
      stub_gitlab_rb(gitaly: { enable: false })
    end

    it_behaves_like "disabled runit service", "gitaly"

    it 'does not create the gitaly directories' do
      expect(chef_run).not_to create_directory('/var/opt/gitlab/gitaly')
      expect(chef_run).not_to create_directory('/var/log/gitlab/gitaly')
      expect(chef_run).not_to create_directory('/opt/gitlab/etc/gitaly')
      expect(chef_run).not_to create_file('/var/opt/gitlab/gitaly/config.toml')
    end
  end

  context 'when using concurrency configuration' do
    before do
      stub_gitlab_rb(
        {
          gitaly: {
            concurrency: [
              {
                'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                'max_per_repo' => 20
              }, {
                'rpc' => "/gitaly.SSHService/SSHUploadPack",
                'max_per_repo' => 5
              }
            ]
          }
        }
      )
    end

    it 'populates gitaly config.toml with custom concurrency configurations' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[concurrency\]\]\s+rpc = "/gitaly.SmartHTTPService/PostReceivePack"\s+max_per_repo = 20})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[concurrency\]\]\s+rpc = "/gitaly.SSHService/SSHUploadPack"\s+max_per_repo = 5})
    end
  end

  shared_examples 'empty concurrency configuration' do
    it 'does not generate a gitaly concurrency configuration' do
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[\[concurrency\]\]})
    end
  end

  context 'when not using concurrency configuration' do
    context 'when concurrency configuration is not set' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
            }
          }
        )
      end

      it_behaves_like 'empty concurrency configuration'
    end

    context 'when concurrency configuration is empty' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
              concurrency: []
            }
          }
        )
      end

      it_behaves_like 'empty concurrency configuration'
    end
  end

  context 'populates default env variables' do
    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitaly/env').with_variables(default_vars)
    end
  end

  context 'computes env variables based on other values' do
    before do
      stub_gitlab_rb(
        {
          user: {
            home: "/my/random/path"
          }
        }
      )
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitaly/env').with_variables(
        default_vars.merge(
          {
            'HOME' => '/my/random/path',
          }
        )
      )
    end
  end
end

describe 'gitaly::git_data_dirs' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when user has not specified git_data_dir' do
    it 'defaults to correct path' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/var/opt/gitlab/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
    end
  end

  context 'when gitaly is set to use a listen_addr' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       socket_path: '',
                       listen_addr: 'localhost:8123'
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/tmp/user/git-data/repositories', 'gitaly_address' => 'tcp://localhost:8123' })
    end
  end

  context 'when gitaly is set to use a tls_listen_addr' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       socket_path: '', tls_listen_addr: 'localhost:8123'
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/tmp/user/git-data/repositories', 'gitaly_address' => 'tls://localhost:8123' })
    end
  end

  context 'when both tls and socket' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       socket_path: '/some/socket/path.socket', tls_listen_addr: 'localhost:8123'
                     })
    end

    it 'TlS should take precedence' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => { 'path' => '/tmp/user/git-data/repositories', 'gitaly_address' => 'tls://localhost:8123' })
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

  context 'when git_data_dirs is set with symbol keys rather than string keys' do
    before do
      with_symbol_keys = {
        default: { path: '/tmp/default/git-data' },
        overflow: { path: '/tmp/other/git-overflow-data' }
      }

      allow(Gitlab).to receive(:[]).with('git_data_dirs').and_return(with_symbol_keys)
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'path' => '/tmp/default/git-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'path' => '/tmp/other/git-overflow-data/repositories', 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
                                                                                      })
    end
  end
end
