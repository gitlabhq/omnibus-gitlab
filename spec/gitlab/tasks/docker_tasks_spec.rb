require 'spec_helper'
require_relative '../../../lib/gitlab/docker_operations.rb'

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
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('dev.gitlab.org:5005/gitlab/omnibus-gitlab')
      allow(Build::Info).to receive(:package).and_return('gitlab-ce')
      allow(Build::GitlabImage).to receive(:write_release_file).and_return(true)
      allow(File).to receive(:expand_path).and_return('/tmp/omnibus-gitlab/lib/gitlab/tasks/docker_tasks.rake')
      allow(DockerOperations).to receive(:build).and_call_original

      expect(DockerOperations).to receive(:build).with("/tmp/omnibus-gitlab/docker", "dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce", "latest")
      expect(Docker::Image).to receive(:build_from_dir).with("/tmp/omnibus-gitlab/docker", { t: "dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:latest", pull: true })
      Rake::Task['docker:build:image'].invoke
    end
  end

  describe 'docker:measure_memory' do
    let(:mock_measurer) { Gitlab::DockerImageMemoryMeasurer.new('abc') }

    before do
      Rake::Task['docker:measure_memory'].reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    it 'initialize DockerImageMemoryMeasurer with correct parameters when ENV IMAGE_REFERENCE not set' do
      allow(Build::Info).to receive(:image_reference).and_return("dev.gitlab.org:5005/gitlab/omnibus-gitlab")
      allow(ENV).to receive(:[]).with('DEBUG_OUTPUT_DIR').and_return('tmp/debug_folder')

      expect(Gitlab::DockerImageMemoryMeasurer).to receive(:new).with('dev.gitlab.org:5005/gitlab/omnibus-gitlab', 'tmp/debug_folder').and_return(mock_measurer)
      expect(mock_measurer).to receive(:measure).and_return('mock_return')
      expect { Rake::Task['docker:measure_memory'].invoke }.to output("mock_return\n").to_stdout
    end

    it 'initialize DockerImageMemoryMeasurer with correct parameters when ENV IMAGE_REFERENCE set' do
      allow(Build::Info).to receive(:image_reference).and_return("dev.gitlab.org:5005/gitlab/omnibus-gitlab")
      allow(ENV).to receive(:[]).with('IMAGE_REFERENCE').and_return('env_value_image_reference')
      allow(ENV).to receive(:[]).with('DEBUG_OUTPUT_DIR').and_return('tmp/debug_folder')

      expect(Gitlab::DockerImageMemoryMeasurer).to receive(:new).with('env_value_image_reference', 'tmp/debug_folder').and_return(mock_measurer)
      expect(mock_measurer).to receive(:measure).and_return('mock_return')
      expect { Rake::Task['docker:measure_memory'].invoke }.to output("mock_return\n").to_stdout
    end
  end

  describe 'docker:pull:staging' do
    before do
      Rake::Task['docker:pull:staging'].reenable
      allow(ENV).to receive(:[]).and_call_original
    end

    it 'pulls in correct image' do
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('dev.gitlab.org:5005/gitlab/omnibus-gitlab')
      allow(Build::Info).to receive(:package).and_return('gitlab-ce')
      allow(Build::Info).to receive(:docker_tag).and_return('9.0.0')
      allow(DockerOperations).to receive(:authenticate).and_return(true)

      expect(Docker::Image).to receive(:create).with('fromImage' => 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0')
      Rake::Task['docker:pull:staging'].invoke
    end
  end

  describe 'docker:push' do
    let(:dummy_image) { Docker::Image.new(Docker::Connection.new("test", {}), "id" => "test") }
    let(:dummy_creds) { { username: "test", password: "test" } }

    before do
      Rake::Task['docker:push:staging'].reenable
      Rake::Task['docker:push:stable'].reenable
      Rake::Task['docker:push:nightly'].reenable
      Rake::Task['docker:push:rc'].reenable
      Rake::Task['docker:push:latest'].reenable

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('dev.gitlab.org:5005/gitlab/omnibus-gitlab')
      allow(Build::Info).to receive(:package).and_return('gitlab-ce')
      allow(Build::Info).to receive(:docker_tag).and_return('9.0.0')
      allow(DockerOperations).to receive(:authenticate).and_return(true)
      allow(Docker::Image).to receive(:get).and_return(dummy_image)
      allow(Docker).to receive(:creds).and_return(dummy_creds)
      allow(dummy_image).to receive(:tag).and_return(true)
    end

    it 'pushes to staging correctly' do
      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:9.0.0')
      Rake::Task['docker:push:staging'].invoke
    end

    it 'pushes nightly images correctly' do
      allow(Build::Check).to receive(:is_nightly?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:nightly')
      Rake::Task['docker:push:nightly'].invoke
    end

    it 'pushes latest images correctly' do
      allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:latest')
      Rake::Task['docker:push:latest'].invoke
    end

    it 'pushes rc images correctly' do
      allow(Build::Check).to receive(:is_latest_tag?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-ce:rc')
      Rake::Task['docker:push:rc'].invoke
    end

    it 'pushes triggered images correctly' do
      allow(ENV).to receive(:[]).with('CI_REGISTRY_IMAGE').and_return('registry.gitlab.com/gitlab-org/omnibus-gitlab')
      allow(ENV).to receive(:[]).with("IMAGE_TAG").and_return("omnibus-12345")

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ce:omnibus-12345')
      Rake::Task['docker:push:triggered'].invoke
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
