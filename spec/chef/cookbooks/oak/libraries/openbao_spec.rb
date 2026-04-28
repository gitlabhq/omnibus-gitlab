require 'chef_helper'

RSpec.describe Oak::OpenBao do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.component_enabled?' do
    context 'when openbao component is not configured' do
      it 'returns false' do
        expect(described_class.component_enabled?).to be false
      end
    end

    context 'when openbao component is enabled' do
      before do
        stub_gitlab_rb(
          oak: {
            components: { 'openbao' => { 'enable' => true, 'internal_url' => 'http://10.0.0.5:8200' } }
          }
        )
      end

      it 'returns true' do
        expect(described_class.component_enabled?).to be true
      end
    end

    context 'when openbao component is disabled' do
      before do
        stub_gitlab_rb(
          oak: {
            components: { 'openbao' => { 'enable' => false, 'internal_url' => 'http://10.0.0.5:8200' } }
          }
        )
      end

      it 'returns false' do
        expect(described_class.component_enabled?).to be false
      end
    end
  end

  describe '.parse_variables' do
    context 'when OAK is disabled' do
      before { stub_gitlab_rb(gitlab_rails: {}) }

      it 'does not set openbao config' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']).to be_nil
      end
    end

    context 'when OAK is enabled but openbao component is disabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {},
          oak: {
            enable: true,
            network_address: '10.0.0.1',
            components: { 'openbao' => { 'enable' => false, 'internal_url' => 'http://10.0.0.5:8200', 'external_url' => nil } }
          }
        )
      end

      it 'does not set openbao config' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']).to be_nil
      end
    end

    context 'when OAK and openbao component are enabled without external_url' do
      before do
        stub_gitlab_rb(
          oak: {
            enable: true,
            network_address: '10.0.0.1',
            components: { 'openbao' => { 'enable' => true, 'internal_url' => 'http://10.0.0.5:8200' } }
          }
        )
      end

      it 'raises an error about the missing external_url' do
        expect { described_class.parse_variables }
          .to raise_error(RuntimeError, /oak\['components'\]\['openbao'\]\['external_url'\]/)
      end
    end

    context 'when OAK and openbao component are enabled without an internal_url' do
      before do
        stub_gitlab_rb(
          oak: {
            enable: true,
            network_address: '10.0.0.1',
            components: { 'openbao' => { 'enable' => true, 'external_url' => 'http://openbao.example.com' } }
          }
        )
      end

      it 'raises an error about the missing internal_url' do
        expect { described_class.parse_variables }
          .to raise_error(RuntimeError, /oak\['components'\]\['openbao'\]\['internal_url'\]/)
      end
    end

    context 'when OAK is enabled with openbao component and external_url' do
      before do
        stub_gitlab_rb(
          oak: {
            enable: true,
            network_address: '10.0.0.1',
            components: { 'openbao' => { 'enable' => true, 'internal_url' => 'http://10.0.0.5:8200', 'external_url' => 'http://openbao.example.com' } }
          }
        )
      end

      it 'sets openbao url to the external URL' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']['url']).to eq('http://openbao.example.com')
      end

      it 'sets openbao internal_url from the configured internal_url' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']['internal_url']).to eq('http://10.0.0.5:8200')
      end

      it 'sets the nginx fqdn from the external URL' do
        described_class.parse_variables

        expect(Gitlab['oak']['components']['openbao']['fqdn']).to eq('openbao.example.com')
      end

      it 'sets the nginx listen_port from the external URL' do
        described_class.parse_variables

        expect(Gitlab['oak']['components']['openbao']['listen_port']).to eq(80)
      end
    end

    context 'when the user has already set openbao url' do
      before do
        stub_gitlab_rb(
          oak: {
            enable: true,
            network_address: '10.0.0.1',
            components: { 'openbao' => { 'enable' => true, 'internal_url' => 'http://10.0.0.5:8200', 'external_url' => 'http://openbao.example.com' } }
          },
          gitlab_rails: {
            openbao: { url: 'https://vault.example.com' }
          }
        )
      end

      it 'does not override the user-defined url' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']['url']).to eq('https://vault.example.com')
      end

      it 'still infers internal_url when not set' do
        described_class.parse_variables

        expect(Gitlab['gitlab_rails']['openbao']['internal_url']).to eq('http://10.0.0.5:8200')
      end
    end
  end
end
