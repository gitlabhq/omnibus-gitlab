require 'chef_helper'

RSpec.describe 'gitaly' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:config_path) { '/var/opt/gitlab/gitaly/config.toml' }
  let(:gitaly_config) { chef_run.template(config_path) }
  let(:runtime_dir) { '/var/opt/gitlab/gitaly/user_defined/run' }
  let(:socket_path) { '/tmp/gitaly.socket' }
  let(:listen_addr) { 'localhost:7777' }
  let(:tls_listen_addr) { 'localhost:8888' }
  let(:certificate_path) { '/path/to/cert.pem' }
  let(:key_path) { '/path/to/key.pem' }
  let(:gpg_signing_key_path) { '/path/to/signing_key.gpg' }
  let(:prometheus_listen_addr) { 'localhost:9000' }
  let(:logging_level) { 'warn' }
  let(:logging_format) { 'default' }
  let(:logging_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project' }
  let(:logging_ruby_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project-ruby' }
  let(:logging_sentry_environment) { 'production' }
  let(:prometheus_grpc_latency_buckets) do
    '[0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]'
  end
  let(:auth_token) { '123secret456' }
  let(:auth_transitioning) { true }
  let(:ruby_max_rss) { 1000000 }
  let(:graceful_restart_timeout) { '20m' }
  let(:ruby_graceful_restart_timeout) { '30m' }
  let(:ruby_restart_delay) { '10m' }
  let(:ruby_num_workers) { 5 }
  let(:git_catfile_cache_size) { 50 }
  let(:git_bin_path) { '/path/to/usr/bin/git' }
  let(:use_bundled_git) { true }
  let(:open_files_ulimit) { 10000 }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'TZ' => ':/etc/localtime',
      'HOME' => '/var/opt/gitlab',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.9/site-packages',
      'WRAPPER_JSON_LOGGING' => 'true',
      "GITALY_PID_FILE" => '/var/opt/gitlab/gitaly/gitaly.pid',
    }
  end

  let(:gitlab_url) { 'http://localhost:3000' }
  let(:workhorse_addr) { 'localhost:4000' }
  let(:gitaly_custom_hooks_dir) { '/path/to/gitaly/custom/hooks' }
  let(:user) { 'user123' }
  let(:password) { 'password321' }
  let(:ca_file) { '/path/to/ca_file' }
  let(:ca_path) { '/path/to/ca_path' }
  let(:read_timeout) { 123 }
  let(:daily_maintenance_start_hour) { 21 }
  let(:daily_maintenance_start_minute) { 9 }
  let(:daily_maintenance_duration) { '45m' }
  let(:daily_maintenance_storages) { ["default"] }
  let(:daily_maintenance_disabled) { false }
  let(:cgroups_mountpoint) { '/sys/fs/cgroup' }
  let(:cgroups_hierarchy_root) { 'gitaly' }
  let(:cgroups_memory_bytes) { 2097152 }
  let(:cgroups_cpu_shares) { 512 }
  let(:cgroups_repositories_count) { 10 }
  let(:cgroups_repositories_memory_bytes) { 1048576 }
  let(:cgroups_repositories_cpu_shares) { 128 }
  let(:pack_objects_cache_enabled) { true }
  let(:pack_objects_cache_dir) { '/pack-objects-cache' }
  let(:pack_objects_cache_max_age) { '10m' }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it_behaves_like "enabled runit service", "gitaly", "root", "root"

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly').with(user: 'git', mode: '0700')
      expect(chef_run).to create_directory('/var/log/gitlab/gitaly').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Gitaly').with(
        version_file_path: '/var/opt/gitlab/gitaly/VERSION',
        version_check_cmd: "/opt/gitlab/embedded/bin/ruby -rdigest/sha2 -e 'puts %(sha256:) + Digest::SHA256.file(%(/opt/gitlab/embedded/bin/gitaly)).hexdigest'"
      )

      expect(chef_run.version_file('Create version file for Gitaly')).to notify('runit_service[gitaly]').to(:hup)
    end

    it 'creates a default RUBY_VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create Ruby version file for Gitaly').with(
        version_file_path: '/var/opt/gitlab/gitaly/RUBY_VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/ruby --version'
      )

      expect(chef_run.version_file('Create Ruby version file for Gitaly')).to notify('runit_service[gitaly]').to(:hup)
    end

    it 'populates gitaly config.toml with defaults' do
      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(content).to include("socket_path = '/var/opt/gitlab/gitaly/gitaly.socket'")
        expect(content).to include("runtime_dir = '/var/opt/gitlab/gitaly/run'")
        expect(content).to include("bin_dir = '/opt/gitlab/embedded/bin'")
      }

      expect(chef_run).not_to render_file(config_path)
        .with_content("listen_addr = '#{listen_addr}'")
      expect(chef_run).not_to render_file(config_path)
        .with_content("tls_listen_addr =")
      expect(chef_run).not_to render_file(config_path)
       .with_content("certificate_path  =")
      expect(chef_run).not_to render_file(config_path)
       .with_content("key_path  =")
      expect(chef_run).not_to render_file(config_path)
       .with_content("signing_key =")
      expect(chef_run).not_to render_file(config_path)
        .with_content("prometheus_listen_addr = '#{prometheus_listen_addr}'")
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level = '#{logging_level}'\s+format = '#{logging_format}'\s+sentry_dsn = '#{logging_sentry_dsn}'})
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level = '#{logging_level}'\s+format = '#{logging_format}'\s+ruby_sentry_dsn = '#{logging_ruby_sentry_dsn}'})
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[logging\]\s+level = '#{logging_level}'\s+format = '#{logging_format}'\s+sentry_environment = '#{logging_sentry_environment}'})
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
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{catfile_cache_size})
      expect(chef_run).not_to render_file(config_path)
        .with_content('[pack_objects_cache]')
      expect(chef_run).not_to render_file(config_path)
        .with_content('rugged_git_config_search_path')
      expect(chef_run).not_to render_file(config_path)
        .with_content('[[git.config]]')
    end

    it 'populates gitaly config.toml with default git binary path' do
      expect(chef_run).to render_file(config_path)
        .with_content("bin_path = '/opt/gitlab/embedded/bin/git'")
    end

    it 'populates gitaly config.toml with default storages' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = 'default'\s+path = '/var/opt/gitlab/git-data/repositories'})
    end

    it 'renders the runit run script with defaults' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n 15000})
    end

    it 'does not append timestamp in logs if logging format is json' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/exec svlogd \/var\/log\/gitlab\/gitaly/)
    end

    it 'populates gitaly config.toml with gitlab-shell values' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[gitlab-shell\]\s+dir = "/opt/gitlab/embedded/service/gitlab-shell"})
    end

    it 'populates gitaly config.toml with gitlab-workhorse socket' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[gitlab\]\s+url = 'http\+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket'\s+relative_url_root = ''})
    end

    it 'deletes the old internal sockets directory' do
      expect(chef_run).to delete_directory("/var/opt/gitlab/gitaly/internal_sockets")
    end
  end

  context 'with pre 15.0 cgroups settings' do
    before do
      stub_gitlab_rb(
        gitaly: {
          cgroups_mountpoint: cgroups_mountpoint,
          cgroups_count: 100,
          cgroups_hierarchy_root: cgroups_hierarchy_root,
          cgroups_memory_limit: cgroups_memory_bytes,
          cgroups_memory_enabled: true,
          cgroups_cpu_shares: cgroups_cpu_shares,
          cgroups_cpu_enabled: true,
          pack_objects_cache_enabled: pack_objects_cache_enabled,
          pack_objects_cache_dir: pack_objects_cache_dir,
          pack_objects_cache_max_age: pack_objects_cache_max_age,
          custom_hooks_dir: gitaly_custom_hooks_dir
        }
      )
    end

    it 'populates gitaly cgroups with correct values' do
      cgroups_section = Regexp.new([
        %r{\[cgroups\]},
        %r{mountpoint = '#{cgroups_mountpoint}'},
        %r{hierarchy_root = '#{cgroups_hierarchy_root}'},
        %r{\[cgroups.repositories\]},
        %r{count = 100},
        %r{memory_bytes = #{cgroups_memory_bytes}},
        %r{cpu_shares = #{cgroups_cpu_shares}},
      ].map(&:to_s).join('\s+'))

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(content).to match(cgroups_section)
      }
    end
  end

  context 'with Omnibus gitconfig' do
    let(:omnibus_gitconfig) { nil }
    let(:gitaly_gitconfig) { nil }

    before do
      stub_gitlab_rb(
        omnibus_gitconfig: {
          system: omnibus_gitconfig,
        },
        gitaly: {
          gitconfig: gitaly_gitconfig,
        }
      )
    end

    context 'with default Omnibus gitconfig' do
      it 'does not write a git.config section' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).not_to include("git.config")
        }
      end
    end

    context 'with default values and weird spacing' do
      let(:omnibus_gitconfig) do
        {
          pack: ["threads =1 "],
          receive: ["  fsckObjects=true", "advertisePushOptions   =    true  "],
          repack: [" writeBitmaps= true "],
        }
      end

      it 'does not write a git.config section' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).not_to include("git.config")
        }
      end
    end

    context 'with changed default value' do
      let(:omnibus_gitconfig) do
        {
          receive: ["fsckObjects = false", "advertisePushOptions = true"],
        }
      end

      it 'writes only non-default git.config section' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "receive.fsckObjects"},
          %r{value = "false"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
          expect(content).not_to include("advertisePushOptions")
        }
      end
    end

    context 'with changed default value and weird spacing' do
      let(:omnibus_gitconfig) do
        {
          receive: ["fsckObjects    =      false", "advertisePushOptions=false"],
        }
      end

      it 'writes only non-default git.config section' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "receive.fsckObjects"},
          %r{value = "false"},
          %r{},
          %r{\[\[git.config\]\]},
          %r{key = "receive.advertisePushOptions"},
          %r{value = "false"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
        }
      end
    end

    context 'with mixed default and non-default values' do
      let(:omnibus_gitconfig) do
        {
          receive: ["fsckObjects = true"],
          nondefault: ["bar = baz"],
        }
      end

      it 'writes only non-default git.config section' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "nondefault.bar"},
          %r{value = "baz"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
          expect(content).not_to include("fsckObjects")
        }
      end
    end

    context 'with Omnibus gitconfig containing subsections' do
      let(:omnibus_gitconfig) do
        {
          'http "http://example.com"' => ['proxy = http://proxy.example.com'],
        }
      end

      it 'writes the correct key' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "http.http://example.com.proxy"},
          %r{value = "http://proxy.example.com"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
        }
      end
    end

    context 'with Gitaly gitconfig' do
      let(:gitaly_gitconfig) do
        [
          { key: "core.fsckObjects", value: "true" },
        ]
      end

      let(:omnibus_gitconfig) do
        {
          this: ["is = overridden"],
        }
      end

      it 'writes only non-default git.config section' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "core.fsckObjects"},
          %r{value = "true"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
          expect(content).not_to include("overridden")
        }
      end
    end

    context 'with invalid value' do
      let(:omnibus_gitconfig) do
        {
          receive: ["fsckObjects"]
        }
      end

      it 'raises an error' do
        expect { chef_run }.to raise_error(/Invalid entry detected in omnibus_gitconfig/)
      end
    end

    context 'with empty Gitaly gitconfig' do
      let(:gitaly_gitconfig) { [] }
      let(:omnibus_gitconfig) do
        {
          this: ["is = overridden"],
        }
      end

      it 'does not write a git.config section' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).not_to include("git.config")
        }
      end
    end

    context 'with sections' do
      let(:gitaly_gitconfig) do
        [
          { section: 'core', key: 'fsckObjects', value: 'true' },
          { section: 'core', key: 'somethingElse', value: 'true' },
          { section: 'another', key: 'section', value: 'true' },
        ]
      end

      it 'writes the correct keys' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "core.fsckObjects"},
          %r{value = "true"},
          %r{},
          %r{\[\[git.config\]\]},
          %r{key = "core.somethingElse"},
          %r{value = "true"},
          %r{},
          %r{\[\[git.config\]\]},
          %r{key = "another.section"},
          %r{value = "true"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
          expect(content).not_to include("overridden")
        }
      end
    end

    context 'with subsections' do
      let(:gitaly_gitconfig) do
        [
          { section: 'http', subsection: 'http://example.com', key: 'insteadOf', value: 'http://rewritten.example.com' },
          { key: 'http.http://another.example.com.insteadOf', value: 'http://rewritten.example.com' },
        ]
      end

      it 'writes the correct keys' do
        gitconfig_section = Regexp.new([
          %r{\[\[git.config\]\]},
          %r{key = "http.http://example.com.insteadOf"},
          %r{value = "http://rewritten.example.com"},
          %r{},
          %r{\[\[git.config\]\]},
          %r{key = "http.http://another.example.com.insteadOf"},
          %r{value = "http://rewritten.example.com"},
        ].map(&:to_s).join('\s+'))

        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to match(gitconfig_section)
          expect(content).not_to include("overridden")
        }
      end
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        gitaly: {
          socket_path: socket_path,
          runtime_dir: runtime_dir,
          listen_addr: listen_addr,
          tls_listen_addr: tls_listen_addr,
          certificate_path: certificate_path,
          key_path: key_path,
          gpg_signing_key_path: gpg_signing_key_path,
          prometheus_listen_addr: prometheus_listen_addr,
          logging_level: logging_level,
          logging_format: logging_format,
          logging_sentry_dsn: logging_sentry_dsn,
          logging_ruby_sentry_dsn: logging_ruby_sentry_dsn,
          logging_sentry_environment: logging_sentry_environment,
          prometheus_grpc_latency_buckets: prometheus_grpc_latency_buckets,
          auth_token: auth_token,
          auth_transitioning: auth_transitioning,
          graceful_restart_timeout: graceful_restart_timeout,
          ruby_max_rss: ruby_max_rss,
          ruby_graceful_restart_timeout: ruby_graceful_restart_timeout,
          ruby_restart_delay: ruby_restart_delay,
          ruby_num_workers: ruby_num_workers,
          git_catfile_cache_size: git_catfile_cache_size,
          git_bin_path: git_bin_path,
          use_bundled_git: true,
          open_files_ulimit: open_files_ulimit,
          daily_maintenance_start_hour: daily_maintenance_start_hour,
          daily_maintenance_start_minute: daily_maintenance_start_minute,
          daily_maintenance_duration: daily_maintenance_duration,
          daily_maintenance_storages: daily_maintenance_storages,
          daily_maintenance_disabled: daily_maintenance_disabled,
          cgroups_mountpoint: cgroups_mountpoint,
          cgroups_hierarchy_root: cgroups_hierarchy_root,
          cgroups_memory_bytes: cgroups_memory_bytes,
          cgroups_cpu_shares: cgroups_cpu_shares,
          cgroups_repositories_count: cgroups_repositories_count,
          cgroups_repositories_memory_bytes: cgroups_repositories_memory_bytes,
          cgroups_repositories_cpu_shares: cgroups_repositories_cpu_shares,
          pack_objects_cache_enabled: pack_objects_cache_enabled,
          pack_objects_cache_dir: pack_objects_cache_dir,
          pack_objects_cache_max_age: pack_objects_cache_max_age,
          custom_hooks_dir: gitaly_custom_hooks_dir
        },
        gitlab_rails: {
          internal_api_url: gitlab_url
        },
        gitlab_shell: {
          http_settings: {
            read_timeout: read_timeout,
            user: user,
            password: password,
            ca_file: ca_file,
            ca_path: ca_path
          }
        },
        gitlab_workhorse: {
          listen_network: 'tcp',
          listen_addr: workhorse_addr,
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like "enabled runit service", "gitaly", "root", "root"

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory(runtime_dir).with(user: 'foo', mode: '0700')
    end

    it 'populates gitaly config.toml with custom values' do
      expect(chef_run).to render_file(config_path)
        .with_content("socket_path = '#{socket_path}'")
      expect(chef_run).to render_file(config_path)
        .with_content("runtime_dir = '#{runtime_dir}'")
      expect(chef_run).to render_file(config_path)
        .with_content("bin_dir = '/opt/gitlab/embedded/bin'")
      expect(chef_run).to render_file(config_path)
        .with_content("listen_addr = 'localhost:7777'")
      expect(chef_run).to render_file(config_path)
        .with_content("graceful_restart_timeout = '#{graceful_restart_timeout}'")
      expect(chef_run).to render_file(config_path)
        .with_content("bin_path = '#{git_bin_path}'")
      expect(chef_run).to render_file(config_path)
        .with_content("use_bundled_binaries = true")

      gitaly_logging_section = Regexp.new([
        %r{\[logging\]},
        %r{level = '#{logging_level}'},
        %r{format = '#{logging_format}'},
        %r{sentry_dsn = '#{logging_sentry_dsn}'},
        %r{ruby_sentry_dsn = '#{logging_ruby_sentry_dsn}'},
        %r{sentry_environment = '#{logging_sentry_environment}'},
      ].map(&:to_s).join('\s+'))

      gitaly_ruby_section = Regexp.new([
        %r{\[gitaly-ruby\]},
        %r{dir = "/opt/gitlab/embedded/service/gitaly-ruby"},
        %r{max_rss = #{ruby_max_rss}},
        %r{graceful_restart_timeout = '#{Regexp.escape(ruby_graceful_restart_timeout)}'},
        %r{restart_delay = '#{Regexp.escape(ruby_restart_delay)}'},
        %r{num_workers = #{ruby_num_workers}},
      ].map(&:to_s).join('\s+'))

      gitlab_shell_section = Regexp.new([
        %r{\[gitlab-shell\]},
        %r{dir = "/opt/gitlab/embedded/service/gitlab-shell"},
      ].map(&:to_s).join('\s+'))

      gitlab_section = Regexp.new([
        %r{\[gitlab\]},
        %r{url = '#{Regexp.escape(gitlab_url)}'},
        %r{\[gitlab.http-settings\]},
        %r{read_timeout = #{read_timeout}},
        %r{user = '#{Regexp.escape(user)}'},
        %r{password = '#{Regexp.escape(password)}'},
        %r{ca_file = '#{Regexp.escape(ca_file)}'},
        %r{ca_path = '#{Regexp.escape(ca_path)}'},
      ].map(&:to_s).join('\s+'))

      hooks_section = Regexp.new([
        %r{\[hooks\]},
        %r{custom_hooks_dir = '#{Regexp.escape(gitaly_custom_hooks_dir)}'},
      ].map(&:to_s).join('\s+'))

      maintenance_section = Regexp.new([
        %r{\[daily_maintenance\]},
        %r{start_hour = #{daily_maintenance_start_hour}},
        %r{start_minute = #{daily_maintenance_start_minute}},
        %r{duration = '#{daily_maintenance_duration}'},
        %r{storages = #{Regexp.escape(daily_maintenance_storages.to_s)}},
      ].map(&:to_s).join('\s+'))

      cgroups_section = Regexp.new([
        %r{\[cgroups\]},
        %r{mountpoint = '#{cgroups_mountpoint}'},
        %r{hierarchy_root = '#{cgroups_hierarchy_root}'},
        %r{memory_bytes = #{cgroups_memory_bytes}},
        %r{cpu_shares = #{cgroups_cpu_shares}},
        %r{\[cgroups.repositories\]},
        %r{count = #{cgroups_repositories_count}},
        %r{memory_bytes = #{cgroups_repositories_memory_bytes}},
        %r{cpu_shares = #{cgroups_repositories_cpu_shares}},
      ].map(&:to_s).join('\s+'))

      pack_objects_cache_section = Regexp.new([
        %r{\[pack_objects_cache\]\nenabled = true},
        %r{dir = '#{pack_objects_cache_dir}'},
        %r{max_age = '#{pack_objects_cache_max_age}'},
      ].map(&:to_s).join('\s+'))

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(content).to include("tls_listen_addr = 'localhost:8888'")
        expect(content).to include("certificate_path = '/path/to/cert.pem'")
        expect(content).to include("key_path = '/path/to/key.pem'")
        expect(content).to include("signing_key = '/path/to/signing_key.gpg'")
        expect(content).to include("prometheus_listen_addr = 'localhost:9000'")
        expect(content).to match(gitaly_logging_section)
        expect(content).to match(%r{\[prometheus\]\s+grpc_latency_buckets = #{Regexp.escape(prometheus_grpc_latency_buckets)}})
        expect(content).to match(%r{\[auth\]\s+token = '#{Regexp.escape(auth_token)}'\s+transitioning = true})
        expect(content).to match(gitaly_ruby_section)
        expect(content).to match(%r{\[git\]\s+catfile_cache_size = 50})
        expect(content).to match(gitlab_shell_section)
        expect(content).to match(gitlab_section)
        expect(content).to match(hooks_section)
        expect(content).to match(maintenance_section)
        expect(content).to match(cgroups_section)
        expect(content).to match(pack_objects_cache_section)
      }
    end

    it 'renders the runit run script with custom values' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n #{open_files_ulimit}})
    end

    it 'renders the runit run script with cgroup root creation' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run').with_content { |content|
        expect(content).to match(%r{mkdir -m 0700 -p #{cgroups_mountpoint}/memory/#{cgroups_hierarchy_root}})
        expect(content).to match(%r{mkdir -m 0700 -p #{cgroups_mountpoint}/cpu/#{cgroups_hierarchy_root}})
        expect(content).to match(%r{chown foo:bar #{cgroups_mountpoint}/memory/#{cgroups_hierarchy_root}})
        expect(content).to match(%r{chown foo:bar #{cgroups_mountpoint}/cpu/#{cgroups_hierarchy_root}})
      }
    end

    it 'populates sv related log files' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/gitaly/)
    end

    context 'when using multiple maintenance storage entries' do
      let(:daily_maintenance_storages) { %w(storage0 storage1 storage2) }

      it 'renders daily_maintenance with multiple storage entries' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to include("storages = #{daily_maintenance_storages}")
        }
      end
    end

    context 'when maintenance is disabled' do
      let(:daily_maintenance_disabled) { true }

      it 'renders daily_maintenance with disabled set to true' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).to include("[daily_maintenance]\ndisabled = true\n\n")
        }
      end
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
      context 'using local gitaly' do
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

      context 'using external gitaly' do
        before do
          stub_gitlab_rb(
            {
              git_data_dirs:
              {
                'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
              }
            }
          )
        end

        it 'populates gitaly config.toml with custom storages' do
          expect(chef_run).to render_file(config_path)
            .with_content(%r{\[\[storage\]\]\s+name = 'default'\s+path = '/var/opt/gitlab/git-data/repositories'})
          expect(chef_run).not_to render_file(config_path)
            .with_content('gitaly_address: "tcp://gitaly.internal:8075"')
        end
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

  context 'when using rate limiting configuration' do
    before do
      stub_gitlab_rb(
        {
          gitaly: {
            rate_limiting: [
              {
                'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                'interval' => '1s',
                'burst' => 100
              }, {
                'rpc' => "/gitaly.SSHService/SSHUploadPack",
                'interval' => '1s',
                'burst' => 200,
              }
            ]
          }
        }
      )
    end

    it 'populates gitaly config.toml with custom concurrency configurations' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[rate_limiting\]\]\s+rpc = "/gitaly.SmartHTTPService/PostReceivePack"\s+interval = "1s"\s+burst = 100})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[rate_limiting\]\]\s+rpc = "/gitaly.SSHService/SSHUploadPack"\s+interval = "1s"\s+burst = 200})
    end
  end

  shared_examples 'empty concurrency configuration' do
    it 'does not generate a gitaly concurrency configuration' do
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[\[concurrency\]\]})
    end
  end

  shared_examples 'empty rate limiting configuration' do
    it 'does not generate a gitaly concurrency configuration' do
      expect(chef_run).not_to render_file(config_path)
        .with_content(%r{\[\[rate_limiting\]\]})
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
      it_behaves_like 'empty rate limiting configuration'
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

    context 'when rate limiting configuration is empty' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
              rate_limiting: []
            }
          }
        )
      end

      it_behaves_like 'empty rate limiting configuration'
    end

    context 'when rate limiting configuration is incomplete' do
      context 'missing interval' do
        before do
          stub_gitlab_rb(
            {
              gitaly: {
                rate_limiting: [{
                  'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                  'burst' => 100
                }]
              }
            }
          )
        end

        it_behaves_like 'empty rate limiting configuration'
      end

      context 'missing burst' do
        before do
          stub_gitlab_rb(
            {
              gitaly: {
                rate_limiting: [{
                  'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                  'interval' => '1s',
                }]
              }
            }
          )
        end

        it_behaves_like 'empty rate limiting configuration'
      end
    end

    context 'when max_queue_size and max_queue_wait are empty' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
              concurrency: [
                {
                  'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                  'max_per_repo' => 20,
                }, {
                  'rpc' => "/gitaly.SSHService/SSHUploadPack",
                  'max_per_repo' => 5,
                }
              ]
            }
          }
        )
      end

      it 'populates gitaly config.toml without max_queue_size and max_queue_wait' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).not_to include("max_queue_size")
          expect(content).not_to include("max_queue_wait")
        }
      end
    end

    context 'when max_per_repo is empty' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
              concurrency: [
                {
                  'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                  'max_queue_size' => '10s'
                }, {
                  'rpc' => "/gitaly.SSHService/SSHUploadPack",
                  'max_queue_size' => '10s'
                }
              ]
            }
          }
        )
      end

      it 'populates gitaly config.toml without max_per_repo' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(content).not_to include("max_per_repo")
        }
      end
    end

    context 'when max_queue_wait is set' do
      before do
        stub_gitlab_rb(
          {
            gitaly: {
              concurrency: [
                {
                  'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                  'max_queue_wait' => "10s",
                }
              ]
            }
          }
        )
      end

      it 'populates gitaly config.toml with quoted max_queue_wait' do
        expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[concurrency\]\]\s+rpc = "/gitaly.SmartHTTPService/PostReceivePack"\s+max_queue_wait = "10s"})
      end
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

  context 'with a non-default workhorse unix socket' do
    context 'with only a listen address set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { listen_addr: '/fake/workhorse/socket' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[gitlab\]\s+url = 'http\+unix://%2Ffake%2Fworkhorse%2Fsocket'\s+relative_url_root = ''})
      end
    end

    context 'with only a socket directory set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { sockets_directory: '/fake/workhorse/sockets' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[gitlab\]\s+url = 'http\+unix://%2Ffake%2Fworkhorse%2Fsockets%2Fsocket'\s+relative_url_root = ''})
      end
    end

    context 'with a listen_address and a sockets_directory set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { listen_addr: '/sockets/in/the/wind', sockets_directory: '/sockets/in/the' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[gitlab\]\s+url = 'http\+unix://%2Fsockets%2Fin%2Fthe%2Fwind'\s+relative_url_root = ''})
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

    it 'create config file with only the URL set' do
      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(content).to match(%r{\[gitlab\]\s+url = 'http://localhost:1234/gitlab'})
        expect(content).not_to match(/relative_url_root/)
      }
    end
  end

  context 'with relative path in external_url' do
    before do
      stub_gitlab_rb(external_url: 'http://example.com/gitlab')
    end

    it 'create config file with the relative_url_root set' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[gitlab\]\s+url = 'http\+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket'\s+relative_url_root = '/gitlab'})
    end
  end

  context 'with cgroups mountpoint and hierarchy_root' do
    before do
      stub_gitlab_rb(
        gitaly: {
          cgroups_mountpoint: '/sys/fs/cgroup',
          cgroups_hierarchy_root: 'gitaly'
        }
      )
    end
  end

  include_examples "consul service discovery", "gitaly", "gitaly"
end

RSpec.describe 'gitaly::git_data_dirs' do
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

  context 'when path not defined in git_data_dirs' do
    before do
      stub_gitlab_rb(
        {
          git_data_dirs:
          {
            'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
          }
        }
      )
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({ 'default' => { 'path' => '/var/opt/gitlab/git-data/repositories', 'gitaly_address' => 'tcp://gitaly.internal:8075' } })
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
