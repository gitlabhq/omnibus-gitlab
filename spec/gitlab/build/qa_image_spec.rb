require 'spec_helper'
require 'gitlab/build/qa_image'

describe Build::QAImage do
  before do
    allow(Build::GitlabImage).to receive(:dockerhub_image_name).and_return('gitlab/gitlab-ce')
    allow(Build::GitlabImage).to receive(:gitlab_registry_image_name).and_return('gitlab-ce')
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
