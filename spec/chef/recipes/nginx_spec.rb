require 'chef_helper'

RSpec.describe 'gitlab::nginx' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(step_into: %w(runit_service)) do |node|
      node.normal['gitlab']['nginx']['enable'] = true
      node.normal['package']['install-dir'] = '/opt/gitlab'
    end
  end

  let(:chef_run) do
    chef_runner.converge('gitlab::config', 'gitlab::nginx')
  end

  let(:gitlab_http_config) { '/var/opt/gitlab/nginx/conf/gitlab-http.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('node') { chef_runner.node }

    # generate a random number to use as error code
    @code = rand(1000)
    @nginx_errors = {
      @code => {
        'title' => 'TEST TITLE',
        'header' => 'TEST HEADER',
        'message' => 'TEST MESSAGE'
      }
    }
  end

  it_behaves_like 'enabled runit service', 'nginx', 'root', 'root'

  it 'creates a custom error_page entry when a custom error is defined' do
    allow(Gitlab).to receive(:[]).with('nginx').and_return({ 'custom_error_pages' => @nginx_errors })

    expect(chef_run).to render_file(gitlab_http_config).with_content { |content|
      expect(content).to include("error_page #{@code} /#{@code}-custom.html;")
    }
  end

  it 'renders an error template when a custom error is defined' do
    chef_runner.node.normal['gitlab']['nginx']['custom_error_pages'] = @nginx_errors
    expect(chef_run).to render_file("/opt/gitlab/embedded/service/gitlab-rails/public/#{@code}-custom.html").with_content { |content|
      expect(content).to include("TEST MESSAGE")
    }
  end

  it 'creates a standard error_page entry when no custom error is defined' do
    chef_runner.node.normal['gitlab']['nginx'].delete('custom_error_pages')
    expect(chef_run).to render_file(gitlab_http_config).with_content { |content|
      expect(content).to include("error_page 404 /404.html;")
    }
  end

  it 'enables the proxy_intercept_errors option when custom_error_pages is defined' do
    chef_runner.node.normal['gitlab']['nginx']['custom_error_pages'] = @nginx_errors
    expect(chef_run).to render_file(gitlab_http_config).with_content { |content|
      expect(content).to include("proxy_intercept_errors on")
    }
  end

  it 'uses the default proxy_intercept_errors option when custom_error_pages is not defined' do
    chef_runner.node.normal['gitlab']['nginx'].delete('custom_error_pages')
    expect(chef_run).to render_file(gitlab_http_config).with_content { |content|
      expect(content).not_to include("proxy_intercept_errors")
    }
  end
end

RSpec.describe 'nginx' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  subject { chef_run }

  let(:gitlab_http_config) { '/var/opt/gitlab/nginx/conf/gitlab-http.conf' }
  let(:nginx_status_config) { /include \/var\/opt\/gitlab\/nginx\/conf\/nginx-status\.conf;/ }

  let(:basic_nginx_headers) do
    {
      "Host" => "$http_host",
      "X-Real-IP" => "$remote_addr",
      "X-Forwarded-Proto" => "http",
      "X-Forwarded-For" => "$proxy_add_x_forwarded_for"
    }
  end

  let(:http_conf) do
    {
      "gitlab" => "/var/opt/gitlab/nginx/conf/gitlab-http.conf",
      "mattermost" => "/var/opt/gitlab/nginx/conf/gitlab-mattermost-http.conf",
      "registry" => "/var/opt/gitlab/nginx/conf/gitlab-registry.conf",
      "pages" => "/var/opt/gitlab/nginx/conf/gitlab-pages.conf",
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when http external urls are being used' do
    before do
      stub_gitlab_rb(
        external_url: 'http://localhost',
        mattermost_external_url: 'http://mattermost.localhost',
        registry_external_url: 'http://registry.localhost',
        pages_external_url: 'http://pages.localhost'
      )
    end

    it 'properly sets the default nginx proxy headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                           "Host" => "$http_host_with_default",
                                                                                           "Upgrade" => "$http_upgrade",
                                                                                           "Connection" => "$connection_upgrade"
                                                                                         }))
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                      "X-Frame-Options" => "SAMEORIGIN",
                                                                                                      "Upgrade" => "$http_upgrade",
                                                                                                      "Connection" => "$connection_upgrade"
                                                                                                    }))
      expect(chef_run.node['gitlab']['pages-nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
    end

    it 'supports overriding default nginx headers' do
      expect_headers = nginx_headers({ "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" })
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: { "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" } },
        "mattermost_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" } },
        "registry_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" } }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to include(expect_headers)
    end
  end

  context 'when https external urls are being used' do
    before do
      stub_gitlab_rb(
        external_url: 'https://localhost',
        mattermost_external_url: 'https://mattermost.localhost',
        registry_external_url: 'https://registry.localhost',
        pages_external_url: 'https://pages.localhost'
      )
    end

    it 'properly sets the default nginx proxy ssl forward headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                           "Host" => "$http_host_with_default",
                                                                                           "X-Forwarded-Proto" => "https",
                                                                                           "X-Forwarded-Ssl" => "on",
                                                                                           "Upgrade" => "$http_upgrade",
                                                                                           "Connection" => "$connection_upgrade"
                                                                                         }))

      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                    "X-Forwarded-Proto" => "https",
                                                                                                    "X-Forwarded-Ssl" => "on"
                                                                                                  }))

      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                      "X-Forwarded-Proto" => "https",
                                                                                                      "X-Forwarded-Ssl" => "on",
                                                                                                      "X-Frame-Options" => "SAMEORIGIN",
                                                                                                      "Upgrade" => "$http_upgrade",
                                                                                                      "Connection" => "$connection_upgrade"
                                                                                                    }))

      expect(chef_run.node['gitlab']['pages-nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                 "X-Forwarded-Proto" => "https",
                                                                                                 "X-Forwarded-Ssl" => "on"
                                                                                               }))
    end

    it 'supports overriding default nginx headers' do
      expect_headers = nginx_headers({ "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp", "X-Forwarded-Ssl" => "on", 'Connection' => 'close' })
      set_headers = { "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp", 'Connection' => 'close' }
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: set_headers },
        "mattermost_nginx" => { proxy_set_headers: set_headers },
        "registry_nginx" => { proxy_set_headers: set_headers },
        "pages_nginx" => { proxy_set_headers: set_headers }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['pages-nginx']['proxy_set_headers']).to include(expect_headers)
    end

    it 'disables Connection header' do
      expect_headers = nginx_headers({ "Host" => "nohost.example.com", "X-Forwarded-Proto" => "https", "X-Forwarded-Ssl" => "on" })
      set_headers = { "Host" => "nohost.example.com", "Connection" => nil }
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: set_headers },
        "mattermost_nginx" => { proxy_set_headers: set_headers },
        "registry_nginx" => { proxy_set_headers: set_headers },
        "pages_nginx" => { proxy_set_headers: set_headers }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['pages-nginx']['proxy_set_headers']).to include(expect_headers)
    end

    it 'does not set ssl_client_certificate by default' do
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).not_to include("ssl_client_certificate")
        }
      end
    end

    it 'does not set ssl_verify_client by default' do
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).not_to include("ssl_verify_client")
        }
      end
    end

    it 'does not set ssl_verify_depth by default' do
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).not_to include("ssl_verify_depth")
        }
      end
    end

    it 'sets the default ssl_verify_depth when ssl_verify_client is defined' do
      verify_client = { "ssl_verify_client" => "on" }
      stub_gitlab_rb(
        "nginx" => verify_client,
        "mattermost_nginx" => verify_client,
        "registry_nginx" => verify_client,
        "pages_nginx" => verify_client
      )
      chef_run.converge('gitlab::default')
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).to include("ssl_verify_depth 1")
        }
      end
    end

    it 'applies nginx verify client settings to gitlab-http' do
      stub_gitlab_rb("nginx" => {
                       "ssl_client_certificate" => "/etc/gitlab/ssl/gitlab-http-ca.crt",
                       "ssl_verify_client" => "on",
                       "ssl_verify_depth" => "2",
                     })
      chef_run.converge('gitlab::default')
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include("ssl_client_certificate /etc/gitlab/ssl/gitlab-http-ca.crt")
        expect(content).to include("ssl_verify_client on")
        expect(content).to include("ssl_verify_depth 2")
      }
    end

    it 'applies nginx request_buffering path regex' do
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include("location ~ (\.git/git-receive-pack$|\.git/info/refs?service=git-receive-pack$|\.git/gitlab-lfs/objects|\.git/info/lfs/objects/batch$)")
      }
    end

    it 'applies mattermost_nginx verify client settings to gitlab-mattermost-http' do
      stub_gitlab_rb("mattermost_nginx" => {
                       "ssl_client_certificate" => "/etc/gitlab/ssl/gitlab-mattermost-http-ca.crt",
                       "ssl_verify_client" => "on",
                       "ssl_verify_depth" => "3",
                     })
      chef_run.converge('gitlab::default')
      expect(chef_run).to render_file(http_conf['mattermost']).with_content { |content|
        expect(content).to include("ssl_client_certificate /etc/gitlab/ssl/gitlab-mattermost-http-ca.crt")
        expect(content).to include("ssl_verify_client on")
        expect(content).to include("ssl_verify_depth 3")
      }
    end

    it 'applies registry_nginx verify client settings to gitlab-registry' do
      stub_gitlab_rb("registry_nginx" => {
                       "ssl_client_certificate" => "/etc/gitlab/ssl/gitlab-registry-ca.crt",
                       "ssl_verify_client" => "off",
                       "ssl_verify_depth" => "5",
                     })
      chef_run.converge('gitlab::default')
      expect(chef_run).to render_file(http_conf['registry']).with_content { |content|
        expect(content).to include("ssl_client_certificate /etc/gitlab/ssl/gitlab-registry-ca.crt")
        expect(content).to include("ssl_verify_client off")
        expect(content).to include("ssl_verify_depth 5")
      }
    end

    it 'applies pages_nginx verify client settings to gitlab-pages' do
      stub_gitlab_rb("pages_nginx" => {
                       "ssl_client_certificate" => "/etc/gitlab/ssl/gitlab-pages-ca.crt",
                       "ssl_verify_client" => "on",
                       "ssl_verify_depth" => "7",
                     })
      chef_run.converge('gitlab::default')
      expect(chef_run).to render_file(http_conf['pages']).with_content { |content|
        expect(content).to include("ssl_client_certificate /etc/gitlab/ssl/gitlab-pages-ca.crt")
        expect(content).to include("ssl_verify_client on")
        expect(content).to include("ssl_verify_depth 7")
      }
    end
  end

  context 'when is enabled' do
    it 'enables nginx status by default' do
      expect(chef_run.node['gitlab']['nginx']['status']).to eql({
                                                                  "enable" => true,
                                                                  "listen_addresses" => ["*"],
                                                                  "fqdn" => "localhost",
                                                                  "port" => 8060,
                                                                  "vts_enable" => true,
                                                                  "options" => {
                                                                    "server_tokens" => "off",
                                                                    "access_log" => "off",
                                                                    "allow" => "127.0.0.1",
                                                                    "deny" => "all"
                                                                  }
                                                                })
      expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/nginx.conf').with_content(nginx_status_config)
    end

    it "supports overrading nginx status default configuration" do
      custom_nginx_status_config = {
        "enable" => true,
        "listen_addresses" => ["127.0.0.1"],
        "fqdn" => "dev.example.com",
        "port" => 9999,
        "vts_enable" => true,
        "options" => {
          "server_tokens" => "off",
          "access_log" => "on",
          "allow" => "127.0.0.1",
          "deny" => "all"
        }
      }

      stub_gitlab_rb("nginx" => {
                       "status" => custom_nginx_status_config
                     })

      chef_run.converge('gitlab::default')

      expect(chef_run.node['gitlab']['nginx']['status']).to eql(custom_nginx_status_config)
    end

    it "will not load the nginx status config if nginx status is disabled" do
      stub_gitlab_rb("nginx" => { "status" => { "enable" => false } })
      expect(chef_run).not_to render_file('/var/opt/gitlab/nginx/conf/nginx.conf').with_content(nginx_status_config)
    end

    it 'defaults to redirect_http_to_https off' do
      expect(chef_run.node['gitlab']['nginx']['redirect_http_to_https']).to be false
      expect(chef_run).to render_file(gitlab_http_config).with_content { |content|
        expect(content).not_to include('return 301 https://fauxhai.local:80$request_uri;')
      }
    end

    it 'enables redirect when redirect_http_to_https is true' do
      stub_gitlab_rb(nginx: { listen_https: true, redirect_http_to_https: true })
      expect(chef_run.node['gitlab']['nginx']['redirect_http_to_https']).to be true
      expect(chef_run).to render_file(gitlab_http_config).with_content('return 301 https://fauxhai.local:80$request_uri;')
    end

    context 'when smartcard authentication is enabled' do
      let(:gitlab_smartcard_http_config) { '/var/opt/gitlab/nginx/conf/gitlab-smartcard-http.conf' }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            smartcard_enabled: true
          },
          nginx: { listen_https: true }
        )
      end

      it 'listens on a separate port' do
        expect(chef_run).to render_file(gitlab_smartcard_http_config).with_content { |content|
          expect(content).to include('server_name fauxhai.local;')
          expect(content).to include('listen *:3444 ssl http2;')
        }
      end

      it 'requires client side certificate' do
        expect(chef_run).to render_file(gitlab_smartcard_http_config).with_content { |content|
          expect(content).to include('ssl_client_certificate /etc/gitlab/ssl/CA.pem')
          expect(content).to include('ssl_verify_client on')
          expect(content).to include('ssl_verify_depth 2')
        }
      end

      it 'forwards client side certificate in header' do
        expect(chef_run).to render_file(gitlab_smartcard_http_config).with_content('proxy_set_header X-SSL-Client-Certificate')
      end

      context 'when smartcard_client_certificate_required_host is set' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              smartcard_enabled: true,
              smartcard_client_certificate_required_host: 'smartcard.fauxhai.local'
            },
            nginx: { listen_https: true }
          )
        end

        it 'sets smartcard nginx server name' do
          expect(chef_run).to render_file(gitlab_smartcard_http_config).with_content { |content|
            expect(content).to include('server_name smartcard.fauxhai.local;')
            expect(content).to include('listen *:3444 ssl http2;')
          }
        end
      end
    end

    context 'when smartcard authentication is disabled' do
      let(:gitlab_smartcard_http_config) { '/var/opt/gitlab/nginx/conf/gitlab-smartcard-http.conf' }

      before do
        stub_gitlab_rb(gitlab_rails: { smartcard_enabled: false })
      end

      it 'should not add the gitlab smartcard config' do
        expect(chef_run).not_to render_file(gitlab_smartcard_http_config)
      end
    end
  end

  context 'when is disabled' do
    it 'should not add the nginx status config' do
      stub_gitlab_rb("nginx" => { "enable" => false })
      expect(chef_run).not_to render_file('/var/opt/gitlab/nginx/conf/nginx.conf').with_content(nginx_status_config)
    end
  end

  context 'when grafana is enabled' do
    before do
      stub_gitlab_rb(
        grafana: { enable: true }
      )
    end

    it 'applies nginx grafana proxy' do
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include('location /-/grafana/ {')
        expect(content).to include('proxy_pass http://localhost:3000/;')
      }
    end
  end

  context 'when hsts is disabled' do
    before do
      stub_gitlab_rb(nginx: { hsts_max_age: 0 })
    end
    it { is_expected.not_to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security "max-age=31536000";/) }

  context 'when referrer_policy is disabled' do
    before do
      stub_gitlab_rb(nginx: { referrer_policy: false })
    end

    it { is_expected.not_to render_file(gitlab_http_config).with_content(/add_header Referrer-Policy/) }
  end

  context 'when referrer_policy is set to origin' do
    before do
      stub_gitlab_rb(nginx: { referrer_policy: 'origin' })
    end

    it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Referrer-Policy origin;/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Referrer-Policy strict-origin-when-cross-origin;/) }

  context 'when gzip is disabled' do
    before do
      stub_gitlab_rb(nginx: { gzip_enabled: false })
    end
    it { is_expected.not_to render_file(gitlab_http_config).with_content(/gzip on;/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/gzip on;/) }

  context 'when include_subdomains is enabled' do
    before do
      stub_gitlab_rb(nginx: { hsts_include_subdomains: true })
    end

    it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";/) }
  end

  context 'when max-age is set to 10' do
    before do
      stub_gitlab_rb(nginx: { hsts_max_age: 10 })
    end

    it { is_expected.to render_file(gitlab_http_config).with_content(/"max-age=10[^"]*"/) }
  end

  context 'when NGINX RealIP module is configured' do
    before do
      stub_gitlab_rb(
        external_url: 'https://localhost',
        mattermost_external_url: 'https://mattermost.localhost',
        registry_external_url: 'https://registry.localhost',
        pages_external_url: 'https://pages.localhost'
      )
    end

    context 'when real_ip_header is configured' do
      before do
        stub_gitlab_rb(
          nginx: { real_ip_header: 'X-FAKE' },
          mattermost_nginx: { real_ip_header: 'X-FAKE' },
          registry_nginx: { real_ip_header: 'X-FAKE' },
          pages_nginx: { real_ip_header: 'X-FAKE' }
        )
      end

      it 'populates all config with real_ip_header' do
        http_conf.each_value do |conf|
          expect(chef_run).to render_file(conf).with_content(/real_ip_header X-FAKE/)
        end
      end
    end

    context 'when real_ip_recursive is configured' do
      before do
        stub_gitlab_rb(
          nginx: { real_ip_recursive: 'On' },
          mattermost_nginx: { real_ip_recursive: 'On' },
          registry_nginx: { real_ip_recursive: 'On' },
          pages_nginx: { real_ip_recursive: 'On' }
        )
      end

      it 'populates all config with real_up_recursive' do
        http_conf.each_value do |conf|
          expect(chef_run).to render_file(conf).with_content(/real_ip_recursive On/)
        end
      end
    end

    context 'when real_ip_trusted_addresses is configured' do
      before do
        stub_gitlab_rb(
          nginx: { real_ip_trusted_addresses: %w(one two three) },
          mattermost_nginx: { real_ip_trusted_addresses: %w(one two three) },
          registry_nginx: { real_ip_trusted_addresses: %w(one two three) },
          pages_nginx: { real_ip_trusted_addresses: %w(one two three) }
        )
      end

      it 'populates all config with all items for real_ip_trusted_addresses' do
        http_conf.each_value do |conf|
          expect(chef_run).to render_file(conf).with_content { |content|
            expect(content).to match(/set_real_ip_from one/)
            expect(content).to match(/set_real_ip_from two/)
            expect(content).to match(/set_real_ip_from three/)
          }
        end
      end
    end
  end

  describe 'logrotate settings' do
    context 'default values' do
      it_behaves_like 'configured logrotate service', 'nginx', 'root', 'root'
    end

    context 'specified username and group' do
      before do
        stub_gitlab_rb(
          web_server: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'configured logrotate service', 'nginx', 'root', 'root'
    end
  end

  def nginx_headers(additional_headers)
    basic_nginx_headers.merge(additional_headers)
  end
end
