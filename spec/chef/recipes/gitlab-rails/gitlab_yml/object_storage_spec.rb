require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'object storage settings' do
    include_context 'object storage config'

    describe 'consolidated object storage settings' do
      context 'with default values' do
        it 'renders gitlab.yml without consolidated object storage settings' do
          expect(gitlab_yml[:production][:object_store]).to be_nil
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              object_store: {
                enabled: true,
                connection: aws_connection_hash,
                storage_options: aws_storage_options_hash,
                objects: object_config,
                proxy_download: true,
              }
            }
          )
        end

        it 'generates gitlab.yml properly with specified values' do
          expect(gitlab_yml[:production][:object_store]).to eq(
            enabled: true,
            connection: aws_connection_data,
            storage_options: aws_storage_options,
            objects: object_config,
            proxy_download: true
          )
        end
      end
    end

    describe 'individual object storage settings' do
      # Parameters are:
      # 1. Component name
      # 2. Default settings deviating from general pattern
      # 3. Whether Workhorse acceleration is in place - decides whether to
      #    include background_upload, direct_upload, proxy_download etc.
      include_examples 'renders object storage settings in gitlab.yml', 'artifacts'
      include_examples 'renders object storage settings in gitlab.yml', 'uploads'
      include_examples 'renders object storage settings in gitlab.yml', 'external_diffs', { remote_directory: 'external-diffs' }
      include_examples 'renders object storage settings in gitlab.yml', 'lfs', { remote_directory: 'lfs-objects' }
      include_examples 'renders object storage settings in gitlab.yml', 'packages'
      include_examples 'renders object storage settings in gitlab.yml', 'dependency_proxy'
      include_examples 'renders object storage settings in gitlab.yml', 'terraform_state', { remote_directory: 'terraform' }, false
      include_examples 'renders object storage settings in gitlab.yml', 'ci_secure_files', { remote_directory: 'ci-secure-files' }, false
      include_examples 'renders object storage settings in gitlab.yml', 'pages', {}, false
    end
  end
end
