require 'spec_helper'
require 'omnibus-ctl'

RSpec.shared_context 'object storage config' do
  let(:object_config) do
    {
      artifacts: { bucket: 'artifacts' },
      lfs: { bucket: 'lfs-objects' },
      dependency_proxy: { bucket: 'dependency_proxy' },
      external_diffs: { bucket: 'external_diffs' },
      packages: { bucket: 'packages' },
      terraform_state: { enabled: false, bucket: 'terraform' },
      ci_secure_files: { bucket: 'ci_secure_files' },
      uploads: { bucket: 'uploads' },
      pages: { bucket: 'pages' }
    }
  end
  let(:aws_connection_hash) do
    {
      'provider' => 'AWS',
      'region' => 'eu-west-1',
      'aws_access_key_id' => 'AKIAKIAKI',
      'aws_secret_access_key' => 'secret123'
    }
  end
  let(:aws_storage_options_hash) do
    {
      'server_side_encryption' => 'AES256',
      'server_side_encryption_kms_key_id' => 'arn:aws:12345'
    }
  end
  let(:azure_connection_hash) do
    {
      'provider' => 'AzureRM',
      'azure_storage_account_name' => 'testaccount',
      'azure_storage_access_key' => '1234abcd'
    }
  end

  let(:aws_connection_data) { JSON.parse(aws_connection_hash.to_json, symbolize_names: true) }
  let(:aws_storage_options) { JSON.parse(aws_storage_options_hash.to_json, symbolize_names: true) }
end
