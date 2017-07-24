require_relative '../../files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb'
require 'chef_helper'

describe GitlabRails do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when a service role is activated' do
    before do
      stub_gitlab_rb(redis_master_role: { enable: true })
      allow(Services).to receive(:disable_group).and_call_original
    end

    it 'disables other services' do
      expect(GitlabRails).to receive(:disable_services_roles).and_call_original
      expect(Services).to receive(:disable_group).with('rails')

      chef_run
    end
  end

  context 'when a behavior role is defined' do
    before do
      stub_gitlab_rb(geo_secondary: { enable: true })
    end

    it 'does not disable other services' do
      expect(GitlabRails).not_to receive(:disable_services_roles)

      chef_run
    end
  end
end
