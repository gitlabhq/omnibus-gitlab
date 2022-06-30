require 'chef_helper'

RSpec.describe GitlabWorkhorseHelper do
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'workhorse is listening on a tcp socket' do
    cached(:chef_run) { converge_config }
    let(:tcp_address) { '1.9.8.4' }

    before do
      stub_gitlab_rb(
        gitlab_workhorse: {
          listen_network: 'http',
          listen_addr: tcp_address
        }
      )
    end

    describe '#unix_socket?' do
      it 'returns false' do
        expect(subject.unix_socket?).to be false
      end
    end
  end

  context 'workhorse is listening on a unix socket' do
    cached(:chef_run) { converge_config }
    before do
      stub_gitlab_rb(
        gitlab_workhorse: {
          listen_network: 'unix'
        }
      )
    end

    describe '#unix_socket?' do
      it 'returns true' do
        expect(subject.unix_socket?).to be true
      end
    end
  end

  context 'object storage disabled' do
    cached(:chef_run) { converge_config }

    describe '#object_store_toml' do
      it 'returns nil' do
        expect(subject.object_store_toml).to be nil
      end
    end
  end

  context 'object storage enabled' do
    include_context 'object storage config'

    let(:chef_run) { converge_config }

    before do
      stub_gitlab_rb(
        gitlab_rails: {
          object_store: {
            enabled: true,
            connection: connection_hash,
            objects: object_config
          }
        }
      )
    end

    context 'with AWS' do
      let(:connection_hash) { aws_connection_hash }

      it 'returns valid TOML' do
        data = Tomlrb.parse(subject.object_store_toml)

        expect(data.dig('object_storage', 'provider')).to eq('AWS')

        s3_data = data.dig('object_storage', 's3')
        expect(s3_data).to be_a(Hash)
        expect(s3_data.keys.count).to eq(2)
        expect(s3_data['aws_access_key_id']).to eq(aws_connection_hash['aws_access_key_id'])
        expect(s3_data['aws_secret_access_key']).to eq(aws_connection_hash['aws_secret_access_key'])
      end
    end

    context 'with Azure' do
      let(:connection_hash) { azure_connection_hash }

      it 'returns valid TOML' do
        data = Tomlrb.parse(subject.object_store_toml)

        expect(data.dig('object_storage', 'provider')).to eq('AzureRM')

        az_data = data.dig('object_storage', 'azurerm')
        expect(az_data).to be_a(Hash)
        expect(az_data.keys.count).to eq(2)
        expect(az_data['azure_storage_account_name']).to eq(azure_connection_hash['azure_storage_account_name'])
        expect(az_data['azure_storage_access_key']).to eq(azure_connection_hash['azure_storage_access_key'])
      end
    end

    context 'with Google' do
      let(:connection_hash) { { 'provider' => 'Google' } }

      it 'returns nil' do
        expect(subject.object_store_toml).to be nil
      end
    end
  end
end
