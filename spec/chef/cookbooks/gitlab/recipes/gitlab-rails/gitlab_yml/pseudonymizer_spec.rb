require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'
  include_context 'object storage config'

  describe 'pseudonymizer settings' do
    context 'with default values' do
      it 'renders gitlab.yml with pseudonymizer disabled' do
        config = gitlab_yml[:production][:pseudonymizer]
        expect(config).to eq(
          {
            manifest: nil,
            upload: {
              connection: {},
              remote_directory: nil
            }
          }
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            pseudonymizer_manifest: 'another/path/manifest.yml',
            pseudonymizer_upload_remote_directory: 'gitlab-pseudo',
            pseudonymizer_upload_connection: aws_connection_hash,
          }
        )
      end
      it 'renders gitlab.yml with user specified values' do
        config = gitlab_yml[:production][:pseudonymizer]
        expect(config).to eq(
          {
            manifest: 'another/path/manifest.yml',
            upload: {
              connection: aws_connection_data,
              remote_directory: 'gitlab-pseudo'
            }
          }
        )
      end
    end
  end
end
