require 'chef_helper'

describe 'gitlab::letsencrypt' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

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

    it 'sets redirect-http_to_https' do
      expect(node['gitlab']['nginx']['redirect_http_to_https']).to be_truthy
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
      expect(prod_cert).to notify('ruby[display_le_message]').to(:run)
    end
  end
end

# This should work standalone for renewal purposes
describe 'letsencrypt::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('letsencrypt::enable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      external_url: 'https://fakehost.example.com',
      letsencrypt: {
        enable: true,
      }
    )
  end

  it 'executes letsencrypt_certificate' do
    pending('not ready yet')
    expect(chef_run).to create_letsencrypt_certificate('fakehost.example.com')
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

  it 'reloads nginx' do
    pending('not ready yet')
    expect(chef_run).to run_execute('gitlab-ctl hup nginx')
  end

  it 'creates a staging certificate' do
    pending('not ready yet')
    expect(chef_run).to create_acme_certificate('staging').with(
      crt: '/etc/gitlab/ssl/fakehost.example.com.crt-staging',
      key: '/etc/gitlab/ssl/fakehost.example.com.key-staging',
      wwwroot: '/var/opt/gitlab/nginx/www'
    )
  end

  it 'creates a production certificate' do
    pending('not ready yet')
    expect(chef_run).to create_acme_certificate('production').with(
      crt: '/etc/gitlab/ssl/fakehost.example.com.crt',
      key: '/etc/gitlab/ssl/fakehost.example.com.key',
      wwwroot: '/var/opt/gitlab/nginx/www'
    )
  end
end
