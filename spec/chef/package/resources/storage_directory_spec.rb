require 'chef_helper'

RSpec.describe 'storage_directory' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(storage_directory)) do |node|
      node.normal['gitlab']['manage-storage-directories']['enable'] = true
    end
  end
  let(:chef_run) { runner.converge("test_package::storage_directory_create") }

  it 'executes correct ruby block' do
    allow_any_instance_of(StorageDirectoryHelper).to receive(:ensure_directory_exists).and_return(true)
    allow_any_instance_of(StorageDirectoryHelper).to receive(:ensure_permissions_set).and_return(true)
    allow_any_instance_of(StorageDirectoryHelper).to receive(:validate!).and_return(true)

    expect(chef_run).to run_ruby_block('directory resource: /tmp/bar')
    expect_any_instance_of(StorageDirectoryHelper).to receive(:ensure_directory_exists)

    ruby_block = chef_run.ruby_block('directory resource: /tmp/bar')
    ruby_block.block.call
  end
end
