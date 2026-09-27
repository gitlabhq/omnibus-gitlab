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
                allowed_download_modes: %w[direct proxy],
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
            proxy_download: true,
            allowed_download_modes: %w[direct proxy]
          )
        end
      end

      context 'without allowed_download_modes configured' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              object_store: {
                enabled: true,
                connection: aws_connection_hash,
                objects: object_config,
                proxy_download: true
              }
            }
          )
        end

        it 'omits allowed_download_modes from gitlab.yml' do
          expect(gitlab_yml[:production][:object_store]).not_to have_key(:allowed_download_modes)
        end
      end

      context 'with an invalid allowed_download_modes value' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              object_store: {
                enabled: true,
                connection: aws_connection_hash,
                objects: object_config,
                allowed_download_modes: %w[direct bogus]
              }
            }
          )
        end

        it 'raises an error naming the invalid configuration' do
          expect { chef_run }.to raise_error(
            RuntimeError,
            /allowed_download_modes contains invalid mode\(s\)\. Valid modes are: proxy, direct\. .*object_store.*allowed_download_modes.*\["direct", "bogus"\]/
          )
        end
      end

      context 'without the mode implied by proxy_download' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              object_store: {
                enabled: true,
                connection: aws_connection_hash,
                proxy_download: true,
                allowed_download_modes: ['direct']
              }
            }
          )
        end

        it 'raises an error naming the missing mode' do
          expect { chef_run }.to raise_error(
            RuntimeError,
            /allowed_download_modes must include the mode implied by proxy_download.*object_store.*allowed_download_modes.*must include "proxy"/
          )
        end
      end
    end

    describe 'individual object storage settings' do
      # Parameters are:
      # 1. Component name
      # 2. Default settings deviating from general pattern
      # 3. Whether proxy_download is supported.
      # 4. Whether allowed_download_modes is supported.
      include_examples 'renders object storage settings in gitlab.yml', 'artifacts'
      include_examples 'renders object storage settings in gitlab.yml', 'uploads'
      include_examples 'renders object storage settings in gitlab.yml', 'external_diffs', { remote_directory: 'external-diffs' }
      include_examples 'renders object storage settings in gitlab.yml', 'lfs', { remote_directory: 'lfs-objects' }
      include_examples 'renders object storage settings in gitlab.yml', 'packages'
      include_examples 'renders object storage settings in gitlab.yml', 'dependency_proxy'
      include_examples 'renders object storage settings in gitlab.yml', 'terraform_state', { remote_directory: 'terraform' }, false, true
      include_examples 'renders object storage settings in gitlab.yml', 'ci_secure_files', { remote_directory: 'ci-secure-files' }, false, true
      include_examples 'renders object storage settings in gitlab.yml', 'agent_plan_content', { remote_directory: 'agent-plan-content' }, false, true
      include_examples 'renders object storage settings in gitlab.yml', 'ci_catalog_bundles', { remote_directory: 'ci-catalog-bundles' }, false, true
      include_examples 'renders object storage settings in gitlab.yml', 'pages', {}, false, false
    end
  end
end
