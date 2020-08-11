require 'chef_helper'

RSpec.describe 'gitlab::users' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::users') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default attributes' do
    it 'creates gitlab user' do
      account_params = {
        username: 'git',
        groupname: 'git',
        home: '/var/opt/gitlab',
        shell: '/bin/sh'
      }

      expect(chef_run).to create_directory('/var/opt/gitlab')
      expect(chef_run).to create_account('GitLab user and group').with(account_params)
    end

    it 'creates .gitconfig' do
      template_params = {
        owner: 'git',
        group: 'git',
        mode: '0644'
      }

      expect(chef_run).to create_template('/var/opt/gitlab/.gitconfig').with(template_params)
      expect(chef_run).to render_file('/var/opt/gitlab/.gitconfig').with_content { |content|
        expect(content).to match(/name = GitLab/)
        expect(content).to match(/email = gitlab@fauxhai.local/)
        expect(content).to match(/fsyncObjectFiles = true/)
      }
    end

    it 'creates .bundle directory' do
      directory_params = {
        owner: 'git',
        group: 'git'
      }

      expect(chef_run).to create_directory('/var/opt/gitlab/.bundle').with(directory_params)
    end
  end
end
