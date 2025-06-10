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
      expect(content).not_to include("proxy_intercept_errors on")
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
      "gitlab_kas" => "/var/opt/gitlab/nginx/conf/gitlab-kas.conf"
    }
  end

  let(:metrics_http_conf) do
    {
      "gitlab-health" => "/var/opt/gitlab/nginx/conf/gitlab-health.conf",
      "nginx-status" => "/var/opt/gitlab/nginx/conf/nginx-status.conf"
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
        pages_external_url: 'http://pages.localhost',
        gitlab_kas_external_url: 'ws://kas.localhost',
        gitlab_kas: { listen_websocket: true }
      )
    end

    it 'properly sets the default nginx proxy headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                           "Host" => "$http_host_with_default",
                                                                                           "Upgrade" => "$http_upgrade",
                                                                                           "Connection" => "$connection_upgrade",
                                                                                           "X-Forwarded-For" => "$remote_addr"
                                                                                         }))
      expect(chef_run.node['gitlab']['registry_nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
      expect(chef_run.node['gitlab']['mattermost_nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                      "X-Frame-Options" => "SAMEORIGIN",
                                                                                                      "Upgrade" => "$http_upgrade",
                                                                                                      "Connection" => "$connection_upgrade"
                                                                                                    }))
      expect(chef_run.node['gitlab']['pages_nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
    end

    it 'properly sets the default nginx proxy headers for gitlab_kas' do
      expected_nginx_headers = basic_nginx_headers.merge({
                                                           "Host" => "$http_host",
                                                           "Connection" => "$connection_upgrade",
                                                           "Upgrade" => "$http_upgrade",
                                                           "X-Forwarded-For" => "$remote_addr",
                                                           "X-Original-Forwarded-For" => "$http_x_forwarded_for",
                                                           "X-Forwarded-Proto" => "$scheme",
                                                           "X-Forwarded-Scheme" => "$scheme",
                                                           "X-Scheme" => "$scheme"
                                                         })
      expect(chef_run.node['gitlab']['gitlab_kas_nginx']['proxy_set_headers']).to eql(expected_nginx_headers)
    end

    it 'supports overriding default nginx headers' do
      set_headers = { "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" }
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: set_headers },
        "mattermost_nginx" => { proxy_set_headers: set_headers },
        "registry_nginx" => { proxy_set_headers: set_headers },
        "gitlab_kas_nginx" => { proxy_set_headers: set_headers }
      )

      expect_headers = nginx_headers(set_headers)
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to(
        include(expect_headers.merge({ "X-Forwarded-For" => "$remote_addr" })))
      expect(chef_run.node['gitlab']['mattermost_nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry_nginx']['proxy_set_headers']).to include(expect_headers)

      # only test the headers that were overridden
      expect(chef_run.node['gitlab']['gitlab_kas_nginx']['proxy_set_headers'].to_h).to include(set_headers)
    end
  end

  context 'when https external urls are being used' do
    before do
      stub_gitlab_rb(
        external_url: 'https://localhost',
        mattermost_external_url: 'https://mattermost.localhost',
        registry_external_url: 'https://registry.localhost',
        pages_external_url: 'https://pages.localhost',
        gitlab_kas_external_url: 'wss://kas.localhost',
        gitlab_kas: { listen_websocket: true }
      )
    end

    it 'properly sets the default nginx proxy ssl forward headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                           "Host" => "$http_host_with_default",
                                                                                           "X-Forwarded-Proto" => "https",
                                                                                           "X-Forwarded-Ssl" => "on",
                                                                                           "Upgrade" => "$http_upgrade",
                                                                                           "Connection" => "$connection_upgrade",
                                                                                           "X-Forwarded-For" => "$remote_addr"
                                                                                         }))

      expect(chef_run.node['gitlab']['registry_nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                    "X-Forwarded-Proto" => "https",
                                                                                                    "X-Forwarded-Ssl" => "on"
                                                                                                  }))

      expect(chef_run.node['gitlab']['mattermost_nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                      "X-Forwarded-Proto" => "https",
                                                                                                      "X-Forwarded-Ssl" => "on",
                                                                                                      "X-Frame-Options" => "SAMEORIGIN",
                                                                                                      "Upgrade" => "$http_upgrade",
                                                                                                      "Connection" => "$connection_upgrade"
                                                                                                    }))

      expect(chef_run.node['gitlab']['pages_nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                 "X-Forwarded-Proto" => "https",
                                                                                                 "X-Forwarded-Ssl" => "on"
                                                                                               }))
      expect(chef_run.node['gitlab']['gitlab_kas_nginx']['proxy_set_headers']).to eql(nginx_headers({
                                                                                                      "Host" => "$http_host",
                                                                                                      "Upgrade" => "$http_upgrade",
                                                                                                      "Connection" => "$connection_upgrade",
                                                                                                      "X-Forwarded-For" => "$remote_addr",
                                                                                                      "X-Original-Forwarded-For" => "$http_x_forwarded_for",
                                                                                                      "X-Forwarded-Proto" => "$scheme",
                                                                                                      "X-Forwarded-Scheme" => "$scheme",
                                                                                                      "X-Scheme" => "$scheme",
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
        "pages_nginx" => { proxy_set_headers: set_headers },
        "gitlab_kas_nginx" => { proxy_set_headers: set_headers }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers.merge("X-Forwarded-For" => "$remote_addr"))
      expect(chef_run.node['gitlab']['mattermost_nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry_nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['pages_nginx']['proxy_set_headers']).to include(expect_headers)

      # only testing against the headers that were set
      expect(chef_run.node['gitlab']['gitlab_kas_nginx']['proxy_set_headers'].to_h).to include(set_headers)
    end

    it 'disables Connection header' do
      expect_headers = nginx_headers({ "Host" => "nohost.example.com", "X-Forwarded-Proto" => "https", "X-Forwarded-Ssl" => "on" })
      set_headers = { "Host" => "nohost.example.com", "Connection" => nil }
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: set_headers },
        "mattermost_nginx" => { proxy_set_headers: set_headers },
        "registry_nginx" => { proxy_set_headers: set_headers },
        "pages_nginx" => { proxy_set_headers: set_headers },
        "gitlab_kas_nginx" => { proxy_set_headers: set_headers }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers.merge("X-Forwarded-For" => "$remote_addr"))
      expect(chef_run.node['gitlab']['mattermost_nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry_nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['pages_nginx']['proxy_set_headers']).to include(expect_headers)
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
        "pages_nginx" => verify_client,
        "gitlab_kas_nginx" => verify_client
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
        expect(content).to include("location ~ (/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$)")
      }
    end

    it 'disables proxy cache for api urls' do
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include("location ~ ^/api/v\\d {\n    proxy_cache off;")
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

    it 'applies gitlab_kas_nginx verify client settings to gitlab-kas' do
      stub_gitlab_rb(
        "gitlab_kas_nginx" => {
          "ssl_client_certificate" => "/etc/gitlab/ssl/gitlab-kas-ca.crt",
          "ssl_verify_client" => "on",
          "ssl_verify_depth" => "7",
        }
      )
      chef_run.converge('gitlab::default')
      expect(chef_run).to render_file(http_conf['gitlab_kas']).with_content { |content|
        expect(content).to include("ssl_client_certificate /etc/gitlab/ssl/gitlab-kas-ca.crt")
        expect(content).to include("ssl_verify_client on")
        expect(content).to include("ssl_verify_depth 7")
      }
    end

    describe 'ssl_password_file' do
      context 'by default' do
        it 'does not set ssl_password_file' do
          http_conf.each_value do |conf|
            expect(chef_run).to render_file(conf).with_content { |content|
              expect(content).not_to include("ssl_password_file")
            }
          end
        end
      end

      context 'when explicitly specified' do
        before do
          stub_gitlab_rb(
            external_url: 'https://localhost',
            mattermost_external_url: 'https://mattermost.localhost',
            registry_external_url: 'https://registry.localhost',
            pages_external_url: 'https://pages.localhost',
            gitlab_kas_external_url: 'wss://kas.localhost',
            gitlab_kas: { listen_websocket: true },
            nginx: {
              ssl_password_file: '/etc/gitlab/ssl/gitlab_password_file.txt'
            },
            mattermost_nginx: {
              ssl_password_file: '/etc/gitlab/ssl/mattermost_password_file.txt'
            },
            pages_nginx: {
              ssl_password_file: '/etc/gitlab/ssl/pages_password_file.txt'
            },
            registry_nginx: {
              ssl_password_file: '/etc/gitlab/ssl/registry_password_file.txt'
            },
            gitlab_kas_nginx: {
              ssl_password_file: '/etc/gitlab/ssl/gitlab_kas_password_file.txt'
            }
          )
        end

        it "sets ssl_password_file correctly in nginx config" do
          http_conf.each do |service, conf|
            expect(chef_run).to render_file(conf).with_content { |content|
              expect(content).to include("ssl_password_file '/etc/gitlab/ssl/#{service}_password_file.txt';")
            }
          end
        end
      end
    end

    # Required to allow chunked encoding responses as of nginx 1.23
    # https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7006
    it 'sets proxy_http_version 1.1 when proxy_pass is used' do
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).to include('proxy_http_version 1.1;') if content.include?('proxy_pass')
        }
      end
    end

    it 'sets proxy_http_version 1.0 when proxy_pass is used' do
      metrics_http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).to include('proxy_http_version 1.0;') if content.include?('proxy_pass')
        }
      end
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

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for NGINX').with(
        version_file_path: '/var/opt/gitlab/nginx/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/sbin/nginx -ver 2>&1'
      )

      expect(chef_run.version_file('Create version file for NGINX')).to notify('runit_service[nginx]').to(:restart)
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
          expect(content).to include('listen *:3444 ssl;')
          expect(content).to include('http2 on;')
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
            expect(content).to include('listen *:3444 ssl;')
            expect(content).to include('http2 on;')
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

  context 'when KAS is enabled' do
    before do
      stub_gitlab_rb(
        gitlab_kas: { enable: true }
      )
    end

    it 'applies nginx KAS proxy' do
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include('location = /-/kubernetes-agent/ {')
        expect(content).to include('proxy_pass http://localhost:8150/;')
        expect(content).to include('proxy_http_version 1.1;')

        expect(content).to include('location /-/kubernetes-agent/k8s-proxy/ {')
        expect(content).to include('proxy_pass http://localhost:8154/;')
      }
    end

    context 'when external url with its own sub-domain is set' do
      before do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_kas: { enable: true, listen_websocket: true },
          gitlab_kas_external_url: gitlab_kas_external_url
        )
      end

      let(:gitlab_kas_external_url) { 'wss://kas.gitlab.example.com' }

      it 'applies nginx KAS proxy' do
        expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
          expect(content).to include('location = /-/kubernetes-agent/ {')
          expect(content).to include('proxy_pass http://localhost:8150/;')
          expect(content).to include('proxy_http_version 1.1;')

          expect(content).to include('location /-/kubernetes-agent/k8s-proxy/ {')
          expect(content).to include('proxy_pass http://localhost:8154/;')
        }
      end

      it 'applies nginx to the kas subdomain' do
        expect(chef_run).to render_file(http_conf['gitlab_kas']).with_content { |content|
          expect(content).to include('listen *:443')
          expect(content).to include('server_name kas.gitlab.example.com;')

          expect(content).to include('proxy_http_version 1.1;')
          expect(content).to include('proxy_pass http://localhost:8150/;')
          expect(content).to include('proxy_http_version 1.1;')

          expect(content).to include('location /k8s-proxy/ {')
          expect(content).to include('location = /k8s-proxy/ {')
          expect(content).to include('proxy_pass http://localhost:8154/;')

          expect(content).to include('proxy_set_header X-Forwarded-For $remote_addr;')
          expect(content).to include('proxy_set_header X-Original-Forwarded-For $http_x_forwarded_for;')
          expect(content).to include('proxy_set_header X-Forwarded-Proto $scheme;')
          expect(content).to include('proxy_set_header X-Forwarded-Scheme $scheme;')
          expect(content).to include('proxy_set_header X-Scheme $scheme;')

          expect(content).to include('proxy_buffering off;')
          expect(content).to include('proxy_request_buffering on;')
          expect(content).to include('proxy_connect_timeout 5s;')
          expect(content).to include('proxy_send_timeout 60s;')
          expect(content).to include('proxy_read_timeout 60s;')
          expect(content).to include('proxy_max_temp_file_size 1024m;')
          expect(content).to include('proxy_redirect off;')
          expect(content).to include('proxy_intercept_errors off;')
        }
      end

      context 'when external url is not ssl-enabled' do
        let(:gitlab_kas_external_url) { 'ws://kas.gitlab.example.com' }

        it 'listens to port 80' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            gitlab_kas: { enable: true, listen_websocket: true },
            gitlab_kas_external_url: gitlab_kas_external_url
          )

          expect(chef_run).to render_file(http_conf['gitlab_kas']).with_content { |content|
            expect(content).to include('listen *:80')
            expect(content).to include('server_name kas.gitlab.example.com;')
          }
        end
      end
    end
  end

  context 'when relative URLs are used' do
    before do
      stub_gitlab_rb(gitlab_rails: { gitlab_relative_url: '/gitlab' })
    end

    it 'disables proxy cache for relative URLs' do
      expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
        expect(content).to include("location ~ ^/gitlab/api/v\\d {\n    proxy_cache off;")
      }
    end
  end

  context 'when hsts is disabled' do
    before do
      stub_gitlab_rb(nginx: { hsts_max_age: 0 })
    end
    it { is_expected.not_to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security "max-age=63072000" always;/) }

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
    it { is_expected.to render_file(gitlab_http_config).with_content(/gzip off;/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/gzip on;/) }

  context 'when include_subdomains is enabled' do
    before do
      stub_gitlab_rb(nginx: { hsts_include_subdomains: true })
    end

    it { is_expected.to render_file(gitlab_http_config).with_content(/add_header Strict-Transport-Security "max-age=63072000; includeSubdomains" always;/) }
  end

  context 'when max-age is set to 10' do
    before do
      stub_gitlab_rb(nginx: { hsts_max_age: 10 })
    end

    it { is_expected.to render_file(gitlab_http_config).with_content(/"max-age=10[^"]*"/) }
  end

  context 'when error log level is set to debug' do
    before do
      stub_gitlab_rb(nginx: { error_log_level: 'debug' })
    end
    it { is_expected.to render_file(gitlab_http_config).with_content(/error_log   \/var\/log\/gitlab\/nginx\/gitlab_error.log debug;/) }
  end

  it { is_expected.to render_file(gitlab_http_config).with_content(/error_log   \/var\/log\/gitlab\/nginx\/gitlab_error.log error;/) }

  context 'when NGINX RealIP module is configured' do
    before do
      stub_gitlab_rb(
        external_url: 'https://localhost',
        mattermost_external_url: 'https://mattermost.localhost',
        registry_external_url: 'https://registry.localhost',
        pages_external_url: 'https://pages.localhost',
        gitlab_kas_external_url: 'wss://kas.localhost',
        gitlab_kas: { listen_websocket: true }
      )
    end

    context 'when real_ip_header is configured' do
      before do
        stub_gitlab_rb(
          nginx: { real_ip_header: 'X-FAKE' },
          mattermost_nginx: { real_ip_header: 'X-FAKE' },
          registry_nginx: { real_ip_header: 'X-FAKE' },
          pages_nginx: { real_ip_header: 'X-FAKE' },
          gitlab_kas_nginx: { real_ip_header: 'X-FAKE' }
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
          pages_nginx: { real_ip_recursive: 'On' },
          gitlab_kas_nginx: { real_ip_recursive: 'On' }
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
          pages_nginx: { real_ip_trusted_addresses: %w(one two three) },
          gitlab_kas_nginx: { real_ip_trusted_addresses: %w(one two three) }
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

    context 'when proxy_protocol is enabled' do
      before do
        stub_gitlab_rb(
          nginx: { proxy_protocol: true },
          mattermost_nginx: { proxy_protocol: true },
          registry_nginx: { proxy_protocol: true },
          pages_nginx: { proxy_protocol: true },
          gitlab_kas_nginx: { proxy_protocol: true }
        )
      end

      it 'applies nginx proxy_protocol settings' do
        http_conf.each_value do |conf|
          expect(chef_run).to render_file(conf).with_content { |content|
            expect(content).to match(/listen .*:\d+ proxy_protocol/)
            expect(content).to include('real_ip_header proxy_protocol;')
            expect(content).to include('proxy_set_header X-Real-IP $proxy_protocol_addr;')
            expect(content).to include('proxy_set_header X-Forwarded-For $proxy_protocol_addr;')
          }
        end
      end
    end

    it 'does not set proxy_protocol settings by default' do
      http_conf.each_value do |conf|
        expect(chef_run).to render_file(conf).with_content { |content|
          expect(content).not_to match(/listen .*:\d+ proxy_protocol/)
          expect(content).not_to include('real_ip_header proxy_protocol;')
          expect(content).not_to include('proxy_set_header X-Real-IP $proxy_protocol_addr;')
          expect(content).not_to include('proxy_set_header X-Forwarded-For $proxy_protocol_addr;')
        }
      end
    end
  end

  context 'for proxy_custom_buffer_size' do
    before do
      stub_gitlab_rb(
        external_url: 'https://localhost',
        mattermost_external_url: 'https://mattermost.localhost',
        pages_external_url: 'https://pages.localhost',
        gitlab_kas_external_url: 'wss://kas.localhost',
        gitlab_kas: { listen_websocket: true }
      )
    end

    context 'when proxy_custom_buffer_size is set' do
      before do
        stub_gitlab_rb(
          nginx: { proxy_custom_buffer_size: '42k' },
          mattermost_nginx: { proxy_custom_buffer_size: '42k' },
          pages_nginx: { proxy_custom_buffer_size: '42k' },
          gitlab_kas_nginx: { proxy_custom_buffer_size: '42k' }
        )
      end

      it 'applies nginx proxy_custom_buffer_size settings for gitlab' do
        # the proxy_buffers and proxy_buffer_size are written in two places for gitlab
        expect(chef_run).to render_file(http_conf['gitlab']).with_content { |content|
          expect(content).to include('proxy_buffers 8 42k;').twice
          expect(content).to include('proxy_buffer_size 42k;').twice
        }
      end

      it 'applies nginx proxy_custom_buffer_size settings' do
        ['mattermost', 'pages', 'gitlab_kas'].each do |conf|
          expect(chef_run).to render_file(http_conf[conf]).with_content { |content|
            expect(content).to include('proxy_buffers 8 42k;')
            expect(content).to include('proxy_buffer_size 42k;')
          }
        end
      end
    end

    it 'does not set proxy_custom_buffer_size by default' do
      ['gitlab', 'mattermost', 'pages', 'gitlab_kas'].each do |conf|
        expect(chef_run).to render_file(http_conf[conf]).with_content { |content|
          expect(content).not_to include('proxy_buffers 8 42k;')
          expect(content).not_to include('proxy_buffer_size 42k;')
        }
      end
    end
  end

  context 'for namespace_in_path' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.localhost',
        pages_external_url: 'https://pages.localhost'
      )
    end

    it 'default gitlab_pages namespace_in_path setting is disabled' do
      expect(chef_run.node['gitlab_pages']['namespace_in_path']).to eql(false)
    end

    context 'when namespace_in_path is enabled in gitlab_pages' do
      before do
        stub_gitlab_rb(
          gitlab_pages: {
            namespace_in_path: true,
            access_control: true,
          }
        )
      end

      it 'applies nginx server_name without group for gitlab-pages' do
        expect(chef_run).to render_file(http_conf['pages']).with_content { |content|
          expect(content).to include('server {')
          expect(content).to include('server_name  ~^pages\.localhost$;')
          expect(content).to include('location / {')
          expect(content).to include('proxy_set_header Host $http_host;')
          # Below checks are to verify proper render entries are made
          expect(content).to include('proxy_http_version 1.1;')
          expect(content).to include('proxy_pass')
          expect(content).to include('disable_symlinks on;')
          expect(content).to include('server_tokens off;')
        }
      end
    end

    context 'when namespace_in_path is disabled in pages_nginx' do
      before do
        stub_gitlab_rb(
          gitlab_pages: { namespace_in_path: false }
        )
      end

      it 'applies nginx server_name with group for gitlab-pages' do
        expect(chef_run).to render_file(http_conf['pages']).with_content { |content|
          expect(content).to include('server {')
          expect(content).to include('server_name  ~^(?<group>.*)\.pages\.localhost$;')
          expect(content).to include('location / {')
          expect(content).to include('proxy_set_header Host $http_host;')
          # Below checks are to verify proper render entries are made
          expect(content).to include('proxy_http_version 1.1;')
          expect(content).to include('proxy_pass')
          expect(content).to include('disable_symlinks on;')
          expect(content).to include('server_tokens off;')
        }
      end
    end
  end

  include_examples "consul service discovery", "nginx", "nginx"

  context 'log directory and runit group' do
    context 'default values' do
      it_behaves_like 'enabled logged service', 'nginx', true, { log_directory_owner: 'root', log_directory_group: 'gitlab-www' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          nginx: {
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'configured logrotate service', 'nginx', 'root', 'fugee'
      it_behaves_like 'enabled logged service', 'nginx', true, { log_directory_owner: 'root', log_group: 'fugee' }
    end
  end

  def nginx_headers(additional_headers)
    basic_nginx_headers.merge(additional_headers)
  end
end

RSpec.describe 'gitlab::nginx with no total CPUs' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04-no-total-cpus.json')
  end

  let(:chef_run) do
    chef_runner.converge('gitlab::config', 'gitlab::nginx')
  end

  it 'sets worker_processes to 16' do
    expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/nginx.conf').with_content { |content|
      expect(content).to include("worker_processes 16;")
    }
  end
end
