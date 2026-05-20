require 'chef_helper'

RSpec.describe Puma do
  let(:chef_run) { converge_config }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    Gitlab[:node] = chef_run.node
  end

  describe '.nproc_cpu_count' do
    context 'when nproc succeeds' do
      it 'returns the integer value from nproc' do
        allow(described_class).to receive(:`).with('nproc 2>/dev/null').and_return("12\n")

        expect(described_class.send(:nproc_cpu_count)).to eq(12)
      end
    end

    context 'when nproc returns an empty string' do
      it 'returns 0' do
        allow(described_class).to receive(:`).with('nproc 2>/dev/null').and_return('')

        expect(described_class.send(:nproc_cpu_count)).to eq(0)
      end
    end

    context 'when nproc raises an error' do
      it 'returns 0' do
        allow(described_class).to receive(:`).with('nproc 2>/dev/null').and_raise(StandardError)

        expect(described_class.send(:nproc_cpu_count)).to eq(0)
      end
    end
  end

  describe '.cpu_threads' do
    context 'when Ohai CPU data is nil' do
      before do
        allow(Gitlab['node']).to receive(:[]).and_call_original
        allow(Gitlab['node']).to receive(:[]).with('cpu').and_return(nil)
      end

      it 'returns 1 regardless of nproc' do
        allow(described_class).to receive(:nproc_cpu_count).and_return(12)

        expect(described_class.cpu_threads).to eq(1)
      end
    end

    context 'when nproc is unavailable (returns 0)' do
      before do
        allow(described_class).to receive(:nproc_cpu_count).and_return(0)
      end

      it 'falls back to the Ohai CPU count' do
        allow(Gitlab['node']['cpu']).to receive(:[]).and_call_original
        allow(Gitlab['node']['cpu']).to receive(:[]).with('total').and_return(56)
        allow(Gitlab['node']['cpu']).to receive(:[]).with('real').and_return(28)

        expect(described_class.cpu_threads).to eq(56)
      end
    end

    context 'when nproc reports fewer CPUs than Ohai (container with cgroup limit)' do
      before do
        allow(described_class).to receive(:nproc_cpu_count).and_return(12)
        allow(Gitlab['node']['cpu']).to receive(:[]).and_call_original
        allow(Gitlab['node']['cpu']).to receive(:[]).with('total').and_return(56)
        allow(Gitlab['node']['cpu']).to receive(:[]).with('real').and_return(28)
      end

      it 'uses the nproc count (cgroup limit) instead of the Ohai host count' do
        expect(described_class.cpu_threads).to eq(12)
      end
    end

    context 'when nproc reports the same count as Ohai (bare metal)' do
      before do
        allow(described_class).to receive(:nproc_cpu_count).and_return(8)
        allow(Gitlab['node']['cpu']).to receive(:[]).and_call_original
        allow(Gitlab['node']['cpu']).to receive(:[]).with('total').and_return(8)
        allow(Gitlab['node']['cpu']).to receive(:[]).with('real').and_return(4)
      end

      it 'returns the Ohai count unchanged' do
        expect(described_class.cpu_threads).to eq(8)
      end
    end

    context 'when nproc reports more CPUs than Ohai' do
      before do
        allow(described_class).to receive(:nproc_cpu_count).and_return(16)
        allow(Gitlab['node']['cpu']).to receive(:[]).and_call_original
        allow(Gitlab['node']['cpu']).to receive(:[]).with('total').and_return(8)
        allow(Gitlab['node']['cpu']).to receive(:[]).with('real').and_return(4)
      end

      it 'uses the Ohai count (minimum of the two)' do
        expect(described_class.cpu_threads).to eq(8)
      end
    end
  end
end
