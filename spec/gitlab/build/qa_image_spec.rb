require_relative '../../../lib/gitlab/build/qa_image'
require 'chef_helper'

describe Build::QAImage do
  before do
    allow(Build::Image).to receive(:dockerhub_image_name).and_return('gitlab/gitlab-ce')
    allow(Build::Image).to receive(:gitlab_registry_image_name).and_return('gitlab-ce')
    allow(ENV).to receive(:[]).with('CI_REGISTRY').and_return('registry.com')
    allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.com/group/repo')
  end

  describe '.dockerhub_image_name' do
    it 'returns a correct image name' do
      expect(described_class.dockerhub_image_name).to eq('gitlab/gitlab-ce-qa')
    end
  end

  describe '.gitlab_registry_image_name' do
    it 'returns a correct image name' do
      expect(described_class.gitlab_registry_image_name).to eq('gitlab-ce-qa')
    end
  end
end
