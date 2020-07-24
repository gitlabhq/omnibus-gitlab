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
      uploads: { bucket: 'uploads' }
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
end
