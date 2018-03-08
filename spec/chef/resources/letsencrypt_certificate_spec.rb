require 'chef_helper'

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
      fullchain: '/etc/gitlab/ssl/fakehost.example.com.crt-staging',
      key: '/etc/gitlab/ssl/fakehost.example.com.key-staging',
      wwwroot: '/var/opt/gitlab/nginx/www',
      endpoint: 'https://acme-staging.api.letsencrypt.org/',
      sensitive: true
    )
  end

  it "updates the node['acme']['private_key'] attribute" do
    expect(chef_run).to run_ruby_block('reset private key')
  end

  it 'creates a production certificate' do
    expect(chef_run).to create_acme_certificate('production').with(
      fullchain: '/etc/gitlab/ssl/fakehost.example.com.crt',
      key: '/etc/gitlab/ssl/fakehost.example.com.key',
      wwwroot: '/var/opt/gitlab/nginx/www',
      sensitive: true
    )
  end

  it 'reloads nginx' do
    prod_cert = chef_run.acme_certificate('production')
    expect(prod_cert).to notify('execute[reload nginx]').to(:run)
  end

  context 'with extra options' do
    before do
      stub_gitlab_rb(
        external_url: 'https://fakehost.example.com',
        letsencrypt: {
          enable: true,
          alt_names: %w(one.example.com two.example.com),
          contact_emails: %w(foo@bar.com one@two.com)
        }
      )
    end

    it 'adds alt_names to the certificate resource' do
      expect(chef_run).to create_acme_certificate('production').with(
        alt_names: %w(one.example.com two.example.com),
        contact: %w(mailto:foo@bar.com mailto:one@two.com)
      )
    end
  end
end
