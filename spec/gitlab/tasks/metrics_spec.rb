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
      allow(Build::Check).to receive(:is_ee?).and_return(true)
    end

    it 'does not upgrade if CE' do
      allow(Build::Check).to receive(:is_ee?).and_return(false)

      expect(Build::Metrics).not_to receive(:install_package)
      expect(STDOUT).to receive(:puts).with('Not an EE package. Not upgrading.')

      Rake::Task['metrics:upgrade_package'].invoke
    end

    it 'does not upgrade if patch release' do
      allow(Build::Check).to receive(:is_patch_release?).and_return(true)
      allow(Build::Check).to receive(:is_an_upgrade?).and_return(true)

      expect(Build::Metrics).not_to receive(:install_package)
      expect(STDOUT).to receive(:puts).with('Not a major/minor release. Not upgrading.')

      Rake::Task['metrics:upgrade_package'].invoke
    end

    it 'does not upgrade if not an upgrade' do
      allow(Build::Check).to receive(:is_patch_release?).and_return(false)
      allow(Build::Check).to receive(:is_an_upgrade?).and_return(false)

      expect(Build::Metrics).not_to receive(:install_package)
      expect(STDOUT).to receive(:puts).with('Not the latest package. Not upgrading.')

      Rake::Task['metrics:upgrade_package'].invoke
    end

    it 'initiates an upgrade correctly' do
      allow(Build::Check).to receive(:is_patch_release?).and_return(false)
      allow(Build::Check).to receive(:is_an_upgrade?).and_return(true)
      allow(Build::Metrics).to receive(:install_package).and_return(true)
      allow(Build::Info).to receive(:release_version).and_return("10.0.5-ce.0")

      expect(Build::Metrics).to receive(:install_package)

      Rake::Task['metrics:upgrade_package'].invoke
    end
  end
end
