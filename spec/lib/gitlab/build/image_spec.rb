require 'spec_helper'
require 'gitlab/build/image'

RSpec.describe Build::Image do
  ComponentImage = Class.new do
    extend Build::Image

    def self.gitlab_registry_image_name
      'my-project/my-image'
    end

    def self.dockerhub_image_name
      'my-image'
    end
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('CI_PROJECT_ID').and_return('20699')
    allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return('1234')
    allow(ENV).to receive(:[]).with('CI_REGISTRY').and_return('registry.com')
    allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.com/group/repo')
    allow(ENV).to receive(:[]).with('DOCKERHUB_USERNAME').and_return('john')
    allow(ENV).to receive(:[]).with('DOCKERHUB_PASSWORD').and_return('secret')
    allow(Build::Info).to receive(:docker_tag).and_return('9.0.0')
    allow(Gitlab::APIClient).to receive(:new).and_return(double(get_job_id: '999999'))
  end

  describe '.pull' do
    it 'creates an image from the local one' do
      expect(Docker::Image).to receive(:create).with(
        'fromImage' => "#{ComponentImage.gitlab_registry_image_address}:9.0.0"
      )

      ComponentImage.pull
    end
  end

  describe '.gitlab_registry_image_address' do
    it 'returns a correct image name' do
      expect(ComponentImage.gitlab_registry_image_address).to eq('registry.com/group/repo/my-project/my-image')
    end

    context 'with a tag given' do
      it 'returns a correct image name' do
        expect(ComponentImage.gitlab_registry_image_address(tag: 'mytag')).to eq('registry.com/group/repo/my-project/my-image:mytag')
      end
    end
  end

  describe '.tag_and_push_to_gitlab_registry' do
    it 'calls DockerOperations.authenticate and DockerOperations.tag_and_push' do
      expect(DockerOperations).to receive(:authenticate).with('gitlab-ci-token', '1234', 'registry.com')
      expect(DockerOperations).to receive(:tag_and_push).with(
        ComponentImage.gitlab_registry_image_address,
        ComponentImage.gitlab_registry_image_address,
        'latest',
        'foo'
      )

      ComponentImage.tag_and_push_to_gitlab_registry('foo')
    end
  end

  describe '.tag_and_push_to_dockerhub' do
    it 'calls DockerOperations.authenticate and DockerOperations.tag_and_push' do
      expect(DockerOperations).to receive(:authenticate).with('john', 'secret')
      expect(DockerOperations).to receive(:tag_and_push).with(
        ComponentImage.gitlab_registry_image_address,
        ComponentImage.dockerhub_image_name,
        '9.0.0',
        'foo'
      )

      ComponentImage.tag_and_push_to_dockerhub('foo')
    end

    context 'with a initial_tag given' do
      it 'calls DockerOperations.authenticate and DockerOperations.tag_and_push' do
        expect(DockerOperations).to receive(:authenticate).with('john', 'secret')
        expect(DockerOperations).to receive(:tag_and_push).with(
          ComponentImage.gitlab_registry_image_address,
          ComponentImage.dockerhub_image_name,
          'latest',
          'foo'
        )

        ComponentImage.tag_and_push_to_dockerhub('foo', initial_tag: 'latest')
      end
    end
  end

  describe '.write_release_file' do
    before do
      stub_env_var('CI_JOB_TOKEN', 'NOT-CI-JOB-TOKEN')
      stub_env_var('PACKAGECLOUD_REPO', 'download-package')
    end

    describe 'for builds in dev.gitlab.org' do
      before do
        stub_env_var('CI_API_V4_URL', 'https://dev.gitlab.org/api/v4')
        stub_env_var('CI_PROJECT_ID', '283')
        stub_env_var('CI_PIPELINE_ID', '12345')
      end

      describe 'for CE' do
        let(:release_file_content) do
          [
            "PACKAGECLOUD_REPO=download-package",
            "RELEASE_PACKAGE=gitlab-ce",
            "RELEASE_VERSION=12.121.12-ce.0",
            "DOWNLOAD_URL=https://dev.gitlab.org/api/v4/projects/283/jobs/999999/artifacts/pkg/ubuntu-jammy/gitlab-ce_12.121.12-ce.0_amd64.deb",
            "CI_JOB_TOKEN=NOT-CI-JOB-TOKEN\n"
          ].join("\n")
        end

        before do
          allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
          allow(Build::Info::Package).to receive(:release_version).and_return('12.121.12-ce.0')
        end

        it 'returns build version and iteration with env variable' do
          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end

      describe 'for EE' do
        let(:release_file_content) do
          [
            "PACKAGECLOUD_REPO=download-package",
            "RELEASE_PACKAGE=gitlab-ee",
            "RELEASE_VERSION=12.121.12-ee.0",
            "DOWNLOAD_URL=https://dev.gitlab.org/api/v4/projects/283/jobs/999999/artifacts/pkg/ubuntu-jammy/gitlab-ee_12.121.12-ee.0_amd64.deb",
            "CI_JOB_TOKEN=NOT-CI-JOB-TOKEN\n"
          ].join("\n")
        end

        before do
          allow(Build::Info::Package).to receive(:release_version).and_return('12.121.12-ee.0')
          stub_env_var('ee', 'true')
        end

        it 'returns build version and iteration with env variable' do
          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end
    end

    describe 'for builds in gitlab.com' do
      before do
        stub_env_var('CI_API_V4_URL', 'https://gitlab.com/api/v4')
        stub_env_var('CI_PROJECT_ID', '20699')
        stub_env_var('CI_PIPELINE_ID', '12345')
      end

      describe 'for CE' do
        let(:release_file_content) do
          [
            "PACKAGECLOUD_REPO=download-package",
            "RELEASE_PACKAGE=gitlab-ce",
            "RELEASE_VERSION=12.121.12-ce.0",
            "DOWNLOAD_URL=https://gitlab.com/api/v4/projects/20699/jobs/999999/artifacts/pkg/ubuntu-jammy/gitlab.deb",
            "CI_JOB_TOKEN=NOT-CI-JOB-TOKEN\n"
          ].join("\n")
        end

        before do
          allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
          allow(Build::Info::Package).to receive(:release_version).and_return('12.121.12-ce.0')
        end

        it 'returns build version and iteration with env variable' do
          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end

      describe 'for EE' do
        let(:release_file_content) do
          [
            "PACKAGECLOUD_REPO=download-package",
            "RELEASE_PACKAGE=gitlab-ee",
            "RELEASE_VERSION=12.121.12-ee.0",
            "DOWNLOAD_URL=https://gitlab.com/api/v4/projects/20699/jobs/999999/artifacts/pkg/ubuntu-jammy/gitlab.deb",
            "CI_JOB_TOKEN=NOT-CI-JOB-TOKEN\n"
          ].join("\n")
        end

        before do
          allow(Build::Info::Package).to receive(:release_version).and_return('12.121.12-ee.0')
          stub_env_var('ee', 'true')
        end

        it 'returns build version and iteration with env variable' do
          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end
    end
  end
end
