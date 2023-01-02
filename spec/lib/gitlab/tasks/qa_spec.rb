require 'spec_helper'

RSpec.describe 'qa', type: :rake do
  let(:gitlab_registry_image_address) { 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce-qa' }
  let(:gitlab_version) { '10.2.0' }
  let(:commit_sha) { 'abcd1234' }
  let(:image_tag) { 'omnibus-12345' }
  let(:version_manifest) { { "software": { "gitlab-rails": { "locked_version": "123445" } } } }

  before(:all) do
    Rake.application.rake_require 'gitlab/tasks/qa'
  end

  describe 'qa:build' do
    let(:repo_path) { "/tmp/gitlab" }
    before do
      Rake::Task['qa:build'].reenable

      allow(ENV).to receive(:[]).and_call_original
      stub_is_ee(false)
      allow(Build::QA).to receive(:get_gitlab_repo).and_return(repo_path)
      allow(Build::QA).to receive(:gitlab_repo).and_return(repo_path)
      allow(Build::QAImage).to receive(:gitlab_registry_image_address).and_return(gitlab_registry_image_address)
      allow(JSON).to receive(:parse).and_return(version_manifest)
    end

    it 'calls build method with correct parameters' do
      expect(DockerOperations).to receive(:build).with(
        repo_path,
        'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce-qa',
        'latest',
        buildargs: "{\"QA_BUILD_TARGET\":\"foss\"}",
        dockerfile: "qa/Dockerfile"
      )

      Rake::Task['qa:build'].invoke
    end
  end

  describe 'qa:copy' do
    before do
      allow(Build::Info).to receive(:gitlab_version).and_return(gitlab_version)
      allow(Build::Info).to receive(:commit_sha).and_return(commit_sha)
    end

    describe ':nightly' do
      before do
        Rake::Task['qa:copy:nightly'].reenable
        allow(Build::Check).to receive(:is_nightly?).and_return(true)
      end

      it 'copies nightly images correctly' do
        expect(Build::QAImage).to receive(:copy_image_to_dockerhub).with('nightly')

        Rake::Task['qa:copy:nightly'].invoke
      end
    end

    describe ':staging' do
      before do
        Rake::Task['qa:copy:staging'].reenable
      end

      it 'copies staging images correctly' do
        stub_is_auto_deploy(false)

        expect(Build::QAImage).to receive(:copy_image_to_omnibus_registry).with(gitlab_version)
        expect(Build::QAImage).to receive(:copy_image_to_omnibus_registry).with(commit_sha)

        Rake::Task['qa:copy:staging'].invoke
      end
    end
  end

  describe 'qa:push' do
    before do
      Rake::Task['qa:push:stable'].reenable
      Rake::Task['qa:push:nightly'].reenable
      Rake::Task['qa:push:rc'].reenable
      Rake::Task['qa:push:latest'].reenable

      allow(Build::Info).to receive(:gitlab_version).and_return(gitlab_version)
    end

    it 'pushes stable images correctly' do
      expect(Build::QAImage).to receive(:tag_and_push_to_gitlab_registry).with(gitlab_version)
      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with(gitlab_version, initial_tag: 'latest')

      Rake::Task['qa:push:stable'].invoke
    end

    it 'pushes nightly images correctly' do
      expect(Build::Check).to receive(:is_nightly?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('nightly', initial_tag: 'latest')

      Rake::Task['qa:push:nightly'].invoke
    end

    it 'pushes latest images correctly' do
      expect(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('latest', initial_tag: 'latest')

      Rake::Task['qa:push:latest'].invoke
    end

    it 'pushes rc images correctly' do
      expect(Build::Check).to receive(:is_latest_tag?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('rc', initial_tag: 'latest')

      Rake::Task['qa:push:rc'].invoke
    end

    describe ':staging' do
      before do
        Rake::Task['qa:push:staging'].reenable

        allow(Build::Info).to receive(:gitlab_version).and_return(gitlab_version)
        allow(Build::Info).to receive(:commit_sha).and_return(commit_sha)
      end

      it 'pushes staging images correctly' do
        stub_is_auto_deploy(false)
        expect(Build::QAImage).to receive(:tag_and_push_to_gitlab_registry).with(gitlab_version)
        expect(Build::QAImage).to receive(:tag_and_push_to_gitlab_registry).with(commit_sha)

        Rake::Task['qa:push:staging'].invoke
      end
    end
  end
end
