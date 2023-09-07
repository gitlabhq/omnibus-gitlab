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
      allow(Build::Info::Package).to receive(:name).and_return("gitlab-ee")
      allow(::Gitlab::Version).to receive(:sources_channel).and_return('remote')

      expect(described_class).to receive(:system).with(*%w[rm -rf /tmp/gitlab])
      expect(described_class).to receive(:system).with(*%w[git clone git@dev.gitlab.org:gitlab/gitlab-ee.git /tmp/gitlab])

      Build::QA.clone_gitlab_rails
    end
  end

  describe '.checkout_gitlab_rails' do
    it 'calls the git command' do
      allow(Build::Info::Package).to receive(:name).and_return("gitlab-ee")
      allow(Gitlab::Version).to receive(:new).with('gitlab-rails-ee').and_return(double(print: 'v9.0.0'))
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      stub_is_auto_deploy(false)

      expect(described_class).to receive(:system).with(*%w[git --git-dir=/tmp/gitlab/.git --work-tree=/tmp/gitlab checkout --quiet v9.0.0])

      Build::QA.checkout_gitlab_rails
    end
  end
end
