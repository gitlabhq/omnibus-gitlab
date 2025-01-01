RSpec.shared_examples 'git data directory' do |git_data_path|
  it 'creates the git-data directory' do
    expect(chef_run).to create_storage_directory(git_data_path).with(owner: 'git', group: 'git', mode: '2770')
  end

  it 'creates the repositories directory' do
    expect(chef_run).to create_storage_directory("#{git_data_path}/repositories").with(owner: 'git', group: 'git', mode: '2770')
  end
end
