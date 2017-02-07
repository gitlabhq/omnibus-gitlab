require 'chef_helper'

describe 'gitlab-ee::ssh_keys' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(ssh_keygen)).converge('gitlab-ee::ssh_keys') }

  context 'when no ssh key exists' do
    it 'creates ssh keys for the git user' do
      expect(chef_run).to create_ssh_key('/var/opt/gitlab/.ssh/id_rsa')
    end
  end

  context 'when no .ssh directory exists' do
    it 'creates .ssh directory when user and group exists' do
      expect_any_instance_of(SSHKeygen::Helper).to receive(:user_and_group_exists?) { true }
      expect(chef_run).to create_directory('/var/opt/gitlab/.ssh')
    end

    it 'does not create .ssh directory when user or group does no exist' do
      expect_any_instance_of(SSHKeygen::Helper).to receive(:user_and_group_exists?) { false }
      expect(chef_run).not_to create_directory('/var/opt/gitlab/.ssh')
    end
  end
end
