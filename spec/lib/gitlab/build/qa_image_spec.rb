require 'spec_helper'
require 'gitlab/build/qa_image'

RSpec.describe Build::QAImage do
  before do
    allow(Build::GitlabImage).to receive(:dockerhub_image_name).and_return('gitlab/gitlab-ce')
    allow(Build::GitlabImage).to receive(:gitlab_registry_image_name).and_return('gitlab-ce')

    allow(Gitlab::Util).to receive(:get_env).and_call_original

    allow(Gitlab::Util).to receive(:get_env).with('CI_JOB_TOKEN').and_return('dummy-token')
    allow(Gitlab::Util).to receive(:get_env).with('CI_REGISTRY').and_return('registry.gitlab.com')
    allow(Gitlab::Util).to receive(:get_env).with('CI_REGISTRY_IMAGE').and_return('registry.gitlab.com/gitlab-org/omnibus-gitlab')

    allow(Gitlab::Util).to receive(:get_env).with('DOCKERHUB_USERNAME').and_return('dummy-dockerhub-username')
    allow(Gitlab::Util).to receive(:get_env).with('DOCKERHUB_PASSWORD').and_return('dummy-dockerhub-password')
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

  describe '.copy_image_to_omnibus_registry' do
    before do
      allow(Build::Info).to receive(:qa_image).and_return('registry.gitlab.com/gitlab-org/gitlab/gitlab-ce-qa:1234567890')

      allow(SkopeoHelper).to receive(:login).and_return(true)
      allow(SkopeoHelper).to receive(:copy_image).and_return(true)
    end

    it 'logs in to the gitlab registry' do
      expect(SkopeoHelper).to receive(:login).with('gitlab-ci-token', 'dummy-token', 'registry.gitlab.com')

      described_class.copy_image_to_omnibus_registry('foobar')
    end

    it 'copies the image from gitlab rails registry to omnibus gitlab registry' do
      expect(SkopeoHelper).to receive(:copy_image).with('registry.gitlab.com/gitlab-org/gitlab/gitlab-ce-qa:1234567890', 'registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce-qa:foobar')

      described_class.copy_image_to_omnibus_registry('foobar')
    end
  end

  describe '.copy_image_to_dockerhub' do
    before do
      allow(Build::Info).to receive(:qa_image).and_return('registry.gitlab.com/gitlab-org/gitlab/gitlab-ce-qa:1234567890')

      allow(SkopeoHelper).to receive(:login).and_return(true)
      allow(SkopeoHelper).to receive(:copy_image).and_return(true)
    end

    it 'logs in to both the registries' do
      expect(SkopeoHelper).to receive(:login).with('gitlab-ci-token', 'dummy-token', 'registry.gitlab.com')
      expect(SkopeoHelper).to receive(:login).with('dummy-dockerhub-username', 'dummy-dockerhub-password', 'docker.io')

      described_class.copy_image_to_dockerhub('nightly')
    end

    it 'copies the image from gitlab rails registry to dockerhub' do
      expect(SkopeoHelper).to receive(:copy_image).with('registry.gitlab.com/gitlab-org/gitlab/gitlab-ce-qa:1234567890', 'gitlab/gitlab-ce-qa:nightly')

      described_class.copy_image_to_dockerhub('nightly')
    end
  end
end
