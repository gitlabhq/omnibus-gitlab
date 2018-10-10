require 'spec_helper'

describe 'metrics', type: :rake do
  let(:gitlab_registry_image_address) { 'dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce-qa' }
  let(:gitlab_version) { '10.2.0' }
  let(:image_tag) { 'omnibus-12345' }
  let(:version_manifest) { { "software": { "gitlab-rails": { "locked_version": "123445" } } } }

  before(:all) do
    Rake.application.rake_require 'gitlab/tasks/metrics'
  end

  describe 'metrics:upgrade_package' do
    before do
      Rake::Task['metrics:upgrade_package'].reenable
    end

    it 'does not install or upgrade unless version criteria are met' do
      allow(Build::Metrics).to receive(:should_upgrade?).and_return(false)

      expect(Build::Metrics).not_to receive(:configure_gitlab_repo)
      expect(Build::Metrics).not_to receive(:install_package)
      expect(Build::Metrics).not_to receive(:upgrade_package)
      expect(Build::Metrics).not_to receive(:calculate_duration)
      expect(Build::Metrics).not_to receive(:append_to_sheet)
    end

    it 'initiates an previous version install and upgrade correctly' do
      allow(Build::Info).to receive(:release_version).and_return("10.4.0-ee.0")
      allow(Build::Info).to receive(:previous_version).and_return("10.3.6-ee.0")
      allow(Build::Metrics).to receive(:should_upgrade?).and_return(true)

      expect(Build::Metrics).to receive(:configure_gitlab_repo)
      expect(Build::Metrics).to receive(:install_package).with("10.3.6-ee.0")
      expect(Build::Metrics).to receive(:upgrade_package)
      expect(Build::Metrics).to receive(:calculate_duration).and_return(290)
      expect(Build::Metrics).to receive(:append_to_sheet).with('10.4.0-ee.0', 290)

      Rake::Task['metrics:upgrade_package'].invoke
    end
  end
end
