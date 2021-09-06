require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'
  include_context 'object storage config'

  describe 'Backup settings' do
    let(:backup_settings) { gitlab_yml[:production][:backup] }

    context 'with default values' do
      it 'renders with default backup settings' do
        expect(backup_settings).to eq(
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
            storage_options: {},
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
        expect(backup_settings).to include(
          gitaly_backup_path: '/some other/bin/gitaly-backup'
        )
      end
    end

    context 'remote upload', :aggregate_failures do
      let(:upload_settings) { backup_settings[:upload] }

      context 'with Server-Side Encryption' do
        context 'with Amazon S3-Managed Keys (SSE-S3)' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                'backup_upload_connection' => aws_connection_hash,
                'backup_encryption' => 'AES256'
              }
            )
          end

          it 'renders encryption option' do
            expect(upload_settings[:encryption]).to eq('AES256')
            expect(upload_settings[:encryption_key]).to be_nil
            expect(upload_settings[:storage_options]).to eq({})
          end
        end

        context 'with Customer Master Keys (CMKs) Stored in AWS Key Management Service (SSE-KMS)' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                'backup_upload_connection' => aws_connection_hash,
                'backup_upload_storage_options' => aws_storage_options_hash
              }
            )
          end

          it 'renders storage options' do
            expect(upload_settings[:encryption]).to be_nil
            expect(upload_settings[:encryption_key]).to be_nil
            expect(upload_settings[:storage_options]).to eq(aws_storage_options)
          end
        end

        context 'with Customer-Provided Keys (SSE-C)' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                'backup_upload_connection' => aws_connection_hash,
                'backup_encryption' => 'AES256',
                'backup_encryption_key' => 'A12345678'
              }
            )
          end

          it 'renders encryption and encryption key options' do
            expect(upload_settings[:encryption]).to eq('AES256')
            expect(upload_settings[:encryption_key]).to eq('A12345678')
            expect(upload_settings[:storage_options]).to eq({})
          end
        end
      end
    end
  end
end
