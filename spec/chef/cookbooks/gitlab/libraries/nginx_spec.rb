require 'chef_helper'

RSpec.describe Nginx do
  let(:chef_run) { converge_config }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.parse_oak_network_binding' do
    context 'when OAK is disabled' do
      it 'does not modify listen_addresses' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['nginx']['listen_addresses']).to be_nil
      end
    end

    context 'when OAK is enabled' do
      before do
        stub_gitlab_rb(
          oak: {
            enable: true,
            network_address: '10.0.0.1'
          }
        )
      end

      it 'extends the listen_addresses with the oak network_address' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['nginx']['listen_addresses']).to eq(["*", "10.0.0.1"])
      end
    end

    context 'when OAK is enabled with a custom listen_addresses' do
      before do
        stub_gitlab_rb(
          nginx: { listen_addresses: ['1.2.3.4'] },
          oak: {
            enable: true,
            network_address: '10.0.0.1'
          }
        )
      end

      it 'preserves custom addresses and appends the network address' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['nginx']['listen_addresses']).to eq(['1.2.3.4', '10.0.0.1'])
      end
    end

    context 'when OAK is enabled and the address is already in listen_addresses' do
      before do
        stub_gitlab_rb(
          nginx: { listen_addresses: ['*', '10.0.0.1'] },
          oak: {
            enable: true,
            network_address: '10.0.0.1'
          }
        )
      end

      it 'does not duplicate the address' do
        Gitlab[:node] = chef_run.node

        expect(Gitlab['nginx']['listen_addresses'].count('10.0.0.1')).to eq(1)
      end
    end
  end
end
