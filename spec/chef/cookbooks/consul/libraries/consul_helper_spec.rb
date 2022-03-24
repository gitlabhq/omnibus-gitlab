require 'chef_helper'

RSpec.describe ConsulHelper do
  let(:chef_run) { converge_config }
  subject { described_class.new(chef_run.node) }

  describe '#running_version' do
    let(:consul_api_output) { instance_double('response', code: '200', body: '{"Config": { "Version": "1.8.10" }}') }

    before do
      # Un-doing the stub added in chef_helper
      allow_any_instance_of(described_class).to receive(:running_version).and_call_original
      allow(Gitlab).to receive(:[]).and_call_original
      allow(subject).to receive(:get_api).and_yield(consul_api_output)
    end

    context 'when consul is not running' do
      it 'returns nil' do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('consul').and_return(false)

        expect(subject.running_version).to be_nil
      end
    end

    context 'when consul is running' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('consul').and_return(true)
      end

      it 'parses version from consul api output properly' do
        expect(subject.running_version).to eq('1.8.10')
      end
    end
  end

  describe '#installed_version' do
    let(:consul_cli_output) do
      <<~MSG
        Consul v1.7.8
        Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)
      MSG
    end

    before do
      # Un-doing the stub added in chef_helper
      allow_any_instance_of(described_class).to receive(:installed_version).and_call_original
      allow(Gitlab).to receive(:[]).and_call_original
      allow(VersionHelper).to receive(:version).with(/consul version/).and_return(consul_cli_output)
    end

    context 'when consul is not running' do
      it 'returns nil' do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('consul').and_return(false)

        expect(subject.installed_version).to be_nil
      end
    end

    context 'when consul is running' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('consul').and_return(true)
      end

      it 'parses consul output properly' do
        expect(subject.installed_version).to eq('1.7.8')
      end
    end
  end

  describe '#api_port' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    it 'falls back to default ports' do
      stub_gitlab_rb(
        consul: {
          enable: true
        }
      )

      expect(subject.api_port('http')).to eq(8500)
      expect(subject.api_port('https')).to eq(8501)
      expect(subject.configuration).not_to match(%r{"http":8500})
      expect(subject.configuration).not_to match(%r{"https":8501})
    end

    it 'uses the configured ports' do
      stub_gitlab_rb(
        consul: {
          enable: true,
          http_port: 18500,
          https_port: 18501
        }
      )

      expect(subject.api_port('http')).to eq(18500)
      expect(subject.api_port('https')).to eq(18501)
      expect(subject.configuration).to match(%r{"http":18500})
      expect(subject.configuration).to match(%r{"https":18501})
    end

    it 'uses the ports from configuration override' do
      stub_gitlab_rb(
        consul: {
          enable: true,
          http_port: 18500,
          https_port: 18501,
          configuration: {
            ports: {
              http: 28500,
              https: 28501,
            }
          }
        }
      )

      expect(subject.api_port('http')).to eq(28500)
      expect(subject.api_port('https')).to eq(28501)
      expect(subject.configuration).to match(%r{"http":28500})
      expect(subject.configuration).to match(%r{"https":28501})
    end
  end

  describe '#api_url' do
    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    it 'uses http by default' do
      stub_gitlab_rb(
        consul: {
          enable: true
        }
      )

      expect(subject.api_url).to eq('http://localhost:8500')
    end

    it 'uses https when tls is enabled' do
      stub_gitlab_rb(
        consul: {
          enable: true,
          use_tls: true
        }
      )

      expect(subject.api_url).to eq('https://localhost:8501')
    end

    it 'uses https when http port is disabled' do
      stub_gitlab_rb(
        consul: {
          enable: true,
          http_port: -1
        }
      )

      expect(subject.api_url).to eq('https://localhost:8501')
    end
  end
end
