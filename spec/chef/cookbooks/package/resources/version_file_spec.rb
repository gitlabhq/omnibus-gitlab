require 'chef_helper'

version_file_path = '/tmp/VERSION_TEST'
version_check_cmd = 'echo 1.0.0-test'

# Collect version as the custom resource would
version = VersionHelper.version(version_check_cmd)

RSpec.describe 'version_file' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(version_file)) }
  let(:chef_run) { runner.converge("test_package::version_file_create") }

  after do
    FileUtils.rm_rf(version_file_path)
  end

  it 'creates version file' do
    expect(chef_run).to create_file(version_file_path).with_content(version)
  end

  it 'restarts service' do
    expect(chef_run.version_file('Test version file creation')).to notify('runit_service[foo]').to(:hup)
  end
end
