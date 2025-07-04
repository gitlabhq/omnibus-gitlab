require 'spec_helper'

RSpec.describe 'docker', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/docker_tasks'
  end

  describe 'docker:build:image' do
    before do
      Rake::Task['docker:build:image'].reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    it 'calls build command with correct parameters' do
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.com/group/repo')
      allow(ENV).to receive(:[]).with('UBUNTU_IMAGE').and_return('ubuntu:stable')
      allow(Build::Info::Docker).to receive(:tag).and_return('9.0.0')
      allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
      allow(Build::GitlabImage).to receive(:write_release_file).and_return(true)
      allow(File).to receive(:expand_path).and_return('/tmp/omnibus-gitlab/lib/gitlab/tasks/docker_tasks.rake')

      allow(DockerHelper).to receive(:authenticate).and_return(true)
      allow(DockerHelper).to receive(:build).and_return(true)
      allow(DockerHelper).to receive(:create_builder).and_return(true)

      expect(DockerHelper).to receive(:build)
        .with('/tmp/omnibus-gitlab/docker', 'registry.com/group/repo/gitlab-ce', '9.0.0', buildargs: ['BASE_IMAGE=ubuntu:stable'])
      Rake::Task['docker:build:image'].invoke
    end
  end

  describe 'docker:push' do
    let(:dummy_image) { Docker::Image.new(Docker::Connection.new("test", {}), "id" => "test") }
    let(:dummy_creds) { { username: "test", password: "test" } }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('dev.gitlab.org:5005/gitlab/omnibus-gitlab')
      allow(ENV).to receive(:[]).with('CI_COMMIT_REF_SLUG').and_return('foo-bar')
      allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
      allow(Build::Info::Docker).to receive(:tag).and_return('9.0.0')
      allow(DockerOperations).to receive(:authenticate).and_return(true)
      allow(Docker::Image).to receive(:get).and_return(dummy_image)
      allow(Docker).to receive(:creds).and_return(dummy_creds)
      allow(dummy_image).to receive(:tag).and_return(true)
      allow(SkopeoHelper).to receive(:login).and_return(true)
      allow(SkopeoHelper).to receive(:copy_image).and_return(true)
    end

    describe 'docker:push:stable' do
      before do
        Rake::Task['docker:push:stable'].reenable
        stub_env_var('PUBLIC_IMAGE_ARCHIVE_REGISTRY', 'registry.gitlab.com')
        stub_env_var('PUBLIC_IMAGE_ARCHIVE_REGISTRY_PATH', 'foobar/public-image-archive')
      end

      it 'pushes images to dockerhub' do
        expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:9.0.0')
        Rake::Task['docker:push:stable'].invoke
      end

      it 'pushes image to public registry' do
        expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'registry.gitlab.com/foobar/public-image-archive/gitlab-ce:9.0.0')
        Rake::Task['docker:push:stable'].invoke
      end
    end

    describe 'docker:push:staging' do
      before do
        Rake::Task['docker:push:staging'].reenable
        allow(ENV).to receive(:[]).with('CI_COMMIT_REF_SLUG').and_return('foo-bar')
        allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.gitlab.com/gitlab-org/omnibus-gitlab')
        allow(SkopeoHelper).to receive(:copy_image).and_return(true)
        allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
        allow(Build::Info::Docker).to receive(:tag).and_return('1.2.3.4')
      end

      it 'pushes triggered images correctly' do
        expect(SkopeoHelper).to receive(:copy_image).with('registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce:1.2.3.4', 'registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce:foo-bar')
        Rake::Task['docker:push:staging'].invoke
      end
    end

    describe 'docker:push:nightly' do
      before do
        Rake::Task['docker:push:nightly'].reenable
        allow(Build::Check).to receive(:is_nightly?).and_return(true)
      end

      it 'copies nightly images correctly' do
        expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:nightly')
        Rake::Task['docker:push:nightly'].invoke
      end
    end

    describe 'docker:push:latest' do
      before do
        Rake::Task['docker:push:latest'].reenable
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)
      end

      it 'copies latest images correctly' do
        expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:latest')
        Rake::Task['docker:push:latest'].invoke
      end
    end

    describe 'docker:push:rc' do
      before do
        Rake::Task['docker:push:rc'].reenable
        allow(Build::Check).to receive(:is_latest_tag?).and_return(true)
      end

      it 'copies rc images correctly' do
        expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:rc')
        Rake::Task['docker:push:rc'].invoke
      end
    end

    describe 'docker:push:triggered' do
      before do
        Rake::Task['docker:push:triggered'].reenable
        allow(ENV).to receive(:[]).with('CI_COMMIT_REF_SLUG').and_return('foo-bar')
        allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.gitlab.com/gitlab-org/omnibus-gitlab')
        allow(SkopeoHelper).to receive(:copy_image).and_return(true)
        allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
        allow(Build::Info::Docker).to receive(:tag).and_return('1.2.3.4')
      end

      it 'pushes triggered images correctly' do
        expect(SkopeoHelper).to receive(:copy_image).with('registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce:1.2.3.4', 'registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce:foo-bar')
        Rake::Task['docker:push:triggered'].invoke
      end
    end
  end

  describe 'docker:combine_images' do
    before do
      Rake::Task['docker:push:triggered'].reenable
      allow(DockerHelper).to receive(:authenticate).and_return(true)
      allow(Build::GitlabImage).to receive(:gitlab_registry_image_address).and_return('registry.gitlab.com/foo/bar')
      allow(Build::Info::Docker).to receive(:tag).and_return('18.0.0')
      allow(Gitlab::Util).to receive(:get_env).and_call_original
    end

    it 'combines the two images' do
      expect(DockerHelper).to receive(:combine_images).with('registry.gitlab.com/foo/bar', '18.0.0', %w[18.0.0-amd64 18.0.0-arm64])

      Rake::Task['docker:combine_images'].invoke
    end
  end
end

RSpec.describe 'docker_operations' do
  describe 'without docker operations timeout variable' do
    it 'sets default value as timeout' do
      DockerOperations.set_timeout
      expect(Docker.options[:read_timeout]).to eq(1200)
    end
  end

  describe 'with docker operations timeout variable specified' do
    it 'sets provided value as timeout' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('DOCKER_TIMEOUT').and_return("500")
      DockerOperations.set_timeout
      expect(Docker.options[:read_timeout]).to eq("500")
    end
  end
end
