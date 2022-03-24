require 'chef_helper'

RSpec.describe 'gitlab::gitlab-healthcheck' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'nginx is enabled' do
    before do
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'correctly renders the healthcheck-rc file' do
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='http://localhost:80/help'})
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{flags='--insecure'})
    end

    it 'correctly renders out the healthcheck-rc file when using https' do
      stub_gitlab_rb(external_url: 'https://gitlab.example.com')
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='https://localhost:443/help'})
    end

    it 'correctly renders out the healthcheck-rc file when using custom port' do
      stub_gitlab_rb(external_url: 'http://gitlab.example.com:8080')
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='http://localhost:8080/help'})
    end

    it 'correctly renders out the healthcheck-rc file when using a relative url' do
      stub_gitlab_rb(external_url: 'http://gitlab.example.com/custom')
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='http://localhost:80/custom/help'})
    end
  end

  context 'nginx is disabled' do
    before do
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'correctly renders the healthcheck-rc file using workhorse' do
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='http://localhost/help'})
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{flags='--unix-socket /var/opt/gitlab/gitlab-workhorse/sockets/socket'})
    end

    it 'correctly renders healthcheck-rc file using workhorse on a port' do
      stub_gitlab_rb(
        gitlab_workhorse: { listen_network: 'tcp', listen_addr: 'localhost:9191' }
      )
      expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
        .with_content(%r{url='http://localhost:9191/help'})
    end

    it 'does not render the healthcheck-rc file when workhorse workhorse is disabled' do
      stub_gitlab_rb(nginx: { enable: false }, gitlab_workhorse: { enable: false })
      expect(chef_run).not_to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc")
    end
  end
end
