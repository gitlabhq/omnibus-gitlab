require 'chef_helper'

describe 'gitlab::letsencrypt' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

  let(:redirect_block) do
    <<-EOF
server {
  listen *:80;

  server_name fakehost.example.com;
  server_tokens off; ## Don't show the nginx version number, a security best practice

  location /.well-known {
    root /var/opt/gitlab/nginx/www/.well-known;
  }

  location / {
    return 301 https://fakehost.example.com:443$request_uri;
  }

  access_log  /var/log/gitlab/nginx/gitlab_access.log gitlab_access;
  error_log   /var/log/gitlab/nginx/gitlab_error.log;
}
   EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'default' do
    it 'does not run' do
      expect(chef_run).not_to include_recipe('letsencrypt::enable')
    end
  end

  context 'enabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://fakehost.example.com',
        letsencrypt: {
          enable: true,
        }
      )
    end

    it 'is included' do
      expect(chef_run).to include_recipe('letsencrypt::enable')
    end

    it 'Updates nginx configuration' do
      expect(node['gitlab']['nginx']['redirect_http_to_https']).to be_truthy
      expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-http.conf')
        .with_content(redirect_block)
    end

    it 'uses http authorization by default' do
      expect(chef_run).to include_recipe('letsencrypt::http_authorization')
    end

    it 'creates a self signed certificate' do
      expect(chef_run).to create_acme_selfsigned('fakehost.example.com').with(
        crt: '/etc/gitlab/ssl/fakehost.example.com.crt',
        key: '/etc/gitlab/ssl/fakehost.example.com.key',
        chain: '/etc/gitlab/ssl/chain.pem'
      )
    end

    it 'creates a letsencrypt certificate' do
      expect(chef_run).to create_letsencrypt_certificate('fakehost.example.com').with(
        crt: '/etc/gitlab/ssl/fakehost.example.com.crt',
        key: '/etc/gitlab/ssl/fakehost.example.com.key',
        chain: '/etc/gitlab/ssl/chain.pem'
      )
    end

    it 'warns the user' do
      prod_cert = chef_run.letsencrypt_certificate('fakehost.example.com')
      expect(prod_cert).to notify('ruby_block[display_le_message]').to(:run)
    end
  end
end

# This should work standalone for renewal purposes
describe 'letsencrypt::enable' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['gitlab']['external-url'] = 'https://standalone.fakehost.com'
      node.normal['gitlab']['nginx']['ssl_certificate'] = '/fake/path/cert.crt'
      node.normal['gitlab']['nginx']['ssl_certificate_key'] = '/fake/path/cert.key'
    end.converge('letsencrypt::enable')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'executes letsencrypt_certificate' do
    expect(chef_run).to create_letsencrypt_certificate('standalone.fakehost.com')
  end
end

# Test just the LWRP
describe 'gitlab::letsencrypt' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: %(letsencrypt_certificate)).converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      external_url: 'https://fakehost.example.com',
      letsencrypt: {
        enable: true,
      }
    )
  end

  it 'creates a staging certificate' do
    expect(chef_run).to create_acme_certificate('staging').with(
      crt: '/etc/gitlab/ssl/fakehost.example.com.crt-staging',
      key: '/etc/gitlab/ssl/fakehost.example.com.key-staging',
      wwwroot: '/var/opt/gitlab/nginx/www',
      endpoint: 'https://acme-staging.api.letsencrypt.org/'
    )
  end

  it 'creates a production certificate' do
    expect(chef_run).to create_acme_certificate('production').with(
      crt: '/etc/gitlab/ssl/fakehost.example.com.crt',
      key: '/etc/gitlab/ssl/fakehost.example.com.key',
      wwwroot: '/var/opt/gitlab/nginx/www'
    )
  end

  it 'reloads nginx' do
    expect(chef_run).to run_execute('gitlab-ctl hup nginx')
  end
end
