require 'spec_helper'
require 'gitlab/build/info/deploy'

RSpec.describe Build::Info::Deploy do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.environment' do
    before do
      allow(ENV).to receive(:[]).with('PATCH_DEPLOY_ENVIRONMENT').and_return('patch')
      allow(ENV).to receive(:[]).with('RELEASE_DEPLOY_ENVIRONMENT').and_return('r')
    end

    context 'on RC tag' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(true)
      end
      it 'returns the patch-deploy environment' do
        expect(described_class.environment).to eq('patch')
      end
    end

    context 'on latest tag' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)
      end
      it 'returns the release-deploy environment' do
        expect(described_class.environment).to eq('r')
      end
    end

    context 'when unable to determine the desired env' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(false)
      end
      it 'it returns nil' do
        expect(described_class.environment).to eq(nil)
      end
    end
  end
end
