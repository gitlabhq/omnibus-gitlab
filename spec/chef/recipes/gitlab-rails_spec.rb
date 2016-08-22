require 'chef_helper'

describe 'gitlab::gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    # Prevent chef converge from reloading the helper library, which would override our helper stub
    allow(Kernel).to receive(:load).and_call_original
    allow(Kernel).to receive(:load).with(%r{gitlab/libraries/storage_directory_helper}).and_return(true)
  end

  context 'when manage-storage-directories is disabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' }, manage_storage_directories: { enable: false })
    end

    it 'does not create the shared directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared')
    end

    it 'does not create the artifacts directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'does not create the lfs storage directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'does not create the uploads storage directory' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'does not create the ci builds directory' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/builds')
    end

    it 'does not create the GitLab pages directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/pages')
    end
  end

  context 'when manage-storage-directories is enabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' } )
    end

    it 'creates the shared directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared')
    end

    it 'creates the artifacts directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'creates the lfs storage directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'creates the uploads directory' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'creates the ci builds directory' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to run_ruby_block('directory resource: /tmp/builds')
    end

    it 'creates the GitLab pages directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/pages')
    end
  end
end
