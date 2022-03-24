RSpec.shared_examples 'enabled registry service' do
  it 'creates default set of directories' do
    expect(chef_run.node['registry']['dir'])
      .to eql('/var/opt/gitlab/registry')
    expect(chef_run.node['registry']['log_directory'])
      .to eql('/var/log/gitlab/registry')
    expect(chef_run.node['gitlab']['gitlab-rails']['registry_path'])
      .to eql('/var/opt/gitlab/gitlab-rails/shared/registry')

    expect(chef_run).to create_directory('/var/opt/gitlab/registry')
    expect(chef_run).to create_directory('/var/log/gitlab/registry').with(
      owner: 'registry',
      group: nil,
      mode: '0700'
    )
    expect(chef_run).to create_directory('/var/opt/gitlab/gitlab-rails/shared/registry').with(
      owner: 'registry',
      group: 'git',
      mode: '0770'
    )
  end

  it 'creates default user and group' do
    expect(chef_run.node['registry']['username'])
      .to eql('registry')
    expect(chef_run.node['registry']['group'])
      .to eql('registry')

    expect(chef_run).to create_account('Docker registry user and group').with(
      username: 'registry',
      groupname: 'registry',
      uid: nil,
      gid: nil,
      system: true,
      home: '/var/opt/gitlab/registry'
    )
  end

  it 'creates default self signed key-certificate pair' do
    expect(chef_run).to create_file('/var/opt/gitlab/registry/gitlab-registry.crt').with(
      user: 'registry',
      group: 'registry'
    )
    expect(chef_run).to create_file('/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key').with(
      user: 'git',
      group: 'git'
    )

    expect(chef_run).to render_file('/var/opt/gitlab/registry/gitlab-registry.crt')
      .with_content(/-----BEGIN CERTIFICATE-----/)
    expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key')
      .with_content(/-----BEGIN RSA PRIVATE KEY-----/)
  end

  it 'creates registry config.yml template' do
    expect(chef_run).to create_template('/var/opt/gitlab/registry/config.yml').with(
      owner: 'registry',
      group: nil,
      mode: '0644'
    )
    expect(chef_run).to(
      render_file('/var/opt/gitlab/registry/config.yml').with_content do |content|
        expect(content).to match(/version: 0.1/)
        expect(content).to match(/realm: .*\/jwt\/auth/)
        expect(content).to match(/addr: localhost:5000/)
        expect(content).to match(%r(storage: {"filesystem":{"rootdirectory":"/var/opt/gitlab/gitlab-rails/shared/registry"}))
        expect(content).to match(/health:\s*storagedriver:\s*enabled:\s*true/)
        expect(content).to match(/log:\s*level: info\s*formatter:\s*text/)
        expect(content).to match(/validation:\s*disabled: true$/)
        expect(content).not_to match(/^compatibility:/)
        expect(content).not_to match(/^middleware:/)
      end
    )
  end

  it 'populates default settings for svlogd' do
    expect(chef_run).to render_file('/opt/gitlab/sv/registry/log/run')
      .with_content(/exec svlogd -tt \/var\/log\/gitlab\/registry/)
  end

  it 'creates a default VERSION file and restarts service' do
    expect(chef_run).to create_version_file('Create version file for Registry').with(
      version_file_path: '/var/opt/gitlab/registry/VERSION',
      version_check_cmd: '/opt/gitlab/embedded/bin/registry --version'
    )

    expect(chef_run.version_file('Create version file for Registry')).to notify('runit_service[registry]').to(:restart)
  end

  it 'creates gitlab-rails config with default values' do
    expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(hash_including('registry_api_url' => 'http://localhost:5000'))
  end

  it 'sets default storage options' do
    expect(chef_run.node['registry']['storage']['filesystem'])
      .to eql('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
    expect(chef_run.node['registry']['storage']['cache'])
      .to eql('blobdescriptor' => 'inmemory')
    expect(chef_run.node['registry']['storage']['delete'])
      .to eql('enabled' => true)
  end
end
