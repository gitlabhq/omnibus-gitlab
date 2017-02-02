require 'chef_helper'

describe 'gitlab::gitlab-healthcheck' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'correctly renders out the healthcheck-rc file using localhost when nginx is enabled' do
    stub_gitlab_rb(external_url: 'http://gitlabe.example.com')
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{host='http://localhost'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{port='80'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{path='/help'})
  end

  it 'correctly renders out the healthcheck-rc file when using hostname when nginx is disabled' do
    stub_gitlab_rb(external_url: 'http://gitlabe.example.com', nginx: { enable: false })
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{host='http://gitlabe.example.com'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{port='80'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{path='/help'})
  end

  it 'correctly renders out the healthcheck-rc file when using https' do
    stub_gitlab_rb(external_url: 'https://gitlabe.example.com')
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{host='https://localhost'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{port='443'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{path='/help'})
  end

  it 'correctly renders out the healthcheck-rc file when using custom port' do
    stub_gitlab_rb(external_url: 'http://gitlabe.example.com:8080')
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{host='http://localhost'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{port='8080'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{path='/help'})
  end

  it 'correctly renders out the healthcheck-rc file when using a relative url' do
    stub_gitlab_rb(external_url: 'http://gitlabe.example.com/custom')
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{host='http://localhost'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{port='80'})
    expect(chef_run).to render_file("/opt/gitlab/etc/gitlab-healthcheck-rc").with_content(%r{path='/custom/help'})
  end
end
