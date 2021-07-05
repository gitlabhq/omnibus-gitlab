require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Backup settings' do
    context 'with default values' do
      it 'renders with default backup settings' do
        expect(gitlab_yml[:production][:backup]).to eq(
          archive_permissions: nil,
          gitaly_backup_path: '/opt/gitlab/embedded/bin/gitaly-backup',
          keep_time: nil,
          path: '/var/opt/gitlab/backups',
          pg_schema: nil,
          upload: {
            connection: nil,
            encryption: nil,
            encryption_key: nil,
            multipart_chunk_size: nil,
            remote_directory: nil,
            storage_class: nil
          }
        )
      end
    end

    context 'with user specified gitaly-backup path set' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            backup_gitaly_backup_path: '/some other/bin/gitaly-backup'
          }
        )
      end

      it 'renders with the user specified gitaly-backup path' do
        expect(gitlab_yml[:production][:backup]).to include(
          gitaly_backup_path: '/some other/bin/gitaly-backup'
        )
      end
    end
  end
end
