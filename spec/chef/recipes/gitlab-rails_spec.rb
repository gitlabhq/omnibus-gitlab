require 'chef_helper'

describe 'gitlab::gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when manage-storage-directories is disabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' }, manage_storage_directories: { enable: false })
    end

    it 'does not create the shared directory' do
      expect(chef_run).to_not create_directory('/tmp/shared')
    end

    it 'does not create the artifacts directory' do
      expect(chef_run).to_not create_directory('/tmp/shared/artifacts')
    end

    it 'does not create the lfs storage directory' do
      expect(chef_run).to_not create_directory('/tmp/shared/lfs-objects')
    end

    it 'does not create the uploads storage directory' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to_not create_directory('/tmp/uploads')
    end

    it 'does not create the ci builds directory' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to_not create_directory('/tmp/builds')
    end

    it 'does not create the GitLab pages directory' do
      expect(chef_run).to_not create_directory('/tmp/shared/pages')
    end
  end

  context 'when manage-storage-directories is enabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' }, manage_storage_directories: { enable: true } )
    end

    it 'creates the shared directory with the proper permissions' do
      expect(chef_run).to create_directory('/tmp/shared').with(
        user: 'git',
        group: 'gitlab-www',
        mode: '0751'
      )
    end

    it 'creates the artifacts directory with the proper permissions' do
      expect(chef_run).to create_directory('/tmp/shared/artifacts').with(
        user: 'git',
        mode: '0700'
      )
    end

    it 'creates the lfs storage directory with the proper permissions' do
      expect(chef_run).to create_directory('/tmp/shared/lfs-objects').with(
        user: 'git',
        mode: '0700'
      )
    end

    it 'creates the uploads directory with the proper permissions' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to create_directory('/tmp/uploads').with(
        user: 'git',
        mode: '0700'
      )
    end

    it 'creates the ci builds directory with the proper permissions' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to create_directory('/tmp/builds').with(
        user: 'git',
        mode: '0700'
      )
    end

    it 'creates the GitLab pages directory with the proper permissions' do
      expect(chef_run).to create_directory('/tmp/shared/pages').with(
        user: 'git',
        group: 'gitlab-www',
        mode: '0750'
      )
    end

    context 'and root_squash_safe directory management is enabled' do
      before { stub_gitlab_rb(manage_storage_directories: { enable: true, root_squash_safe: true } ) }

      it 'creates the shared directory with the proper permissions' do
        expect(chef_run).to run_bash('directory resource: /tmp/shared').with(
          user: 'git',
          group: 'gitlab-www',
          code: /chmod 0751/
        )
      end

      it 'creates the artifacts directory with the proper permissions' do
        expect(chef_run).to run_bash('directory resource: /tmp/shared/artifacts').with(
          user: 'git',
          code: /chmod 0700/
        )
      end

      it 'creates the lfs storage directory with the proper permissions' do
        expect(chef_run).to run_bash('directory resource: /tmp/shared/lfs-objects').with(
          user: 'git',
          code: /chmod 0700/
        )
      end

      it 'creates the uploads directory with the proper permissions' do
        stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
        expect(chef_run).to run_bash('directory resource: /tmp/uploads').with(
          user: 'git',
          code: /chmod 0700/
        )
      end

      it 'creates the ci builds directory with the proper permissions' do
        stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
        expect(chef_run).to run_bash('directory resource: /tmp/builds').with(
          user: 'git',
          code: /chmod 0700/
        )
      end

      it 'creates the GitLab pages directory with the proper permissions' do
        expect(chef_run).to run_bash('directory resource: /tmp/shared/pages').with(
          user: 'git',
          group: 'gitlab-www',
          code: /chmod 0750/
        )
      end
    end
  end
end
