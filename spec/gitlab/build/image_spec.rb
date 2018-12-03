require 'spec_helper'
require 'gitlab/build/image'

describe Build::Image do
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
    allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return('1234')
    allow(ENV).to receive(:[]).with('CI_REGISTRY').and_return('registry.com')
    allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.com/group/repo')
    allow(ENV).to receive(:[]).with('DOCKERHUB_USERNAME').and_return('john')
    allow(ENV).to receive(:[]).with('DOCKERHUB_PASSWORD').and_return('secret')
    allow(Build::Info).to receive(:docker_tag).and_return('9.0.0')
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
    describe 'with triggered build' do
      let(:release_file) do
        [
          "PACKAGECLOUD_REPO=download-package",
          "RELEASE_VERSION=12.121.12-ce.1",
          "DOWNLOAD_URL=https://gitlab.com/api/v4/projects/1/jobs/1/artifacts/pkg/ubuntu-xenial/gitlab.deb",
          "TRIGGER_PRIVATE_TOKEN=NOT-PRIVATE-TOKEN\n"
        ]
      end

      before do
        stub_env_var('PACKAGECLOUD_REPO', 'download-package')
        stub_env_var('TRIGGER_PRIVATE_TOKEN', 'NOT-PRIVATE-TOKEN')
        stub_env_var('CI_PROJECT_ID', '1')
        stub_env_var('CI_PIPELINE_ID', '2')
        allow(Build::Info).to receive(:release_version).and_return('12.121.12-ce.1')
        allow(Build::Info).to receive(:fetch_artifact_url).with('1', '2').and_return('1')
      end

      describe 'for CE' do
        before do
          allow(Build::Info).to receive(:package).and_return('gitlab-ce')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ce').join("\n")

          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end

      describe 'for EE' do
        before do
          allow(Build::Info).to receive(:package).and_return('gitlab-ee')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ee').join("\n")

          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end

      describe 'with regular build' do
        let(:s3_download_link) { 'https://downloads-packages.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_12.121.12-ce.1_amd64.deb' }

        let(:release_file) do
          [
            "RELEASE_VERSION=12.121.12-ce.1",
            "DOWNLOAD_URL=#{s3_download_link}\n",
          ]
        end

        before do
          stub_env_var('PACKAGECLOUD_REPO', '')
          stub_env_var('TRIGGER_PRIVATE_TOKEN', '')
          stub_env_var('CI_PROJECT_ID', '')
          stub_env_var('CI_PIPELINE_ID', '')
          allow(Build::Check).to receive(:on_tag?).and_return(true)
          allow(Build::Info).to receive(:package).and_return('gitlab-ee')
          allow(ComponentImage).to receive(:release_version).and_return('12.121.12-ce.1')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(0, 'RELEASE_PACKAGE=gitlab-ee').join("\n")

          expect(ComponentImage.write_release_file).to eq(release_file_content)
        end
      end
    end
  end
end
