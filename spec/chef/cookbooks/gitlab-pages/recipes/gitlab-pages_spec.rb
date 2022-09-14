require 'chef_helper'

RSpec.describe 'gitlab::gitlab-pages' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Etc).to receive(:getpwnam).with('git').and_return(spy('getpwnam spy', uid: 1000, gid: 1000))
  end

  context 'with default values' do
    it 'does not include Pages recipe' do
      expect(chef_run).not_to include_recipe('gitlab-pages::enable')
      expect(chef_run).to include_recipe('gitlab-pages::disable')
    end
  end

  context 'with Pages enabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com'
      )
    end

    it 'includes Pages recipe' do
      expect(chef_run).to include_recipe('gitlab-pages::enable')
    end

    it 'creates a VERSION file and restarts the service' do
      expect(chef_run).to create_version_file('Create version file for Gitlab Pages').with(
        version_file_path: '/var/opt/gitlab/gitlab-pages/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/gitlab-pages --version'
      )

      expect(chef_run.version_file('Create version file for Gitlab Pages')).to notify('runit_service[gitlab-pages]').to(:restart)
    end

    it 'renders the env dir files' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-pages/env/SSL_CERT_DIR')
        .with_content('/opt/gitlab/embedded/ssl/certs')
    end

    it 'renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-config="/var/opt/gitlab/gitlab-pages/gitlab-pages-config"})
    end

    it 'renders the pages log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/log/run").with_content(%r{exec svlogd /var/log/gitlab/gitlab-pages})
    end

    it 'deletes old admin.secret file' do
      expect(chef_run).to delete_file("/var/opt/gitlab/gitlab-pages/admin.secret")
    end

    it 'renders pages config file' do
      default_content = <<~EOS
       pages-domain=pages.example.com
       pages-root=/var/opt/gitlab/gitlab-rails/shared/pages
       api-secret-key=/var/opt/gitlab/gitlab-pages/.gitlab_pages_secret
       listen-proxy=localhost:8090
       log-format=json
       use-http2=true
       artifacts-server=https://gitlab.example.com/api/v4
       artifacts-server-timeout=10
       gitlab-server=https://gitlab.example.com
      EOS

      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content(default_content)
    end

    it 'skips rendering the auth settings when access control is disabled' do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          access_control: false,
          auth_secret: 'auth_secret'
        }
      )

      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content { |content|
        expect(content).not_to match(%r{auth-secret=auth_secret})
      }
    end

    context 'when access control is enabled' do
      context 'when access control secrets are not specified' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_pages: {
              access_control: true,
              auth_secret: 'auth_secret'
            }
          )

          allow(GitlabPages).to receive(:authorize_with_gitlab) {
            Gitlab['gitlab_pages']['gitlab_secret'] = 'app_secret'
            Gitlab['gitlab_pages']['gitlab_id'] = 'app_id'
          }
        end

        it 'authorizes Pages with GitLab' do
          expect(chef_run).to run_ruby_block('authorize pages with gitlab')
            .at_converge_time
          expect(chef_run).to run_ruby_block('re-populate GitLab Pages configuration options')
            .at_converge_time
          expect(GitlabPages).to receive(:authorize_with_gitlab)

          chef_run.ruby_block('authorize pages with gitlab').block.call
          chef_run.ruby_block('re-populate GitLab Pages configuration options').block.call

          expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content { |content|
            expect(content).to match(%r{auth-client-id=app_id})
            expect(content).to match(%r{auth-client-secret=app_secret})
            expect(content).to match(%r{auth-redirect-uri=https://projects.pages.example.com/auth})
            expect(content).to match(%r{auth-secret=auth_secret})
          }
        end
      end

      context 'when access control secrets are specified' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_pages: {
              access_control: true,
              gitlab_id: 'app_id',
              gitlab_secret: 'app_secret',
              auth_secret: 'auth_secret',
              auth_redirect_uri: 'https://projects.pages.example.com/auth',
              auth_scope: 'read_api'
            }
          )
        end

        it 'attempt to authorize with GitLab even when oauth credentials are given' do
          expect(chef_run).to run_ruby_block('authorize pages with gitlab')
        end

        it 'renders pages config file' do
          expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content { |content|
            expect(content).to match(%r{auth-client-id=app_id})
            expect(content).to match(%r{auth-client-secret=app_secret})
            expect(content).to match(%r{auth-redirect-uri=https://projects.pages.example.com/auth})
            expect(content).to match(%r{auth-secret=auth_secret})
            expect(content).to match(%r{auth-scope=read_api})
          }
        end
      end
    end

    context 'with custom port' do
      before do
        stub_gitlab_rb(
          pages_external_url: 'https://pages.example.com:8443',
          gitlab_pages: {
            access_control: true
          }
        )
      end

      it 'sets the correct port number' do
        expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content { |content|
          expect(content).to match(%r{auth-redirect-uri=https://projects.pages.example.com:8443/auth})
        }
      end
    end

    context 'with custom values' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          pages_external_url: 'https://pages.example.com',
          gitlab_pages: {
            external_http: ['external_pages.example.com', 'localhost:9000'],
            external_https: ['external_pages.example.com', 'localhost:9001'],
            external_https_proxyv2: ['external_pages.example.com', 'localhost:9002'],
            metrics_address: 'localhost:1234',
            redirect_http: true,
            dir: '/var/opt/gitlab/pages',
            cert: '/etc/gitlab/pages.crt',
            artifacts_server_url: "https://gitlab.elsewhere.com/api/v5",
            artifacts_server_timeout: 60,
            status_uri: '/@status',
            max_connections: 7500,
            max_uri_length: 2048,
            propagate_correlation_id: true,
            log_format: 'text',
            log_verbose: true,
            gitlab_id: 'app_id',
            gitlab_secret: 'app_secret',
            auth_secret: 'auth_secret',
            auth_redirect_uri: 'https://projects.pages.example.com/auth',
            auth_scope: 'read_api',
            access_control: true,
            insecure_ciphers: true,
            tls_min_version: "tls1.0",
            tls_max_version: "tls1.2",
            sentry_enabled: true,
            sentry_dsn: 'https://b44a0828b72421a6d8e99efd68d44fa8@example.com/40',
            sentry_environment: 'production',
            headers: ['X-XSS-Protection: 1; mode=block', 'X-Content-Type-Options: nosniff', 'Test: Header'],
            server_shutdown_timeout: "30s",
            gitlab_client_http_timeout: "10s",
            gitlab_client_jwt_expiry: "30s",
            zip_cache_expiration: "120s",
            zip_cache_cleanup: "1m",
            zip_cache_refresh: "60s",
            zip_open_timeout: "45s",
            zip_http_client_timeout: "30m",
            internal_gitlab_server: "https://int.gitlab.example.com",
            gitlab_cache_expiry: "1m",
            gitlab_cache_refresh: "500ms",
            gitlab_cache_cleanup: "100ms",
            gitlab_retrieval_timeout: "3s",
            gitlab_retrieval_interval: "500ms",
            gitlab_retrieval_retries: 5,
            rate_limit_source_ip: 100,
            rate_limit_source_ip_burst: 50,
            rate_limit_domain: 1000,
            rate_limit_domain_burst: 10000,
            rate_limit_tls_source_ip: 101,
            rate_limit_tls_source_ip_burst: 51,
            rate_limit_tls_domain: 1001,
            rate_limit_tls_domain_burst: 10001,
            server_read_timeout: "1m",
            server_read_header_timeout: "2m",
            server_write_timeout: "3m",
            server_keep_alive: "4m",
            redirects_max_config_size: 128000,
            redirects_max_path_segments: 50,
            redirects_max_rule_count: 2000,
            enable_disk: true,
            env: {
              GITLAB_CONTINUOUS_PROFILING: "stackdriver?service=gitlab-pages",
            },
          }
        )
      end

      it 'renders pages config file in the specified directory' do
        expected_content = <<~EOS
            pages-domain=pages.example.com
            pages-root=/var/opt/gitlab/gitlab-rails/shared/pages
            api-secret-key=/var/opt/gitlab/pages/.gitlab_pages_secret
            auth-client-id=app_id
            auth-redirect-uri=https://projects.pages.example.com/auth
            auth-client-secret=app_secret
            auth-secret=auth_secret
            auth-scope=read_api
            zip-cache-expiration=120s
            zip-cache-cleanup=1m
            zip-cache-refresh=60s
            zip-open-timeout=45s
            zip-http-client-timeout=30m
            listen-proxy=localhost:8090
            metrics-address=localhost:1234
            pages-status=/@status
            max-conns=7500
            max-uri-length=2048
            propagate-correlation-id=true
            log-format=text
            log-verbose
            sentry-dsn=https://b44a0828b72421a6d8e99efd68d44fa8@example.com/40
            sentry-environment=production
            redirect-http=true
            use-http2=true
            artifacts-server=https://gitlab.elsewhere.com/api/v5
            artifacts-server-timeout=60
            gitlab-server=https://gitlab.example.com
            internal-gitlab-server=https://int.gitlab.example.com
            insecure-ciphers
            tls-min-version=tls1.0
            tls-max-version=tls1.2
            server-shutdown-timeout=30s
            gitlab-client-http-timeout=10s
            gitlab-client-jwt-expiry=30s
            listen-http=external_pages.example.com,localhost:9000
            listen-https=external_pages.example.com,localhost:9001
            listen-https-proxyv2=external_pages.example.com,localhost:9002
            root-cert=/etc/gitlab/pages.crt
            root-key=/etc/gitlab/ssl/pages.example.com.key
            gitlab-cache-expiry=1m
            gitlab-cache-refresh=500ms
            gitlab-cache-cleanup=100ms
            gitlab-retrieval-timeout=3s
            gitlab-retrieval-timeout=500ms
            gitlab-retrieval-retries=5
            enable-disk=true
            rate-limit-source-ip=100
            rate-limit-source-ip-burst=50
            rate-limit-domain=1000
            rate-limit-domain-burst=10000
            rate-limit-tls-source-ip=101
            rate-limit-tls-source-ip-burst=51
            rate-limit-tls-domain=1001
            rate-limit-tls-domain-burst=10001
            server-read-timeout=1m
            server-read-header-timeout=2m
            server-write-timeout=3m
            server-keep-alive=4m
            redirects-max-config-size=128000
            redirects-max-path-segments=50
            redirects-max-rule-count=2000
        EOS

        expect(chef_run).to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(expected_content)
      end

      it 'specifies headers as arguments in the run file' do
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="X-XSS-Protection: 1; mode=block"})
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="X-Content-Type-Options: nosniff"})
        expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="Test: Header"})
      end

      it 'renders the env dir files' do
        expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-pages/env/GITLAB_CONTINUOUS_PROFILING")
          .with_content('stackdriver?service=gitlab-pages')
        expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-pages/env/SSL_CERT_DIR")
          .with_content('/opt/gitlab/embedded/ssl/certs')
      end
    end

    describe 'logrotate settings' do
      context 'default values' do
        it_behaves_like 'configured logrotate service', 'gitlab-pages', 'git', 'git'
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

        it_behaves_like 'configured logrotate service', 'gitlab-pages', 'foo', 'bar'
      end
    end
  end
end
