require 'chef_helper'

RSpec.describe Oak do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.parse_variables' do
    context 'when OAK is disabled' do
      it 'does not raise' do
        expect { described_class.parse_variables }.not_to raise_error
      end
    end

    context 'when OAK is enabled without a network_address' do
      before { stub_gitlab_rb(oak: { enable: true }) }

      it 'raises an error about the missing network_address' do
        expect { described_class.parse_variables }.to raise_error(RuntimeError, /oak\['network_address'\]/)
      end
    end

    context 'when OAK is enabled with a network_address' do
      before { stub_gitlab_rb(oak: { enable: true, network_address: '10.0.0.1' }) }

      it 'does not raise' do
        expect { described_class.parse_variables }.not_to raise_error
      end
    end
  end

  describe '.enabled?' do
    context 'when oak enable is true' do
      before { stub_gitlab_rb(oak: { enable: true }) }

      it 'returns true' do
        expect(described_class.enabled?).to be true
      end
    end

    context 'when oak enable is false' do
      it 'returns false' do
        expect(described_class.enabled?).to be false
      end
    end

    context 'when oak enable is nil' do
      before { stub_gitlab_rb(oak: { enable: nil }) }

      it 'returns false' do
        expect(described_class.enabled?).to be false
      end
    end
  end
end
