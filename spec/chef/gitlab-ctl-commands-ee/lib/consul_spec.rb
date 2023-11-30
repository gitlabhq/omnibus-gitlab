require 'spec_helper'
require 'consul'
require 'consul_download'

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

  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }

  describe ConsulHandler::Kv do
    before(:each) do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return('consul' => { 'binary_path' => consul_cmd })
    end

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

  describe ConsulHandler::Encrypt do
    before(:each) do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return('consul' => { 'binary_path' => consul_cmd })
    end

    describe '#keygen' do
      it 'returns the generated key' do
        generated_key = 'BYX6EPaUiUI0TDdm6gAMmmLnpJSwePJ33Xwh6rjCYbg='
        results = double('results', run_command: [], error!: nil, stdout: generated_key)
        allow(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} keygen").and_return(results)

        expect(described_class.keygen).to eq(generated_key)
      end

      it 'raises an error' do
        results = double('results', run_command: [], stdout: '', stderr: 'oops')
        allow(results).to receive(:error!).and_raise(StandardError)
        allow(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} keygen").and_return(results)

        expect { described_class.keygen }.to raise_error(ConsulHandler::ConsulError, 'StandardError: oops')
      end
    end
  end
end

RSpec.describe ConsulDownloadCommand do
  let(:command) do
    described_class.new([
                          '', '',
                          '--arch', 'amd64',
                          '--output', '/tmp/consul',
                          '--force', true,
                          '--version', '1.16.1',
                        ])
  end

  it 'downloads consul' do
    consul_zip = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry("consul")
      zio.write "binary"
      zio.put_next_entry("foo")
      zio.write "bar"
    end
    mock_response = Net::HTTPSuccess.new('1.0', '200', '')
    expect(mock_response).to receive(:body).and_return(consul_zip.string)

    expect(GitlabCtl::Util)
      .to receive(:get_node_attributes)
      .and_return({ 'kernel' => { 'machine' => 'amd64' } })
    expect(Net::HTTP).to receive(:get_response)
      .with(URI.parse('https://releases.hashicorp.com/consul/1.16.1/consul_1.16.1_linux_amd64.zip'))
      .and_return(mock_response)
    expect(File)
      .to receive(:write)
      .with('/tmp/consul', 'binary')
    expect(File)
      .to receive(:chmod)
      .with(0755, '/tmp/consul')

    command.run
  end
end
