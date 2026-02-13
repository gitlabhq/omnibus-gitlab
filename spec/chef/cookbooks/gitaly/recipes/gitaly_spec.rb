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
  let(:logging_sentry_environment) { 'production' }
  let(:prometheus_grpc_latency_buckets) do
    [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]
  end
  let(:auth_token) { '123#$secret456' }
  let(:auth_transitioning) { true }
  let(:graceful_restart_timeout) { '20m' }
  let(:git_catfile_cache_size) { 50 }
  let(:open_files_ulimit) { 10000 }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'TZ' => ':/etc/localtime',
      'HOME' => '/var/opt/gitlab',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.12/site-packages',
      'WRAPPER_JSON_LOGGING' => 'true',
      "GITALY_PID_FILE" => '/var/opt/gitlab/gitaly/gitaly.pid',
      'GODEBUG' => "tlsmlkem=0",
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
  let(:cgroups_cpu_quota_us) { 400000 }
  let(:cgroups_repositories_count) { 10 }
  let(:cgroups_repositories_memory_bytes) { 1048576 }
  let(:cgroups_repositories_cpu_shares) { 128 }
  let(:cgroups_repositories_cpu_quota_us) { 200000 }
  let(:cgroups_repositories_max_cgroups_per_repo) { 2 }
  let(:pack_objects_cache_enabled) { true }
  let(:pack_objects_cache_dir) { '/pack-objects-cache' }
  let(:pack_objects_cache_max_age) { '10m' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(SecretsHelper).to receive(:generate_hex).and_return('4ecd22c031fee5c7368a5a102f76dc41')
  end

  context 'by default' do
    it_behaves_like "enabled runit service", "gitaly", "root", "root"

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Gitaly').with(
        version_file_path: '/var/opt/gitlab/gitaly/VERSION',
        version_check_cmd: "/opt/gitlab/embedded/bin/ruby -rdigest/sha2 -e 'puts %(sha256:) + Digest::SHA256.file(%(/opt/gitlab/embedded/bin/gitaly)).hexdigest'"
      )

      expect(chef_run.version_file('Create version file for Gitaly')).to notify('runit_service[gitaly]').to(:hup)
    end

    it 'creates secret file for authenticating with GitLab' do
      expect(chef_run).to create_file('/var/opt/gitlab/gitaly/.gitlab_secret').with_content('4ecd22c031fee5c7368a5a102f76dc41')
    end

    it 'populates gitaly config.toml with defaults' do
      expect(get_rendered_toml(chef_run, '/var/opt/gitlab/gitaly/config.toml')).to eq(
        {
          auth: {},
          bin_dir: '/opt/gitlab/embedded/bin',
          git: {
            ignore_gitconfig: true,
          },
          gitlab: {
            relative_url_root: '',
            url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
            secret_file: '/var/opt/gitlab/gitaly/.gitlab_secret'
          },
          'gitlab-shell': {
            dir: '/opt/gitlab/embedded/service/gitlab-shell'
          },
          logging: {
            dir: '/var/log/gitlab/gitaly',
            format: 'json'
          },
          prometheus_listen_addr: 'localhost:9236',
          runtime_dir: '/var/opt/gitlab/gitaly/run',
          socket_path: '/var/opt/gitlab/gitaly/gitaly.socket',
          storage: [
            {
              name: 'default',
              path: '/var/opt/gitlab/git-data/repositories'
            }
          ]
        }
      )
    end

    it 'renders the runit run script with defaults' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n 15000})
    end

    it 'does not append timestamp in logs if logging format is json' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/svlogd \/var\/log\/gitlab\/gitaly/)
    end

    it 'deletes the old internal sockets directory' do
      expect(chef_run).to delete_directory("/var/opt/gitlab/gitaly/internal_sockets")
    end
  end

  context 'with a user specified GitLab secret' do
    context 'when the Gitlab Shell and Gitaly secrets match' do
      before do
        stub_gitlab_rb(
          gitaly: {
            gitlab_secret: 'my-super-secret-password'
          },
          gitlab_shell: {
            secret_token: 'my-super-secret-password'
          }
        )
      end

      it 'populates the secret file with specified value' do
        expect(chef_run).to create_file('/var/opt/gitlab/gitaly/.gitlab_secret').with_content('my-super-secret-password')
      end

      it 'does not log a warning' do
        expect(LoggingHelper).not_to receive(:warning).with("Gitaly and GitLab Shell specifies different secrets to authenticate with GitLab")

        chef_run
      end
    end

    context 'when the Gitlab Shell and Gitaly secrets differ' do
      before do
        stub_gitlab_rb(
          gitaly: {
            gitlab_secret: 'password-for-gitaly'
          },
          gitlab_shell: {
            secret_token: 'password-for-shell'
          }
        )

        allow(LoggingHelper).to receive(:warning).and_call_original
      end

      it 'populates the secret file with specified value' do
        expect(chef_run).to create_file('/var/opt/gitlab/gitaly/.gitlab_secret').with_content('password-for-gitaly')
      end

      it 'logs a secret mismatch warning' do
        expect(LoggingHelper).to receive(:warning).with("Gitaly and GitLab Shell specifies different secrets to authenticate with GitLab")

        chef_run
      end
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      it_behaves_like 'enabled logged service', 'gitaly', true, { log_directory_owner: 'git' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          gitaly: {
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'configured logrotate service', 'gitaly', 'git', 'fugee'
      it_behaves_like 'enabled logged service', 'gitaly', true, { log_directory_owner: 'git', log_group: 'fugee' }
    end

    it_behaves_like 'a service with proper supervise directories', 'gitaly'
  end

  context 'sets cgroups settings' do
    before do
      stub_gitlab_rb(
        gitaly: {
          configuration: {
            cgroups: {
              mountpoint: cgroups_mountpoint,
              hierarchy_root: cgroups_hierarchy_root,
              memory_bytes: cgroups_memory_bytes,
              cpu_shares: cgroups_cpu_shares,
              cpu_quota_us: cgroups_cpu_quota_us,
              repositories: {
                count: cgroups_repositories_count,
                memory_bytes: cgroups_repositories_memory_bytes,
                cpu_shares: cgroups_repositories_cpu_shares,
                cpu_quota_us: cgroups_repositories_cpu_quota_us,
                max_cgroups_per_repo: cgroups_repositories_max_cgroups_per_repo,
              }
            },
          },
        }
      )
    end

    it 'populate gitaly cgroups' do
      cgroups_section = Regexp.new([
        %r{\[cgroups\]},
        %r{mountpoint = "#{cgroups_mountpoint}"},
        %r{hierarchy_root = "#{cgroups_hierarchy_root}"},
        %r{memory_bytes = #{cgroups_memory_bytes}},
        %r{cpu_shares = #{cgroups_cpu_shares}},
        %r{cpu_quota_us = #{cgroups_cpu_quota_us}},
        %r{\[cgroups.repositories\]},
        %r{count = #{cgroups_repositories_count}},
        %r{memory_bytes = #{cgroups_repositories_memory_bytes}},
        %r{cpu_shares = #{cgroups_repositories_cpu_shares}},
        %r{cpu_quota_us = #{cgroups_repositories_cpu_quota_us}},
        %r{max_cgroups_per_repo = #{cgroups_repositories_max_cgroups_per_repo}},
      ].map(&:to_s).join('\s+'))

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(content).to match(cgroups_section)
      }
    end
  end

  context 'with some defaults overridden with custom configuration' do
    before do
      stub_gitlab_rb(
        gitaly: {
          enable: true,
          configuration: {
            socket_path: 'overridden_socket_path',
            logging: {
              dir: 'overridden_logging_path'
            },
            custom_section: {
              custom_key: 'custom_value'
            },
            storage: [
              {
                name: 'custom_storage',
                path: 'custom_path'
              },
            ],
            cgroups: {
              mountpoint: '/mycgroups',
              hierarchy_root: 'myroot',
              cpu_shares: 100,
              repositories: {
                count: 10
              }
            },
          }
        }
      )
    end

    it 'renders config.toml with' do
      expect(get_rendered_toml(chef_run, '/var/opt/gitlab/gitaly/config.toml')).to eq(
        {
          'auth': {},
          'gitlab-shell': {
            dir: '/opt/gitlab/embedded/service/gitlab-shell'
          },
          bin_dir: '/opt/gitlab/embedded/bin',
          custom_section: { custom_key: 'custom_value' },
          git: {
            ignore_gitconfig: true,
          },
          gitlab: {
            url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
            relative_url_root: '',
            secret_file: '/var/opt/gitlab/gitaly/.gitlab_secret'
          },
          logging: {
            dir: 'overridden_logging_path',
            format: 'json',
          },
          prometheus_listen_addr: 'localhost:9236',
          runtime_dir: '/var/opt/gitlab/gitaly/run',
          socket_path: 'overridden_socket_path',
          storage: [
            {
              name: 'custom_storage',
              path: 'custom_path',
            }
          ],
          cgroups: {
            mountpoint: '/mycgroups',
            hierarchy_root: 'myroot',
            cpu_shares: 100,
            repositories: {
              count: 10
            }
          }
        }
      )
    end
  end

  context 'with default settings' do
    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
        .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/var/opt/gitlab/git-data/repositories"})
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        gitaly: {
          open_files_ulimit: open_files_ulimit,
          # Sanity check that configuration values get printed out.
          configuration: {
            socket_path: socket_path,
            listen_addr: listen_addr,
            tls_listen_addr: tls_listen_addr,
            string_value: 'some value',
            runtime_dir: runtime_dir,
            git: {
              signing_key: gpg_signing_key_path,
              catfile_cache_size: git_catfile_cache_size,
            },
            prometheus: {
              grpc_latency_buckets: prometheus_grpc_latency_buckets
            },
            prometheus_listen_addr: prometheus_listen_addr,
            graceful_restart_timeout: graceful_restart_timeout,
            auth: {
              token: auth_token,
              transitioning: auth_transitioning,
            },
            tls: {
              certificate_path: certificate_path,
              key_path: key_path,
            },
            storage: [
              { name: 'default', path: '/tmp/path-1' },
              { name: 'nfs1', path: '/mnt/nfs1' }
            ],
            logging: {
              level: logging_level,
              format: logging_format,
              sentry_dsn: logging_sentry_dsn,
              sentry_environment: logging_sentry_environment,
            },
            hooks: { custom_hooks_dir: gitaly_custom_hooks_dir },
            pack_objects_cache: {
              enabled: pack_objects_cache_enabled,
              dir: pack_objects_cache_dir,
              max_age: pack_objects_cache_max_age,
            },
            cgroups: {
              mountpoint: cgroups_mountpoint,
              hierarchy_root: cgroups_hierarchy_root,
              memory_bytes: cgroups_memory_bytes,
              cpu_shares: cgroups_cpu_shares,
              repositories: {
                count: cgroups_repositories_count,
                memory_bytes: cgroups_repositories_memory_bytes,
                cpu_shares: cgroups_repositories_cpu_shares,
              },
            },
            daily_maintenance: {
              disabled: daily_maintenance_disabled,
              start_hour: daily_maintenance_start_hour,
              start_minute: daily_maintenance_start_minute,
              duration: daily_maintenance_duration,
              storages: %w(storage0 storage1),
            },
            concurrency: [
              {
                rpc: '/gitaly.SmartHTTPService/PostReceivePack',
                max_per_repo: 20
              },
              {
                rpc: '/gitaly.SSHService/SSHUploadPack',
                max_per_repo: 5
              }
            ],
            rate_limiting: [
              {
                rpc: '/gitaly.SmartHTTPService/PostReceivePack',
                interval: '1s',
                burst: 100
              }, {
                rpc: '/gitaly.SSHService/SSHUploadPack',
                interval: '1s',
                burst: 200,
              }
            ],
            subsection: {
              array_value: [1, 2, 3]
            }
          }
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
      expect(get_rendered_toml(chef_run, '/var/opt/gitlab/gitaly/config.toml')).to eq(
        {
          auth: {
            token: '123#$secret456',
            transitioning: true
          },
          bin_dir: '/opt/gitlab/embedded/bin',
          cgroups: {
            cpu_shares: 512,
            hierarchy_root: 'gitaly',
            memory_bytes: 2097152,
            mountpoint: '/sys/fs/cgroup',
            repositories: {
              count: 10,
              cpu_shares: 128,
              memory_bytes: 1048576
            }
          },
          concurrency: [
            {
              max_per_repo: 20,
              rpc: '/gitaly.SmartHTTPService/PostReceivePack'
            },
            {
              max_per_repo: 5,
              rpc: '/gitaly.SSHService/SSHUploadPack'
            }
          ],
          daily_maintenance: {
            disabled: false,
            duration: '45m',
            start_hour: 21,
            start_minute: 9,
            storages: %w(storage0 storage1)
          },
          git: {
            catfile_cache_size: 50,
            ignore_gitconfig: true,
            signing_key: '/path/to/signing_key.gpg',
          },
          gitlab: {
            'http-settings': {
              ca_file: '/path/to/ca_file',
              ca_path: '/path/to/ca_path',
              password: 'password321',
              read_timeout: 123,
              user: 'user123'
            },
            url: 'http://localhost:3000',
            secret_file: '/var/opt/gitlab/gitaly/.gitlab_secret'
          },
          'gitlab-shell': {
            dir: '/opt/gitlab/embedded/service/gitlab-shell'
          },
          graceful_restart_timeout: '20m',
          hooks: {
            custom_hooks_dir: '/path/to/gitaly/custom/hooks'
          },
          listen_addr: 'localhost:7777',
          logging: {
            dir: '/var/log/gitlab/gitaly',
            format: 'default',
            level: 'warn',
            sentry_dsn: 'https://my_key:my_secret@sentry.io/test_project',
            sentry_environment: 'production'
          },
          pack_objects_cache: {
            enabled: true,
            dir: '/pack-objects-cache',
            max_age: '10m'
          },
          prometheus: {
            grpc_latency_buckets: [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]
          },
          prometheus_listen_addr: 'localhost:9000',
          rate_limiting: [
            {
              burst: 100,
              interval: '1s',
              rpc: '/gitaly.SmartHTTPService/PostReceivePack'
            },
            {
              burst: 200,
              interval: '1s',
              rpc: '/gitaly.SSHService/SSHUploadPack'
            }
          ],
          runtime_dir: '/var/opt/gitlab/gitaly/user_defined/run',
          socket_path: '/tmp/gitaly.socket',
          storage: [
            {
              name: 'default',
              path: '/tmp/path-1'
            },
            {
              name: 'nfs1',
              path: '/mnt/nfs1'
            }
          ],
          string_value: 'some value',
          subsection: { array_value: [1, 2, 3] },
          tls: {
            certificate_path: '/path/to/cert.pem',
            key_path: '/path/to/key.pem'
          },
          tls_listen_addr: 'localhost:8888',
        }
      )
    end

    it 'renders the runit run script with custom values' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n #{open_files_ulimit}})
    end

    context 'with cgroups v2' do
      before do
        allow(Gitaly).to receive(:cgroups_v2?).and_return true
      end

      it 'renders the runit run script with cgroup root creation' do
        expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run').with_content { |content|
          expect(content).to match(%r{mkdir -m 0700 -p #{cgroups_mountpoint}})
          expect(content).to match(%r{chown -R foo:bar #{cgroups_mountpoint}})
        }
      end
    end

    context 'with cgroups v1' do
      before do
        allow(Gitaly).to receive(:cgroups_v2?).and_return false
      end

      it 'renders the runit run script with cgroup root creation' do
        expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run').with_content { |content|
          expect(content).to match(%r{mkdir -m 0700 -p #{cgroups_mountpoint}/memory/#{cgroups_hierarchy_root}})
          expect(content).to match(%r{mkdir -m 0700 -p #{cgroups_mountpoint}/cpu/#{cgroups_hierarchy_root}})
          expect(content).to match(%r{chown foo:bar #{cgroups_mountpoint}/memory/#{cgroups_hierarchy_root}})
          expect(content).to match(%r{chown foo:bar #{cgroups_mountpoint}/cpu/#{cgroups_hierarchy_root}})
        }
      end
    end

    it 'populates sv related log files' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/svlogd -tt \/var\/log\/gitlab\/gitaly/)
    end

    context 'when use_wrapper is defined' do
      context 'with wrapper enabled' do
        before do
          stub_gitlab_rb(gitaly: { use_wrapper: true })
        end

        it 'renders the runit run script with the wrapper' do
          expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
            .with_content(/\/opt\/gitlab\/embedded\/bin\/gitaly-wrapper/)
        end
      end

      context 'with wrapper disabled' do
        before do
          stub_gitlab_rb(gitaly: { use_wrapper: false })
        end

        it 'renders the runit run script without the wrapper' do
          expect(chef_run).not_to render_file('/opt/gitlab/sv/gitaly/run')
            .with_content(/\/opt\/gitlab\/embedded\/bin\/gitaly-wrapper/)
        end
      end
    end

    context 'when storages are left to defaults' do
      before do
        stub_gitlab_rb(
          gitaly: {
            configuration: {
              storage: nil
            }
          },
          gitlab_rails: {
            repositories_storages: nil
          }
        )
      end

      it 'correctly sets the repository storage directories' do
        expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
          .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
      end

      it 'correctly populates gitaly config.toml' do
        expect(chef_run).to render_file(config_path)
                              .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/var/opt/gitlab/git-data/repositories"})
      end
    end

    context 'when storages are correctly configured' do
      context 'using local gitaly' do
        context 'with git_data_dirs' do
          before do
            stub_gitlab_rb(
              gitaly: {
                configuration: {
                  storage: nil
                }
              },
              git_data_dirs:
                {
                  'default' => { 'path' => '/tmp/default/git-data' },
                  'nfs1' => { 'path' => '/mnt/nfs1' }
                }
            )
          end

          it 'correctly sets the repository storage directories' do
            expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
              .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                      'nfs1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
          end

          it 'correctly populates gitaly config.toml' do
            expect(chef_run).to render_file(config_path)
                                  .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
            expect(chef_run).to render_file(config_path)
                                  .with_content(%r{\[\[storage\]\]\s+name = "nfs1"\s+path = "/mnt/nfs1/repositories"})
          end
        end

        context "with gitaly['configuration']['storage']" do
          before do
            stub_gitlab_rb(
              gitaly: {
                configuration: {
                  storage: [
                    {
                      'name' => 'nfs1',
                      'path' => '/mnt/nfs1/repositories'
                    },
                    {
                      'name' => 'default',
                      'path' => '/tmp/default/git-data/repositories'
                    }
                  ]
                }
              }
            )
          end

          it 'correctly sets the repository storage directories' do
            expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
              .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                      'nfs1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
          end

          it 'correctly populates gitaly config.toml' do
            expect(chef_run).to render_file(config_path)
                                  .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
            expect(chef_run).to render_file(config_path)
                                  .with_content(%r{\[\[storage\]\]\s+name = "nfs1"\s+path = "/mnt/nfs1/repositories"})
          end
        end
      end

      context 'using external gitaly' do
        context 'with git_data_dirs' do
          before do
            stub_gitlab_rb(
              gitaly: {
                configuration: {
                  storage: nil
                }
              },
              git_data_dirs:
                {
                  'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
                }
            )
          end

          it 'correctly sets the repository storage directories' do
            expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
              .to eql('default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' })
          end
        end

        context 'with repositories_storages' do
          before do
            stub_gitlab_rb(
              gitaly: {
                configuration: {
                  storage: nil
                }
              },
              gitlab_rails: {
                repositories_storages: {
                  'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075', 'gitaly_token' => 'secret' },
                }
              }
            )
          end

          it 'correctly sets the repository storage directories' do
            expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
              .to eql('default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075', 'gitaly_token' => 'secret' })
          end
        end
      end

      # https://gitlab.com/gitlab-org/gitlab-qa/-/blob/50425989c764e135ca92a6276583581e2cffd35e/lib/gitlab/qa/scenario/test/instance/repository_storage.rb#L44
      context 'using a default storage on an external gitaly' do
        before do
          stub_gitlab_rb(
            gitaly: {
              configuration: {
                storage: [
                  {
                    name: 'gitaly',
                    path: '/var/opt/gitlab/git-data/gitaly/repositories',
                  },
                  {
                    name: 'secondary',
                    path: '/var/opt/gitlab/git-data/secondary/repositories',
                  },
                ]
              }
            },
            git_data_dirs:
              {
                'default' => {
                  'gitaly_address' => 'tcp://praefect.test:2305',
                  'gitaly_token' => 'PRAEFECT_EXTERNAL_TOKEN'
                },
                'gitaly' => {
                  'gitaly_address' => 'tcp://gitlab.test:8075',
                  'path' => '/var/opt/gitlab/git-data/gitaly'
                },
                'secondary' => {
                  'gitaly_address' => 'tcp://gitlab.test:8075',
                  'path' => '/var/opt/gitlab/git-data/secondary'
                }
              }
          )
        end

        it 'correctly sets the repository storage directories' do
          expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
            .to eql('default' => { 'gitaly_address' => 'tcp://praefect.test:2305', 'gitaly_token' => 'PRAEFECT_EXTERNAL_TOKEN' },
                    'gitaly' => { 'gitaly_address' => 'tcp://gitlab.test:8075' },
                    'secondary' => { 'gitaly_address' => 'tcp://gitlab.test:8075' }
                   )
        end

        it 'correctly excludes external Gitaly from the storages list' do
          expect(chef_run.node['gitaly']['configuration']['storage'])
            .to eql([{
                      'name' => 'gitaly',
                      'path' => '/var/opt/gitlab/git-data/gitaly/repositories'
                    },
                     {
                       'name' => 'secondary',
                       'path' => '/var/opt/gitlab/git-data/secondary/repositories'
                     }])
        end

        it 'correctly populates gitaly config.toml' do
          expect(chef_run).to render_file(config_path)
                                .with_content(%r{\[\[storage\]\]\s+name = "gitaly"\s+path = "/var/opt/gitlab/git-data/gitaly/repositories"})
          expect(chef_run).to render_file(config_path)
                                .with_content(%r{\[\[storage\]\]\s+name = "secondary"\s+path = "/var/opt/gitlab/git-data/secondary/repositories"})
        end
      end
    end

    context 'when different storages on separate nodes have the same path' do
      before do
        stub_gitlab_rb(
          gitaly: {
            configuration: {
              storage: [
                {
                  "name" => "nondefault",
                  "path" => "/var/opt/gitlab/git-data/repositories"
                }
              ]
            }
          },
          git_data_dirs:
            {
              "default" => { "path" => "/var/opt/gitlab/git-data", "gitaly_address" => "tcp://gitaly.internal:9999" },
            }
        )
      end

      it 'correctly sets the repository storage directories' do
        expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
          .to eql('default' => { 'gitaly_address' => 'tcp://gitaly.internal:9999' },
                  'nondefault' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
      end

      it 'correctly populates gitaly config.toml' do
        expect(chef_run).to render_file(config_path)
                              .with_content(%r{\[\[storage\]\]\s+name = "nondefault"\s+path = "/var/opt/gitlab/git-data/repositories"})
      end
    end

    context 'when the storages are incorrectly configured' do
      context 'with multiple storages using the same path' do
        let(:real_path) { Dir.mktmpdir }
        let(:other_dir) { Dir.mktmpdir }
        let(:symlink_path) { File.join(other_dir, 'symlink') }

        context 'when Gitaly is not enabled' do
          before do
            File.symlink(real_path, symlink_path)
            stub_gitlab_rb(
              gitaly: {
                enable: false,
                configuration: {
                  storage: [
                    {
                      'name' => 'default',
                      'path' => '/var/opt/gitlab/git-data/repositories'
                    },
                    {
                      'name' => 'other',
                      'path' => '/var/opt/gitlab/git-data/repositories'
                    },
                    {
                      'name' => 'realpath',
                      'path' => real_path
                    },
                    {
                      'name' => 'symlinked',
                      'path' => symlink_path,
                    }
                  ]
                }
              }
            )
          end

          after do
            FileUtils.rm_rf([real_path, other_dir])
          end

          it 'does not raise an error' do
            expect { chef_run }.not_to raise_error
          end
        end

        context 'when Gitaly is enabled' do
          before do
            File.symlink(real_path, symlink_path)
            stub_gitlab_rb(
              gitaly: {
                configuration: {
                  storage: [
                    {
                      'name' => 'default',
                      'path' => '/var/opt/gitlab/git-data/repositories'
                    },
                    {
                      'name' => 'other',
                      'path' => '/var/opt/gitlab/git-data/repositories'
                    },
                    {
                      'name' => 'realpath',
                      'path' => real_path
                    },
                    {
                      'name' => 'symlinked',
                      'path' => symlink_path,
                    }
                  ]
                }
              }
            )
          end

          after do
            FileUtils.rm_rf([real_path, other_dir])
          end

          it 'raises an error' do
            expect { chef_run }.to raise_error(/Multiple Gitaly storages are sharing the same filesystem path:.*: default.*: realpath/m)
          end
        end
      end
    end

    context 'when using repositories_storages and Gitaly storage configuration' do
      context 'using local gitaly' do
        before do
          stub_gitlab_rb(
            gitaly: {
              configuration: {
                storage: [
                  {
                    name: 'default',
                    path: '/tmp/default/git-data/repositories'
                  },
                  {
                    name: 'nfs1',
                    path: '/mnt/nfs1/repositories'
                  }
                ]
              }
            },
            gitlab_rails: {
              repositories_storages: {
                'default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                'nfs1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
              }
            }
          )
        end

        it 'correctly sets the repository storage directories' do
          expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
            .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                    'nfs1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
        end

        it 'correctly populates gitaly config.toml' do
          expect(chef_run).to render_file(config_path)
                                .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
          expect(chef_run).to render_file(config_path)
                                .with_content(%r{\[\[storage\]\]\s+name = "nfs1"\s+path = "/mnt/nfs1/repositories"})
        end
      end

      context 'using external gitaly' do
        before do
          stub_gitlab_rb(
            gitaly: {
              configuration: {
                storage: nil
              }
            },
            gitlab_rails: {
              repositories_storages: {
                'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
              }
            }
          )
        end

        it 'correctly sets the repository storage directories' do
          expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
            .to eql('default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' })
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

  context 'when not using concurrency configuration' do
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
              configuration: {
                concurrency: [
                  {
                    'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                    'max_queue_wait' => "10s",
                  }
                ]
              }
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
          .with_content(%r{\[gitlab\]\s+url = "http\+unix://%2Ffake%2Fworkhorse%2Fsocket"\s+relative_url_root = ""})
      end
    end

    context 'with only a socket directory set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { sockets_directory: '/fake/workhorse/sockets' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[gitlab\]\s+url = "http\+unix://%2Ffake%2Fworkhorse%2Fsockets%2Fsocket"\s+relative_url_root = ""})
      end
    end

    context 'with a listen_address and a sockets_directory set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { listen_addr: '/sockets/in/the/wind', sockets_directory: '/sockets/in/the' })
      end

      it 'create config file with provided values' do
        expect(chef_run).to render_file(config_path)
          .with_content(%r{\[gitlab\]\s+url = "http\+unix://%2Fsockets%2Fin%2Fthe%2Fwind"\s+relative_url_root = ""})
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
        expect(content).to match(%r{\[gitlab\]\s+url = "http://localhost:1234/gitlab"})
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
        .with_content(%r{\[gitlab\]\s+url = "http\+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket"\s+relative_url_root = "/gitlab"})
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

  context 'with custom gitlab values' do
    before do
      stub_gitlab_rb(
        gitaly: {
          configuration: {
            gitlab: {
              url: 'http://localhost:9999',
              relative_url_root: '/gitlab-ee'
            }
          }
        }
      )
    end

    it 'creates config file with the custom gitlab values set' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[gitlab\]\s+url = "http://localhost:9999"\s+relative_url_root = "/gitlab-ee"})
    end
  end

  include_examples "consul service discovery", "gitaly", "gitaly"
end

RSpec.describe 'gitaly::git_data_dirs' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(gitlab_rails: {
                     enable: false,
                   }, gitaly: {
                     enable: true,
                   }, git_data_dirs: {
                     'default' => {
                       'path' => '/tmp/git-data'
                     }
                   })
  end

  include_examples "git data directory", "/tmp/git-data/repositories"
end

RSpec.describe 'git_data_dirs configuration' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:config_path) { '/var/opt/gitlab/gitaly/config.toml' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when user has not specified git_data_dir' do
    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
        .to eql('default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/var/opt/gitlab/git-data/repositories"})
    end
  end

  context 'when gitaly is set to use a listen_addr' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       configuration: {
                         socket_path: '',
                         listen_addr: 'localhost:8123'
                       }
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
        .to eql('default' => { 'gitaly_address' => 'tcp://localhost:8123' })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/user/git-data/repositories"})
    end
  end

  context 'when gitaly is set to use a tls_listen_addr' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       configuration: {
                         socket_path: '',
                         tls_listen_addr: 'localhost:8123'
                       }
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
        .to eql('default' => { 'gitaly_address' => 'tls://localhost:8123' })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/user/git-data/repositories"})
    end
  end

  context 'when both tls and socket' do
    before do
      stub_gitlab_rb(git_data_dirs: {
                       'default' => {
                         'path' => '/tmp/user/git-data'
                       }
                     }, gitaly: {
                       configuration: {
                         socket_path: '/some/socket/path.socket',
                         tls_listen_addr: 'localhost:8123'
                       }
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages'])
        .to eql('default' => { 'gitaly_address' => 'tls://localhost:8123' })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/user/git-data/repositories"})
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
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
                                                                                      })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "overflow"\s+path = "/tmp/other/git-overflow-data/repositories"})
    end
  end

  context 'when git_data_dirs is set to multiple directories with different gitaly addresses' do
    before do
      stub_gitlab_rb({
                       git_data_dirs: {
                         'default' => { 'path' => '/tmp/default/git-data' },
                         'overflow' => { 'path' => '/tmp/other/git-overflow-data', 'gitaly_address' => 'tcp://localhost:8123', 'gitaly_token' => '123#$secret456gitaly' }
                       }
                     })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'gitaly_address' => 'tcp://localhost:8123', 'gitaly_token' => '123#$secret456gitaly' }
                                                                                      })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "overflow"\s+path = "/tmp/other/git-overflow-data/repositories"})
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
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages']).to eql({ 'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' } })
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
      expect(chef_run.node['gitlab']['gitlab_rails']['repositories_storages']).to eql({
                                                                                        'default' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
                                                                                        'overflow' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' }
                                                                                      })
    end

    it 'correctly populates gitaly config.toml' do
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "default"\s+path = "/tmp/default/git-data/repositories"})
      expect(chef_run).to render_file(config_path)
        .with_content(%r{\[\[storage\]\]\s+name = "overflow"\s+path = "/tmp/other/git-overflow-data/repositories"})
    end
  end
end
