require 'spec_helper'
require 'gitlab/build/gitlab_image'

RSpec.describe Build::GitlabImage do
  before do
    allow(Build::Info).to receive(:package).and_return('gitlab-ce')
  end

  describe '.dockerhub_image_name' do
    it 'returns a correct image name' do
      expect(described_class.dockerhub_image_name).to eq('gitlab/gitlab-ce')
    end
  end

  describe '.gitlab_registry_image_name' do
    it 'returns a correct image name' do
      expect(described_class.gitlab_registry_image_name).to eq('gitlab-ce')
    end
  end
end
