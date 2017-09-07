require 'chef_helper'

describe 'GitLabRoles' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Services).to receive(:enable_group).and_call_original
  end

  describe 'DefaultRole' do
    before do
      allow(DefaultRole).to receive(:load_role).and_call_original
    end

    it 'enables the default services when no other roles are active' do
      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, anything).once
    end

    it 'leaves the default services disabled when another role is active' do
      stub_gitlab_rb(application_role: { enable: true })

      Gitlab.load_roles

      expect(DefaultRole).to have_received(:load_role)
      expect(Services).not_to have_received(:enable_group).with(Services::DEFAULT_GROUP, anything)
    end

    it 'leaves rails roles disabled when requested to maintain backward compat' do
      stub_gitlab_rb(gitlab_rails: { enable: false })

      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, hash_including(except: ['rails'])).once
    end
  end

  describe 'ApplicationRole' do
    before do
      allow(ApplicationRole).to receive(:load_role).and_call_original
    end

    it 'enables the rails services' do
      stub_gitlab_rb(application_role: { enable: true })

      Gitlab.load_roles

      expect(ApplicationRole).to have_received(:load_role)
      expect(Gitlab['gitlab_rails']['enable']).to eq true
      expect(Services).to have_received(:enable_group).with('rails').once
    end
  end
end
