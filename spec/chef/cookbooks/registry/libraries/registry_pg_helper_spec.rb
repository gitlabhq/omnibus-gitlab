require 'chef_helper'

RSpec.describe RegistryPgHelper do
  let(:node) { chef_run.node }
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }
  let(:helper) { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    # Mock the is_ready? method to prevent actual database connection attempts during Chef run
    allow_any_instance_of(RegistryPgHelper).to receive(:is_ready?).and_return(true)
  end

  it 'inherits from PgHelper' do
    expect(helper).to be_a(PgHelper)
  end

  describe '#connection_info' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com',
        registry: {
          database: {
            enabled: true
          }
        }
      )
    end

    it 'builds connection info from registry database settings' do
      connection_info = helper.send(:connection_info)

      expect(connection_info.dbname).to eq('registry')
      expect(connection_info.pguser).to eq('registry')
      expect(connection_info.port).to eq(5432)
      # Host should be set by Registry.parse_database_configuration
      expect(connection_info.dbhost).not_to be_nil
    end
  end
end
