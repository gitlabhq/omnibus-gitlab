require 'chef_helper'

describe 'gitlab-ee::ssh_keys' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab-ee::ssh_keys') }

  context 'when no ssh key exists' do
    it 'creates ssh keys for the git user' do
      expect(chef_run).to create_ssh_key('/var/opt/gitlab/.ssh/id_rsa')
    end
  end
end
