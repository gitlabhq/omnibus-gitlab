require 'chef_helper'

RSpec.describe 'postgresql::user' do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'postgresql::user') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'includes postgresql::directory_locations recipe' do
    expect(chef_run).to include_recipe('postgresql::directory_locations')
  end

  context 'with default attributes' do
    it 'creates postgresql user and groups' do
      account_params = {
        username: 'gitlab-psql',
        groupname: 'gitlab-psql',
        home: '/var/opt/gitlab/postgresql',
        shell: '/bin/sh'
      }

      expect(chef_run).to create_account('Postgresql user and group').with(account_params)
    end

    it 'creates postgresql base directory' do
      directory_params = {
        owner: 'gitlab-psql',
        mode: '0755',
        recursive: true
      }
      expect(chef_run).to create_directory('/var/opt/gitlab/postgresql').with(directory_params)
    end

    it 'creates a .profile with bundled PostgreSQL PATH' do
      file_params = {
        owner: 'gitlab-psql',
        content: %r{PATH=/opt/gitlab/embedded/bin:/opt/gitlab/bin:\$PATH}
      }

      expect(chef_run).to create_file('/var/opt/gitlab/postgresql/.profile').with(file_params)
    end
  end

  context 'when using custom values for directories' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'postgresql::user') }

    before do
      stub_gitlab_rb(
        postgresql: {
          home: '/mypghomedir'
        })
    end

    it 'creates postgresql user and groups' do
      account_params = {
        username: 'gitlab-psql',
        groupname: 'gitlab-psql',
        home: '/mypghomedir',
        shell: '/bin/sh'
      }

      expect(chef_run).to create_account('Postgresql user and group').with(account_params)
    end

    it 'creates postgresql base directory' do
      directory_params = {
        owner: 'gitlab-psql',
        mode: '0755',
        recursive: true
      }
      expect(chef_run).to create_directory('/mypghomedir').with(directory_params)
    end

    it 'creates necessary directories' do
      expect(chef_run).to create_directory('/mypghomedir').with(owner: 'gitlab-psql', mode: '0755', recursive: true)
    end
  end
end
