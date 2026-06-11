require 'chef_helper'

RSpec.describe GitlabHealthcheckHelper do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when nginx is enabled' do
    before do
      stub_gitlab_rb(nginx: { enable: true })
    end

    describe '#web_node?' do
      it 'is true' do
        expect(subject.web_node?).to be true
      end
    end

    describe '#url' do
      it 'targets nginx on localhost using http and the default port' do
        expect(subject.url).to eq('http://localhost:80/help')
      end

      it 'uses https when external_url uses https' do
        stub_gitlab_rb(external_url: 'https://gitlab.example.com')
        expect(subject.url).to eq('https://localhost:443/help')
      end

      it 'uses http when administrators terminate TLS externally' do
        # For cases when administrators terminate TLS via a reverse
        # proxy, external_url will listen on `https` but `listen_https`
        # will be set to false. Ensure the helper always understands how
        # to evaluate and apply this scenario.
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          nginx: { listen_https: false }
        )
        expect(subject.url).to eq('http://localhost:443/help')
      end

      it 'uses the custom port from external_url' do
        stub_gitlab_rb(external_url: 'http://gitlab.example.com:8080')
        expect(subject.url).to eq('http://localhost:8080/help')
      end

      it 'includes the relative path from external_url' do
        stub_gitlab_rb(external_url: 'http://gitlab.example.com/custom')
        expect(subject.url).to eq('http://localhost:80/custom/help')
      end

      it 'still targets localhost when allowed_hosts is set' do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: { allowed_hosts: ['gitlab.example.com'] }
        )
        expect(subject.url).to eq('https://localhost:443/help')
      end
    end

    describe '#flags' do
      it 'includes --insecure by default' do
        expect(subject.flags).to eq(['--insecure'])
      end

      it 'prepends --haproxy-protocol when proxy_protocol is enabled' do
        stub_gitlab_rb(nginx: { proxy_protocol: true })
        expect(subject.flags).to eq(['--haproxy-protocol', '--insecure'])
      end

      it 'prepends a Host header when allowed_hosts is set' do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com',
          gitlab_rails: { allowed_hosts: ['gitlab.example.com'] }
        )
        expect(subject.flags).to eq(['--header "Host: gitlab.example.com"', '--insecure'])
      end
    end
  end

  context 'when nginx is disabled and workhorse is enabled' do
    before do
      stub_gitlab_rb(nginx: { enable: false })
    end

    describe '#web_node?' do
      it 'is true' do
        expect(subject.web_node?).to be true
      end
    end

    describe '#url' do
      it 'targets workhorse over http on the default unix socket' do
        expect(subject.url).to eq('http://localhost/help')
      end

      it 'targets the workhorse port when listening on a TCP socket' do
        stub_gitlab_rb(
          nginx: { enable: false },
          gitlab_workhorse: { listen_network: 'tcp', listen_addr: 'localhost:9191' }
        )
        expect(subject.url).to eq('http://localhost:9191/help')
      end
    end

    describe '#flags' do
      it 'uses --unix-socket pointing at the workhorse socket' do
        expect(subject.flags).to eq(['--unix-socket', '/var/opt/gitlab/gitlab-workhorse/sockets/socket'])
      end

      it 'uses --insecure when workhorse listens on a TCP socket' do
        stub_gitlab_rb(
          nginx: { enable: false },
          gitlab_workhorse: { listen_network: 'tcp', listen_addr: 'localhost:9191' }
        )
        expect(subject.flags).to eq(['--insecure'])
      end
    end
  end

  context 'when neither nginx nor workhorse is enabled' do
    before do
      stub_gitlab_rb(nginx: { enable: false }, gitlab_workhorse: { enable: false })
    end

    describe '#web_node?' do
      it 'is false' do
        expect(subject.web_node?).to be false
      end
    end

    describe '#url' do
      it 'is nil' do
        expect(subject.url).to be_nil
      end
    end

    describe '#flags' do
      it 'is empty' do
        expect(subject.flags).to eq([])
      end
    end
  end
end
