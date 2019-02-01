require 'chef_helper'

describe 'env_dir' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(env_dir)) }
  let(:chef_run) { runner.converge("test_package::env_dir_create") }

  after do
    FileUtils.rm_rf('/tmp/env')
  end

  it 'creates env directory' do
    expect(chef_run).to create_directory('/tmp/env')
  end

  it 'creates env variable' do
    expect(chef_run).to create_file('/tmp/env/FOO').with_content('Lorem')
    expect(chef_run).to create_file('/tmp/env/BAR').with_content('Ipsum')
  end

  it 'deletes extraneous files' do
    FileUtils.mkdir_p('/tmp/env')
    FileUtils.touch('/tmp/env/erase-me')

    expect(chef_run).to delete_file('/tmp/env/erase-me')
  end
end
