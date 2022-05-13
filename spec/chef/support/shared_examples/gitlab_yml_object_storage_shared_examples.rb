RSpec.shared_examples 'renders object storage settings in gitlab.yml' do |component, component_default = {}, workhorse_accelerated = true|
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

        default_values[:proxy_download] = false if workhorse_accelerated

        default_values.merge!(component_default)

        config = gitlab_yml[:production][component.to_sym][:object_store]
        expect(config).to eq(default_values)
      end
    end

    context 'with user specified values' do
      before do
        gitlab_rails_config = {
          "#{component}_object_store_enabled" => true,
          "#{component}_object_store_remote_directory" => 'foobar',
          "#{component}_object_store_connection" => aws_connection_hash
        }

        gitlab_rails_config["#{component}_object_store_proxy_download"] = true if workhorse_accelerated

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

        expected_output[:proxy_download] = true if workhorse_accelerated

        expect(gitlab_yml[:production][component.to_sym][:object_store]).to eq(expected_output)
      end
    end
  end
end
