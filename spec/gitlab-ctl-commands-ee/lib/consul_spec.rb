require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'consul'

RSpec.describe ConsulHandler do
  describe '#initialize' do
    it 'creates instance based on args' do
      instance = ConsulHandler.new([nil, nil, 'consul', 'kv', 'set'], 'rspec')
      expect(instance.command).to eq(ConsulHandler::Kv)
      expect(instance.subcommand).to eq('set')
      expect(instance.input).to eq('rspec')
    end
  end

  describe '#execute' do
    it 'calls the method on command' do
      instance = ConsulHandler.new([nil, nil, 'consul', 'kv', 'set'], 'rspec')
      instance.command = spy
      expect(instance.command).to receive(:set).with('rspec')
      instance.execute
    end
  end
end

RSpec.describe ConsulHandler::Kv do
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }

  it 'allows nil values' do
    results = double('results', run_command: [], error!: nil, stdout: '')
    expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv put foo ").and_return(results)
    described_class.send(:put, 'foo')
  end

  describe '#get' do
    context 'existing key' do
      before do
        results = double('results', run_command: [], error!: nil, stdout: 'bar')
        allow(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv get foo").and_return(results)
      end

      it 'returns the expected key' do
        expect(described_class.get('foo')).to eq('bar')
      end
    end

    context 'non-existing key' do
      before do
        results = double('results', run_command: [], stdout: '', stderr: 'oops')
        allow(results).to receive(:error!).and_raise(StandardError)
        allow(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv get foo").and_return(results)
      end

      it 'raises an error' do
        expect { described_class.get('foo') }.to raise_error(ConsulHandler::ConsulError, 'StandardError: oops')
      end
    end
  end
end
