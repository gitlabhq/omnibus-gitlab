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
      allow(Build::Info::Docker).to receive(:tag).and_return('9.0.0')
      allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
      allow(Build::GitlabImage).to receive(:write_release_file).and_return(true)
      allow(File).to receive(:expand_path).and_return('/tmp/omnibus-gitlab/lib/gitlab/tasks/docker_tasks.rake')

      allow(DockerHelper).to receive(:authenticate).and_return(true)
      allow(DockerHelper).to receive(:build).and_return(true)
      allow(DockerHelper).to receive(:create_builder).and_return(true)

      expect(DockerHelper).to receive(:build).with("/tmp/omnibus-gitlab/docker", "registry.com/group/repo/gitlab-ce", '9.0.0')
      Rake::Task['docker:build:image'].invoke
    end
  end

  describe 'docker:pull:staging' do
    before do
      Rake::Task['docker:pull:staging'].reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is set' do
      before do
        stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'true')
      end

      it 'does not pull image' do
        expect(Docker::Image).not_to receive(:create).with('fromImage' => 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0')
        Rake::Task['docker:pull:staging'].invoke
      end
    end

    context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is not set' do
      before do
        stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'false')
      end

      it 'pulls in correct image' do
        allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('dev.gitlab.org:5005/gitlab/omnibus-gitlab')
        allow(Build::Info::Package).to receive(:name).and_return('gitlab-ce')
        allow(Build::Info::Docker).to receive(:tag).and_return('9.0.0')
        allow(DockerOperations).to receive(:authenticate).and_return(true)
        allow(SkopeoHelper).to receive(:login).and_return(true)

        expect(Docker::Image).to receive(:create).with('fromImage' => 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0')
        Rake::Task['docker:pull:staging'].invoke
      end
    end
  end

  describe 'docker:push' do
    let(:dummy_image) { Docker::Image.new(Docker::Connection.new("test", {}), "id" => "test") }
    let(:dummy_creds) { { username: "test", password: "test" } }

    before do
      Rake::Task['docker:push:stable'].reenable

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

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'true')
        end

        it 'copies nightly images correctly' do
          expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:nightly')
          Rake::Task['docker:push:nightly'].invoke
        end
      end

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is not set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'false')
        end

        it 'pushes nightly images correctly' do
          expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:nightly')
          Rake::Task['docker:push:nightly'].invoke
        end
      end
    end

    describe 'docker:push:latest' do
      before do
        Rake::Task['docker:push:latest'].reenable
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)
      end

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'true')
        end

        it 'copies latest images correctly' do
          expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:latest')
          Rake::Task['docker:push:latest'].invoke
        end
      end

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is not set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'false')
        end

        it 'pushes latest images correctly' do
          expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:latest')
          Rake::Task['docker:push:latest'].invoke
        end
      end
    end

    describe 'docker:push:rc' do
      before do
        Rake::Task['docker:push:rc'].reenable
        allow(Build::Check).to receive(:is_latest_tag?).and_return(true)
      end

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'true')
        end

        it 'copies rc images correctly' do
          expect(SkopeoHelper).to receive(:copy_image).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0', 'gitlab/gitlab-ce:rc')
          Rake::Task['docker:push:rc'].invoke
        end
      end

      context 'when USE_SKOPEO_FOR_DOCKER_RELEASE is not set' do
        before do
          stub_env_var('USE_SKOPEO_FOR_DOCKER_RELEASE', 'false')
        end

        it 'pushes rc images correctly' do
          expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:rc')
          Rake::Task['docker:push:rc'].invoke
        end
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
