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
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-secret-path="/var/opt/gitlab/gitlab-pages/admin.secret"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-unix-listener="/var/opt/gitlab/gitlab-pages/admin.socket"})

      # By default we defer to the gitlab-pages default for max-conns
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-max-conns})

      # By default pages access_control is disabled
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-id})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-redirect-uri})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-server})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-secret})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-secret})

      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-http})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-status-uri})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-log-format})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-cert})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-key})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-listener})
    end

    it 'correctly renders the pages log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/log/run").with_content(%r{exec svlogd -tt /var/log/gitlab/gitlab-pages})
    end
  end

  context 'with access control without id and secret' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          log_verbose: true,
          auth_secret: 'auth_secret',
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

      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-id=app_id})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-secret=app_secret})
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
          log_format: 'json',
          admin_https_cert: '/etc/gitlab/pages-admin.crt',
          admin_https_key: '/etc/gitlab/pages-admin.key',
          admin_https_listener: 'localhost:2345',
          log_verbose: true,
          gitlab_id: 'app_id',
          gitlab_secret: 'app_secret',
          auth_secret: 'auth_secret',
          access_control: true
        }
      )
    end

    it 'skip authorize pages with gitlab when id and secret exists' do
      expect(chef_run).not_to run_ruby_block('authorize pages with gitlab')
    end

    it 'correctly renders the pages service run file' do
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
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-secret-path="/var/opt/gitlab/pages/admin.secret"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-unix-listener="/var/opt/gitlab/pages/admin.socket"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-status="/@status"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-max-conns=7500})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-inplace-chroot=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-log-format="json"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-cert="/etc/gitlab/pages-admin.crt"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-key="/etc/gitlab/pages-admin.key"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-admin-https-listener="localhost:2345"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-log-verbose})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-id=app_id})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-redirect-uri="https://projects.pages.example.com/auth"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-server="https://gitlab.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-secret=app_secret})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-secret=auth_secret})
    end

    it 'correctly renders the pages log run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/log/run").with_content(%r{exec svlogd /var/log/gitlab/gitlab-pages})
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
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-id=})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-redirect-uri=})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-server=})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-client-secret=})
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-auth-secret=})
    end
  end
end
