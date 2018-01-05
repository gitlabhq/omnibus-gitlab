require 'chef_helper'

describe 'qa', type: :rake do
  let(:gitlab_registry_image_address) { 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce-qa' }
  let(:gitlab_version) { '10.2.0' }
  let(:image_tag) { 'omnibus-12345' }

  before(:all) do
    Rake.application.rake_require 'gitlab/tasks/qa'
  end

  describe 'qa:build' do
    before do
      Rake::Task['qa:build'].reenable

      allow(Build::QA).to receive(:get_gitlab_repo).and_return("/tmp/gitlab.1234/qa")
      allow(Build::QAImage).to receive(:gitlab_registry_image_address).and_return(gitlab_registry_image_address)
    end

    it 'calls build method with correct parameters' do
      expect(DockerOperations).to receive(:build).with('/tmp/gitlab.1234/qa', 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce-qa', 'latest')

      Rake::Task['qa:build'].invoke
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
      expect(Build::Check).to receive(:add_nightly_tag?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('nightly', initial_tag: 'latest')

      Rake::Task['qa:push:nightly'].invoke
    end

    it 'pushes latest images correctly' do
      expect(Build::Check).to receive(:add_latest_tag?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('latest', initial_tag: 'latest')

      Rake::Task['qa:push:latest'].invoke
    end

    it 'pushes rc images correctly' do
      expect(Build::Check).to receive(:add_rc_tag?).and_return(true)

      expect(Build::QAImage).to receive(:tag_and_push_to_dockerhub).with('rc', initial_tag: 'latest')

      Rake::Task['qa:push:rc'].invoke
    end

    it 'pushes triggered images correctly' do
      expect(ENV).to receive(:[]).with('IMAGE_TAG').and_return(image_tag)

      expect(Build::QAImage).to receive(:tag_and_push_to_gitlab_registry).with(image_tag)

      Rake::Task['qa:push:triggered'].invoke
    end
  end

  describe 'qa:test' do
    before do
      Rake::Task['qa:test'].reenable
      Rake::Task['qa:build'].reenable
      Rake::Task['qa:push:triggered'].reenable

      allow(ENV).to receive(:[]).with('IMAGE_TAG').and_return(image_tag)
    end

    shared_examples 'qa:test command run' do |ee: false|
      it 'tags triggered QA correctly and run QA scenarios' do
        # qa:build
        expect(Build::QA).to receive(:get_gitlab_repo)
        expect(Build::QAImage).to receive(:gitlab_registry_image_address)
        expect(DockerOperations).to receive(:build)

        # qa:push:triggered
        expect(Build::QAImage).to receive(:tag_and_push_to_gitlab_registry).with(image_tag)

        expect(Build::Check).to receive(:is_ee?).and_return(ee)

        tests = {
          'Test::Instance::Image' => double,
          'Test::Omnibus::Image' => double,
          'Test::Omnibus::Upgrade' => double,
          'Test::Integration::Mattermost' => double
        }
        tests['Test::Integration::Geo'] = double if ee

        qa_image = double
        expect(Build::GitlabImage).to receive(:gitlab_registry_image_address).exactly(tests.size).times.with(tag: image_tag).and_return(qa_image)

        tests.each do |scenario, scenario_stub|
          scenario_stub = double
          expect(Gitlab::QA::Scenario).to receive(:const_get).with(scenario).and_return(scenario_stub)
          expect(scenario_stub).to receive(:perform).with(qa_image)
        end

        Rake::Task['qa:test'].invoke
      end
    end

    it_behaves_like 'qa:test command run', ee: false
    it_behaves_like 'qa:test command run', ee: true
  end
end
