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

  let(:google_connection_hash_with_application_default) do
    {
      'provider' => 'Google',
      'google_application_default' => true
    }
  end
  let(:google_connection_hash_with_json_key_string) do
    {
      'provider' => 'Google',
      'google_json_key_string' => '{
        "type": "service_account",
        "project_id": "test",
        "private_key_id": "555555555555555555555",
        "private_key": "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----\n",
        "client_email": "test@test.iam.gserviceaccount.com",
        "client_id": "555555555555555555555",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/test%40test.iam.gserviceaccount.com"
      }'
    }
  end
  let(:google_connection_hash_with_json_key_location) do
    {
      'provider' => 'Google',
      'google_json_key_location' => '/usr/opt/testdata/google_dummy_credentials.json'
    }
  end
  let(:incomplete_google_connection_hash) { { 'provider' => 'Google' } }

  let(:aws_connection_data) { JSON.parse(aws_connection_hash.to_json, symbolize_names: true) }
  let(:aws_storage_options) { JSON.parse(aws_storage_options_hash.to_json, symbolize_names: true) }
end
