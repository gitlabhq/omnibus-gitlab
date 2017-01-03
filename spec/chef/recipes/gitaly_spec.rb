require 'chef_helper'

describe 'gitlab::gitaly' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when gitaly is enabled' do
    before do
      stub_gitlab_rb(gitaly: { enable: true })
    end

    it_behaves_like "enabled runit service", "gitaly", "root", "root"
  end

  context 'when gitaly is disabled' do
    before do
      stub_gitlab_rb(gitaly: { enable: false })
    end

    it_behaves_like "disabled runit service", "gitaly"
  end
end
