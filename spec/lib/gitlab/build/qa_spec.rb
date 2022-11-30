require 'spec_helper'
require 'gitlab/build/qa'

RSpec.describe Build::QA do
  before do
    allow(ENV).to receive(:[]).and_call_original
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.repo_path' do
    it 'returns correct location' do
      expect(described_class.repo_path).to eq("/tmp/gitlab")
    end
  end

  describe '.get_gitlab_repo' do
    it 'returns correct location' do
      allow(Build::QA).to receive(:clone_gitlab_rails).and_return(true)
      allow(Build::QA).to receive(:checkout_gitlab_rails).and_return(true)

      expect(described_class.get_gitlab_repo).to eq("/tmp/gitlab")
    end
  end

  describe '.clone_gitlab_rails' do
    it 'calls the git command' do
      allow(Build::Info).to receive(:package).and_return("gitlab-ee")
      allow(::Gitlab::Version).to receive(:sources_channel).and_return('remote')

      expect(described_class).to receive(:system).with(*%w[rm -rf /tmp/gitlab])
      expect(described_class).to receive(:system).with(*%w[git clone git@dev.gitlab.org:gitlab/gitlab-ee.git /tmp/gitlab])

      Build::QA.clone_gitlab_rails
    end
  end

  describe '.checkout_gitlab_rails' do
    it 'calls the git command' do
      allow(Build::Info).to receive(:package).and_return("gitlab-ee")
      allow(Build::Check).to receive(:on_tag?).and_return(true)

      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:read).with(%r{/VERSION$}).and_return("9.0.0")
      stub_is_auto_deploy(false)

      expect(described_class).to receive(:system).with(*%w[git --git-dir=/tmp/gitlab/.git --work-tree=/tmp/gitlab checkout --quiet v9.0.0])

      Build::QA.checkout_gitlab_rails
    end
  end

  describe '.get_gitlab_rails_sha' do
    it 'returns the correct stable tag' do
      allow(Build::Check).to receive(:on_tag?).and_return(true)

      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:read).with(%r{/VERSION$}).and_return("9.0.0")
      stub_is_auto_deploy(false)

      expect(Build::QA.get_gitlab_rails_sha).to eq("v9.0.0")
    end

    it 'returns the correct auto-deploy commit sha' do
      allow(Build::Check).to receive(:on_tag?).and_return(true)

      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:read).with(%r{/VERSION$}).and_return("bebc7c1e290074863e0d2621b3a4c4c7bdb072ae")
      stub_is_auto_deploy(true)

      expect(Build::QA.get_gitlab_rails_sha).to eq("bebc7c1e290074863e0d2621b3a4c4c7bdb072ae")
    end
  end
end
