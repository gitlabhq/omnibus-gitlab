require 'chef_helper'
describe 'qa', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/qa'
  end

  describe 'qa:build' do
    let(:dummy_image) { Docker::Image.new(Docker::Connection.new("test", {}), "id" => "test") }
    let(:dummy_creds) { { username: "test", password: "test" } }

    before do
      Rake::Task['qa:build'].reenable

      allow(ENV).to receive(:[]).and_call_original
      allow(Build::QA).to receive(:get_gitlab_repo).and_return("/tmp/gitlab.1234/qa")
      allow(Build::Info).to receive(:package).and_return('gitlab-ce')
      allow(DockerOperations).to receive(:build).and_call_original
    end

    it 'calls build method with correct parameters' do
      allow(ENV).to receive(:[]).with('IMAGE_TAG').and_return(nil)

      expect(DockerOperations).to receive(:build).with("/tmp/gitlab.1234/qa", "gitlab/gitlab-qa", "ce-latest")
      expect(Docker::Image).to receive(:build_from_dir).with("/tmp/gitlab.1234/qa", { t: "gitlab/gitlab-qa:ce-latest", pull: true })
      Rake::Task['qa:build'].invoke
    end

    it 'tags triggered QA correctly' do
      allow(ENV).to receive(:[]).with('IMAGE_TAG').and_return("omnibus-12345")
      allow(DockerOperations).to receive(:build).and_return(true)
      allow(Docker::Image).to receive(:build_from_dir).and_return(true)
      allow(Docker::Image).to receive(:get).and_return(dummy_image)
      allow(Build::Image).to receive(:tag_triggered_qa).and_call_original
      allow(DockerOperations).to receive(:tag).and_call_original

      expect(Build::Image).to receive(:tag_triggered_qa)
      expect(DockerOperations).to receive(:tag).with("gitlab/gitlab-qa", "gitlab/gitlab-qa", "ce-latest", "ce-omnibus-12345")
      expect(dummy_image).to receive(:tag).with(repo: "gitlab/gitlab-qa", tag: "ce-omnibus-12345", force: true)
      Rake::Task['qa:build'].invoke
    end
  end

  describe 'qa:push' do
    let(:dummy_image) { Docker::Image.new(Docker::Connection.new("test", {}), "id" => "test") }
    let(:dummy_creds) { { username: "test", password: "test" } }

    before do
      Rake::Task['qa:push:stable'].reenable
      Rake::Task['qa:push:nightly'].reenable
      Rake::Task['qa:push:rc'].reenable
      Rake::Task['qa:push:latest'].reenable

      allow(ENV).to receive(:[]).and_call_original
      allow(Build::Info).to receive(:package).and_return('gitlab-ce')
      allow(Build::Info).to receive(:docker_tag).and_return('9.0.0')
      allow(DockerOperations).to receive(:authenticate).and_return(true)
      allow(Docker::Image).to receive(:get).and_return(dummy_image)
      allow(Docker).to receive(:creds).and_return(dummy_creds)
      allow(dummy_image).to receive(:tag).and_return(true)
    end

    it 'pushes nightly images correctly' do
      allow(Build::Check).to receive(:add_nightly_tag?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-qa:ce-nightly')
      Rake::Task['qa:push:nightly'].invoke
    end

    it 'pushes latest images correctly' do
      allow(Build::Check).to receive(:add_latest_tag?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-qa:ce-latest')
      Rake::Task['qa:push:latest'].invoke
    end

    it 'pushes rc images correctly' do
      allow(Build::Check).to receive(:add_rc_tag?).and_return(true)

      expect(dummy_image).to receive(:push).with(dummy_creds, repo_tag: 'gitlab/gitlab-qa:ce-rc')
      Rake::Task['qa:push:rc'].invoke
    end
  end
end
