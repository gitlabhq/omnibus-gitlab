RSpec.shared_examples 'renders object storage settings in gitlab.yml' do |component, component_default = {}, proxy_download_supported = true, allowed_download_modes_supported = proxy_download_supported|
  include_context 'gitlab-rails'
  include_context 'object storage config'

  describe "for #{component}" do
    context 'with default values' do
      it 'renders gitlab.yml with object storage disabled and other default values' do
        default_values = {
          enabled: false,
          remote_directory: component,
          connection: {}
        }

        default_values[:proxy_download] = false if proxy_download_supported

        default_values.merge!(component_default)

        config = gitlab_yml[:production][component.to_sym][:object_store]
        expect(config).to eq(default_values)
      end

      it 'omits allowed_download_modes from gitlab.yml' do
        config = gitlab_yml[:production][component.to_sym][:object_store]
        expect(config).not_to have_key(:allowed_download_modes)
      end
    end

    context 'with user specified values' do
      before do
        gitlab_rails_config = {
          "#{component}_object_store_enabled" => true,
          "#{component}_object_store_remote_directory" => 'foobar',
          "#{component}_object_store_connection" => aws_connection_hash
        }

        gitlab_rails_config["#{component}_object_store_proxy_download"] = true if proxy_download_supported
        gitlab_rails_config["#{component}_object_store_allowed_download_modes"] = %w[direct proxy] if allowed_download_modes_supported

        stub_gitlab_rb(
          gitlab_rails: gitlab_rails_config.transform_keys(&:to_sym)
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expected_output = {
          enabled: true,
          connection: aws_connection_data,
          remote_directory: 'foobar'
        }

        expected_output[:proxy_download] = true if proxy_download_supported
        expected_output[:allowed_download_modes] = %w[direct proxy] if allowed_download_modes_supported

        expect(gitlab_yml[:production][component.to_sym][:object_store]).to eq(expected_output)
      end
    end

    if allowed_download_modes_supported
      context 'without allowed_download_modes configured' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              "#{component}_object_store_enabled" => true,
              "#{component}_object_store_remote_directory" => 'foobar',
              "#{component}_object_store_connection" => aws_connection_hash
            }.transform_keys(&:to_sym)
          )
        end

        it 'omits allowed_download_modes from gitlab.yml' do
          config = gitlab_yml[:production][component.to_sym][:object_store]
          expect(config).not_to have_key(:allowed_download_modes)
        end
      end
    end

    context 'with an invalid allowed_download_modes value' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            "#{component}_object_store_enabled" => true,
            "#{component}_object_store_connection" => aws_connection_hash,
            "#{component}_object_store_allowed_download_modes" => %w[direct bogus]
          }.transform_keys(&:to_sym)
        )
      end

      it 'raises an error naming the invalid configuration' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /allowed_download_modes contains invalid mode\(s\)\. Valid modes are: proxy, direct\..*#{component}_object_store_allowed_download_modes.*\["direct", "bogus"\]/
        )
      end
    end

    if proxy_download_supported && allowed_download_modes_supported
      context 'without the mode implied by proxy_download' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              "#{component}_object_store_enabled" => true,
              "#{component}_object_store_connection" => aws_connection_hash,
              "#{component}_object_store_proxy_download" => true,
              "#{component}_object_store_allowed_download_modes" => ['direct']
            }.transform_keys(&:to_sym)
          )
        end

        it 'raises an error naming the missing mode' do
          expect { chef_run }.to raise_error(
            RuntimeError,
            /allowed_download_modes must include the mode implied by proxy_download.*#{component}_object_store_allowed_download_modes.*must include "proxy"/
          )
        end
      end
    end
  end
end
