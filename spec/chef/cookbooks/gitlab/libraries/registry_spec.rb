require 'chef_helper'

RSpec.describe Registry do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'registry is disabled' do
    before do
      stub_gitlab_rb(
        registry: {
          enabled: false
        }
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'registry_external_url is set' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com'
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'lets encrypt is not enabled' do
    before do
      stub_gitlab_rb(
        letsencrypt: {
          enable: false
        }
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'external_url is a relative url' do
    before do
      stub_gitlab_rb(
        external_url: 'https://registry.example.com/path'
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  describe '.parse_database_configuration' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(Gitlab).to receive(:warn)
      allow(Gitlab['node']).to receive(:[]).with('registry').and_return({ 'database' => { 'enabled' => 'false' } })
    end

    describe 'host priority' do
      context 'with all possible hosts set' do
        before do
          stub_gitlab_rb(
            registry: {
              database: {
                host: 'explicit.db.host'
              }
            },
            postgresql: {
              listen_address: 'postgresql.internal',
              dir: 'postgresql.dir'
            }
          )
          allow(Gitlab['node']).to receive(:[]).with('postgresql').and_return({ 'listen_address' => 'node.db.host', 'dir' => 'node.db.dir' })
        end

        it 'uses registry the explicitly set host' do
          described_class.parse_database_configuration
          expect(Gitlab['registry']['database']['host']).to eq('explicit.db.host')
        end
      end

      context 'with all host but the explicit registry' do
        before do
          stub_gitlab_rb(
            postgresql: {
              listen_address: 'postgresql.internal',
              dir: 'postgresql.dir'
            }
          )
          allow(Gitlab['node']).to receive(:[]).with('postgresql').and_return({ 'listen_address' => 'node.db.host', 'dir' => 'node.db.dir' })
        end

        it 'uses postgresql listen_address' do
          described_class.parse_database_configuration
          expect(Gitlab['registry']['database']['host']).to eq('postgresql.internal')
        end
      end

      context 'with both postgresql node hosts' do
        before do
          allow(Gitlab['node']).to receive(:[]).with('postgresql').and_return({ 'listen_address' => 'node.db.host', 'dir' => 'node.db.dir' })
        end

        it 'uses postgresql node listen_address' do
          described_class.parse_database_configuration
          expect(Gitlab['registry']['database']['host']).to eq('node.db.host')
        end
      end

      context 'with only postgresql node dir' do
        before do
          allow(Gitlab['node']).to receive(:[]).with('postgresql').and_return({ 'listen_address' => nil, 'dir' => 'node.db.dir' })
        end

        it 'uses postgresql node listen_address' do
          described_class.parse_database_configuration
          expect(Gitlab['registry']['database']['host']).to eq('node.db.dir')
        end
      end

      context 'with multiple postgresql listen_addresses' do
        before do
          stub_gitlab_rb(
            postgresql: {
              listen_address: 'primary.db.host,secondary.db.host,tertiary.db.host'
            }
          )
        end

        it 'uses the first listen_address' do
          described_class.parse_database_configuration
          expect(Gitlab['registry']['database']['host']).to eq('primary.db.host')
        end

        it 'logs a warning about multiple addresses' do
          expect(described_class).to receive(:warn).with(
            "Received multiple postgresql address values.\n  First address from 'primary.db.host,secondary.db.host,tertiary.db.host' will be used for registry database."
          )
          described_class.parse_database_configuration
        end
      end
    end
  end
end
