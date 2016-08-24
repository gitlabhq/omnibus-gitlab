require 'chef_helper'

describe 'nginx' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  let(:basic_nginx_headers) do
    {
      "Host" => "$http_host",
      "X-Real-IP" => "$remote_addr",
      "X-Forwarded-Proto" => "http",
      "X-Forwarded-For" => "$proxy_add_x_forwarded_for"
    }
  end

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when http external urls are being used' do
    before do
      stub_gitlab_rb(
        external_url: 'http://localhost',
        mattermost_external_url: 'http://mattermost.localhost',
        registry_external_url: 'http://registry.localhost'
      )
    end

    it 'properly sets the default nginx proxy headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to eql(basic_nginx_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to eql(nginx_headers({
        "X-Frame-Options" => "SAMEORIGIN",
        "Upgrade" => "$http_upgrade",
        "Connection" => "$connection_upgrade"
      }))
    end

    it 'supports overriding default nginx headers' do
      expect_headers = nginx_headers({ "Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp" })
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } },
        "mattermost_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } },
        "registry_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } }
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
        registry_external_url: 'https://registry.localhost'
      )
    end

    it 'properly sets the default nginx proxy ssl forward headers' do
      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to eql(nginx_headers({
        "X-Forwarded-Proto" => "https",
        "X-Forwarded-Ssl" => "on"
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
    end

    it 'supports overriding default nginx headers' do
      expect_headers = nginx_headers({"Host" => "nohost.example.com", "X-Forwarded-Proto" => "ftp", "X-Forwarded-Ssl" => "on" })
      stub_gitlab_rb(
        "nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } },
        "mattermost_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } },
        "registry_nginx" => { proxy_set_headers: { "Host" => "nohost.example.com",  "X-Forwarded-Proto" => "ftp" } }
      )

      expect(chef_run.node['gitlab']['nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['mattermost-nginx']['proxy_set_headers']).to include(expect_headers)
      expect(chef_run.node['gitlab']['registry-nginx']['proxy_set_headers']).to include(expect_headers)
    end
  end

  def nginx_headers(additional_headers)
    basic_nginx_headers.merge(additional_headers)
  end
end
