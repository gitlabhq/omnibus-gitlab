require 'chef_helper'

RSpec.describe 'gitlab::gitlab-workhorse' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'HOME' => '/var/opt/gitlab',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin'
    }
  end
  let(:config_file) { '/var/opt/gitlab/gitlab-workhorse/config.toml' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Workhorse').with(
        version_file_path: '/var/opt/gitlab/gitlab-workhorse/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/gitlab-workhorse --version'
      )

      expect(chef_run.version_file('Create version file for Workhorse')).to notify('runit_service[gitlab-workhorse]').to(:restart)
    end

    it 'includes both authSocket and authBackend arguments' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
        expect(content).to match(%r(-authSocket /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket))
        expect(content).to match(%r(-authBackend http://localhost:8080))
      }
    end

    it 'does not include object storage configs' do
      expect(chef_run).to render_file(config_file).with_content { |content|
        expect(content).not_to match(/object_storage/)
      }
    end
  end

  context 'when the deprecated socket file exists' do
    it 'includes a cleanup for the orphan socket' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-workhorse/socket').and_return(true)
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
        expect(content).to match(%r(Removing orphaned workhorse socket at))
      }
    end
  end

  context 'user and group' do
    context 'default values' do
      it_behaves_like "enabled runit service", "gitlab-workhorse", "root", "root"
      it_behaves_like 'configured logrotate service', 'gitlab-workhorse', 'git', 'git'
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like "enabled runit service", "gitlab-workhorse", "root", "root"
      it_behaves_like 'configured logrotate service', 'gitlab-workhorse', 'foo', 'bar'
    end
  end

  context 'with environment variables' do
    context 'by default' do
      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-workhorse/env').with_variables(default_vars)
      end

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { env: { 'IAM' => 'CUSTOMVAR' } })
        end

        it 'creates necessary env variable files' do
          expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-workhorse/env').with_variables(
            default_vars.merge(
              {
                'IAM' => 'CUSTOMVAR'
              }
            )
          )
        end
      end
    end
  end

  context 'auth_socket and auth_backend' do
    context 'with only auth_socket specified' do
      context "auth_socket set to legacy '' value" do
        before do
          stub_gitlab_rb(gitlab_workhorse: { auth_socket: "''" })
        end

        it 'includes both authSocket and authBackend arguments' do
          expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
            expect(content).to match(%r(-authSocket /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket))
            expect(content).to match(%r(-authBackend http://localhost:8080))
          }
        end
      end
    end

    context 'with only auth_backend specified' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { auth_backend: 'https://test.example.com:8080' })
      end

      it 'omits authSocket argument' do
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
          expect(content).not_to match(/\-authSocket/)
          expect(content).to match(%r(-authBackend https://test.example.com:8080))
        }
      end
    end

    context "with nil auth_socket" do
      before do
        stub_gitlab_rb(gitlab_workhorse: { auth_socket: nil })
      end

      it 'includes both authSocket and authBackend arguments' do
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
          expect(content).to match(%r(-authSocket /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket))
          expect(content).to match(%r(-authBackend http://localhost:8080))
        }
      end

      context 'with auth_backend specified' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { auth_socket: nil, auth_backend: 'https://test.example.com:8080' })
        end

        it 'omits authSocket argument' do
          expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
            expect(content).not_to match(/\-authSocket/)
            expect(content).to match(%r(-authBackend https://test.example.com:8080))
          }
        end
      end
    end

    context 'with auth_backend and auth_socket set' do
      before do
        stub_gitlab_rb(gitlab_workhorse: { auth_socket: '/tmp/test.socket', auth_backend: 'https://test.example.com:8080' })
      end

      it 'includes both authSocket and authBackend arguments' do
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content { |content|
          expect(content).to match(%r(-authSocket /tmp/test.socket))
          expect(content).to match(%r(-authBackend https://test.example.com:8080))
        }
      end
    end
  end

  context 'consolidated object store settings' do
    include_context 'object storage config'

    context 'with S3 config' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            object_store: {
              enabled: true,
              connection: aws_connection_hash,
              objects: object_config
            }
          }
        )
      end

      it 'includes S3 credentials' do
        expect(chef_run).to render_file(config_file).with_content { |content|
          expect(content).to match(/\[object_storage\]\n  provider = "AWS"\n/m)
          expect(content).to match(/\[object_storage.s3\]\n  aws_access_key_id = "AKIAKIAKI"\n  aws_secret_access_key = "secret123"\n/m)
        }
      end
    end

    context 'with Azure config' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            object_store: {
              enabled: true,
              connection: azure_connection_hash,
              objects: object_config
            }
          }
        )
      end

      it 'includes Azure credentials' do
        expect(chef_run).to render_file(config_file).with_content { |content|
          expect(content).to match(/\[object_storage\]\n  provider = "AzureRM"\n/m)
          expect(content).to match(/\[object_storage.azurerm\]\n  azure_storage_account_name = "testaccount"\n  azure_storage_access_key = "1234abcd"\n/m)
        }
      end
    end
  end

  context 'without api rate limiting' do
    it 'correctly renders out the workhorse service file' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiLimit/)
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueDuration/)
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueLimit/)
    end
  end

  context 'with api rate limiting' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { api_limit: 3, api_queue_limit: 6, api_queue_duration: '1m' })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiLimit 3 \\/)
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueDuration 1m \\/)
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiQueueLimit 6 \\/)
    end
  end

  context 'without prometheus listen address' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { prometheus_listen_addr: '' })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run")
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-prometheusListenAddr/)
    end
  end

  context 'with prometheus listen address' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { prometheus_listen_addr: ':9229' })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-prometheusListenAddr :9229 \\/)
    end
  end

  context 'without api ci long polling duration defined' do
    it 'correctly renders out the workhorse service file' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiCiLongPollingDuration/)
    end
  end

  context 'with api ci long polling duration defined' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { api_ci_long_polling_duration: "60s" })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-apiCiLongPollingDuration 60s/)
    end
  end

  context 'with log format defined as json' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { log_format: "json" })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-logFormat json/)
    end

    it 'renders svlogd file which will not prepend timestamp' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-workhorse/log/run").with_content(/\-tt/)
    end
  end

  context 'with log format defined as text' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { log_format: "text" })
    end

    it 'correctly renders out the workhorse service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-logFormat text/)
    end

    it 'renders svlogd file which will prepend timestamp' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/log/run").with_content(/\-tt/)
    end
  end

  context 'with default value for working directory' do
    it 'should generate config file in the correct directory' do
      expect(chef_run).to render_file(config_file)
    end
  end

  context 'with working directory specified' do
    before do
      stub_gitlab_rb(gitlab_workhorse: { dir: "/home/random/dir" })
    end
    it 'should generate config file in the correct directory' do
      expect(chef_run).to render_file("/home/random/dir/config.toml")
    end
  end

  context 'with default values for redis' do
    it 'should generate config file' do
      content_url = 'URL = "unix:/var/opt/gitlab/redis/redis.socket"'
      expect(chef_run).to render_file(config_file).with_content(content_url)
      expect(chef_run).not_to render_file(config_file).with_content(/Sentinel/)
    end

    it 'should pass config file to workhorse' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-workhorse/run").with_content(/\-config config.toml/)
    end
  end

  context 'with host/port/password values for redis specified and socket disabled' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          redis_host: "10.0.15.1",
          redis_port: "1234",
          redis_password: 'examplepassword'
        }
      )
    end

    it 'should generate config file with the specified values' do
      content_url = 'URL = "redis://:examplepassword@10.0.15.1:1234/"'
      content_password = 'Password = "examplepassword"'
      content_sentinel = 'Sentinel'
      content_sentinel_master = 'SentinelMaster'
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_url)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_password)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_sentinel)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_sentinel_master)
    end
  end

  context 'with socket for redis specified' do
    before do
      stub_gitlab_rb(gitlab_rails: { redis_socket: "/home/random/path.socket", redis_password: 'examplepassword' })
    end

    it 'should generate config file with the specified values' do
      content_url = 'URL = "unix:/home/random/path.socket"'
      content_password = 'Password = "examplepassword"'
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_url)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_password)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(/Sentinel/)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(/SentinelMaster/)
    end
  end

  context 'with Sentinels specified with default master' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          redis_sentinels: [
            { 'host' => '127.0.0.1', 'port' => 2637 },
            { 'host' => '127.0.8.1', 'port' => 1234 }
          ]
        }
      )
    end

    it 'should generate config file with the specified values' do
      content = 'Sentinel = ["tcp://127.0.0.1:2637", "tcp://127.0.8.1:1234"]'
      content_url = 'URL ='
      content_sentinel_master = 'SentinelMaster = "gitlab-redis"'
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_sentinel_master)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_url)
    end
  end

  context 'with Sentinels and master specified' do
    before do
      stub_gitlab_rb(
        gitlab_rails: {
          redis_sentinels: [
            { 'host' => '127.0.0.1', 'port' => 26379 },
            { 'host' => '127.0.8.1', 'port' => 12345 }
          ]
        },
        redis: {
          master_name: 'examplemaster',
          master_password: 'examplepassword'
        }
      )
    end

    it 'should generate config file with the specified values' do
      content = 'Sentinel = ["tcp://127.0.0.1:26379", "tcp://127.0.8.1:12345"]'
      content_sentinel_master = 'SentinelMaster = "examplemaster"'
      content_sentinel_password = 'Password = "examplepassword"'
      content_url = 'URL ='
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_sentinel_master)
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_sentinel_password)
      expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-workhorse/config.toml").with_content(content_url)
    end
  end
end
