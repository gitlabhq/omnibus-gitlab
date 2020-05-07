require 'chef_helper'

describe 'gitlab::gitlab-pages' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com'
      )
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-server="https://gitlab.example.com"})

      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-proxy="localhost:8090"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-uid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-gid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-root="/var/opt/gitlab/gitlab-rails/shared/pages"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-domain="pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-redirect-http=false})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-use-http2=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server="https://gitlab.example.com/api/v4"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server-timeout=10})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-inplace-chroot=false})

      # By default we defer to the gitlab-pages default for max-conns
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-max-conns})

      # By default pages access_control is disabled
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-config})

      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-http})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-status-uri})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-log-format="json"})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-insecure-ciphers})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-tls-min-version})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-tls-max-version})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{http_proxy})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-api-secret-key="/var/opt/gitlab/gitlab-pages/.gitlab_pages_secret"})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-client-http-timeout})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-client-jwt-expiry})
    end

    it 'correctly renders the pages log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/log/run").with_content(%r{exec svlogd /var/log/gitlab/gitlab-pages})
    end

    it 'deletes old admin.secret file' do
      expect(chef_run).to delete_file("/var/opt/gitlab/gitlab-pages/admin.secret")
    end
  end

  context 'with access control without id and secret' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          log_verbose: true,
          auth_secret: 'auth-secret',
          access_control: true
        }
      )
    end

    it 'authorizes pages with gitlab' do
      allow(GitlabPages).to receive(:authorize_with_gitlab) {
        Gitlab['gitlab_pages']['gitlab_secret'] = 'app_secret'
        Gitlab['gitlab_pages']['gitlab_id'] = 'app_id'
      }

      expect(chef_run).to run_ruby_block('authorize pages with gitlab')
        .at_converge_time
      expect(chef_run).to run_ruby_block('re-populate GitLab Pages configuration options')
        .at_converge_time
      expect(GitlabPages).to receive(:authorize_with_gitlab)

      chef_run.ruby_block('authorize pages with gitlab').block.call
      chef_run.ruby_block('re-populate GitLab Pages configuration options').block.call

      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content(%r{auth-client-id=app_id})
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content(%r{auth-client-secret=app_secret})
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content(%r{auth-redirect-uri=https://projects.pages.example.com/auth})
      expect(chef_run).to render_file("/var/opt/gitlab/gitlab-pages/gitlab-pages-config").with_content(%r{auth-secret=auth-secret})
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          external_http: ['external_pages.example.com', 'localhost:9000'],
          external_https: ['external_pages.example.com', 'localhost:9001'],
          metrics_address: 'localhost:1234',
          redirect_http: true,
          dir: '/var/opt/gitlab/pages',
          cert: '/etc/gitlab/pages.crt',
          artifacts_server_url: "https://gitlab.elsewhere.com/api/v5",
          artifacts_server_timeout: 60,
          status_uri: '/@status',
          max_connections: 7500,
          inplace_chroot: true,
          log_format: 'text',
          log_verbose: true,
          gitlab_id: 'app_id',
          gitlab_secret: 'app_secret',
          auth_secret: 'auth_secret',
          auth_redirect_uri: 'https://projects.pages.example.com/auth',
          access_control: true,
          insecure_ciphers: true,
          tls_min_version: "tls1.0",
          tls_max_version: "tls1.2",
          sentry_enabled: true,
          sentry_dsn: 'https://b44a0828b72421a6d8e99efd68d44fa8@example.com/40',
          sentry_environment: 'production',
          headers: ['X-XSS-Protection: 1; mode=block', 'X-Content-Type-Options: nosniff', 'Test: Header'],
          gitlab_client_http_timeout: "10s",
          gitlab_client_jwt_expiry: "30s",
        }
      )
    end

    it 'skip authorize pages with gitlab when id and secret exists' do
      expect(chef_run).not_to run_ruby_block('authorize pages with gitlab')
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-server="https://gitlab.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-proxy="localhost:8090"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-uid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-gid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-root="/var/opt/gitlab/gitlab-rails/shared/pages"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-domain="pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-redirect-http=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-use-http2=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address="localhost:1234"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert="\/etc\/gitlab\/pages.crt"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-http="external_pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-http="localhost:9000"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https="external_pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https="localhost:9001"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server="https://gitlab.elsewhere.com/api/v5"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server-timeout=60})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-status="/@status"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-max-conns=7500})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-inplace-chroot=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-log-format})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-config})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-insecure-ciphers})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-tls-min-version="tls1.0"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-tls-max-version="tls1.2"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-sentry-dsn="https://b44a0828b72421a6d8e99efd68d44fa8@example.com/40"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-sentry-environment="production"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="X-XSS-Protection: 1; mode=block"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="X-Content-Type-Options: nosniff"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-header="Test: Header"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-api-secret-key="/var/opt/gitlab/pages/.gitlab_pages_secret"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-client-http-timeout})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-gitlab-client-jwt-expiry})
    end

    it 'correctly renders the pages log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/log/run").with_content(%r{exec svlogd -tt /var/log/gitlab/gitlab-pages})
    end

    it 'correctly renders the Pages config file' do
      expect(chef_run).to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-client-id=app_id})
      expect(chef_run).to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-client-secret=app_secret})
      expect(chef_run).to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-redirect-uri=https://projects.pages.example.com/auth})
      expect(chef_run).to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-secret=auth_secret})
    end

    it 'deletes old admin.secret file' do
      expect(chef_run).to delete_file("/var/opt/gitlab/pages/admin.secret")
    end
  end

  context 'with artifacts server disabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          artifacts_server: false,
          artifacts_server_url: 'https://gitlab.elsewhere.com/api/v5',
          artifacts_server_timeout: 60
        }
      )
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run")
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server=})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-artifacts-server-timeout=})
    end
  end

  context 'with access control disabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: { access_control: false }
      )
    end

    it 'skip authorize pages with gitlab if access control disabled' do
      expect(chef_run).not_to run_ruby_block('authorize pages with gitlab')
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run")
      expect(chef_run).not_to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-client-id=app_id})
      expect(chef_run).not_to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-client-secret=app_secret})
      expect(chef_run).not_to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-redirect-uri='https://projects.pages.example.com/auth'})
      expect(chef_run).not_to render_file("/var/opt/gitlab/pages/gitlab-pages-config").with_content(%r{auth-secret=auth_secret})
    end

    it 'does not render the Pages config file' do
      expect(chef_run).not_to render_file("/var/opt/gitlab/pages/.gitlab_pages_config")
    end
  end

  context 'with a http proxy value specified' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: { http_proxy: "http://example:8080" }
      )
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{http_proxy="http://example:8080"})
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
