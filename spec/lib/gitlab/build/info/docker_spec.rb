require 'spec_helper'
require 'gitlab/build/info/docker'

RSpec.describe Build::Info::Docker do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns package version when regular build' do
      expect(described_class.tag).to eq('12.121.12-ce.1')
    end

    it 'respects IMAGE_TAG if set' do
      allow(ENV).to receive(:[]).with('IMAGE_TAG').and_return('foobar')
      expect(described_class.tag).to eq('foobar')
    end
  end
end
