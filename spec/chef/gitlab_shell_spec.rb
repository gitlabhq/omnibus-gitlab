require 'chef_helper'

describe 'gitlab_shell' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  # def stub_gitlab_rb(config)
  #   config.each do |key, value|
  #     value = Mash.from_hash(value) if value.is_a?(Hash)
  #     allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
  #   end
  # end

  context 'when git_data_dir is set as a single directory' do
    before { stub_gitlab_rb(git_data_dir: '/tmp/user/git-data') }

    it 'correctly sets the shell git data directories' do
      expect(chef_run.node['gitlab']['gitlab-shell']['git_data_directories'])
        .to eql('default' => '/tmp/user/git-data')
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages'])
        .to eql('default' => '/tmp/user/git-data/repositories')
    end
  end

  context 'when git_data_dirs is set to multiple directories' do
    before do
      stub_gitlab_rb({
        git_data_dirs: { 'default' => '/tmp/default/git-data', 'overflow' => '/tmp/other/git-overflow-data' }
      })
    end

    it 'correctly sets the shell git data directories' do
      expect(chef_run.node['gitlab']['gitlab-shell']['git_data_directories']).to eql({
        'default' => '/tmp/default/git-data',
        'overflow' => '/tmp/other/git-overflow-data'
      })
    end

    it 'correctly sets the repository storage directories' do
      expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eql({
        'default' => '/tmp/default/git-data/repositories',
        'overflow' => '/tmp/other/git-overflow-data/repositories'
      })
    end
  end

  it 'defaults the auth_file to be within the user\'s home directory' do
    stub_gitlab_rb(user: { home: '/tmp/user' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/user/.ssh/authorized_keys')
  end

  it 'uses custom auth_files set in gitlab.rb' do
    stub_gitlab_rb(user: { home: '/tmp/user' }, gitlab_shell: { auth_file: '/tmp/authorized_keys' })
    expect(chef_run.node['gitlab']['gitlab-shell']['auth_file']).to eq('/tmp/authorized_keys')
  end
end
