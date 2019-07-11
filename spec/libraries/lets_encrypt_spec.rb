require 'chef_helper'

describe LetsEncrypt do
  subject { ::LetsEncrypt }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context '.parse_variables' do
    it 'calls to parse_enable' do
      expect(subject).to receive(:parse_enable)

      subject.parse_variables
    end
  end

  context '.parse_enable' do
    context 'when specifying letsencrypt enabled' do
      context 'true' do
        before { stub_gitlab_rb(letsencrypt: { enable: true }) }

        it 'should not call should_auto_enable?' do
          expect(subject).not_to receive(:should_auto_enable?)

          subject.parse_enable
        end
      end

      context 'false' do
        before { stub_gitlab_rb(letsencrypt: { enable: false }) }

        it 'should not call should_auto_enable?' do
          expect(subject).not_to receive(:should_auto_enable?)

          subject.parse_enable
        end
      end

      context 'unspecified' do
        it 'should use the value of should_auto_enable' do
          allow(subject).to receive(:should_auto_enable?).and_return('bananas')
          subject.parse_enable

          expect(Gitlab['letsencrypt']['enable']).to eq('bananas')
        end
      end
    end
  end

  context '.should_auto_enable?' do
    let(:node) { Mash.new(gitlab: { nginx: {} }) }

    before do
      stub_gitlab_rb(
        gitlab_rails: {
          gitlab_https: true
        },
        nginx: {
          ssl_certificate_key: 'example.key',
          ssl_certificate: 'example.crt'
        }
      )

      allow(Gitlab).to receive(:[]).with(:node).and_return(node)
      allow(File).to receive(:exist?).with('example.key').and_return(false)
      allow(File).to receive(:exist?).with('example.crt').and_return(false)
    end

    it 'is true' do
      expect(subject.should_auto_enable?).to be_truthy
    end

    it 'is false when not using a https url' do
      stub_gitlab_rb(gitlab_rails: { gitlab_https: false })

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is false when nginx is not enabled' do
      stub_gitlab_rb(nginx: { enable: false })

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is false when nginx is disabled by roles' do
      allow(node['gitlab']['nginx']).to receive(:[]).with('enable').and_return(false)

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is false with explicit nginx.listen_https = false' do
      stub_gitlab_rb(nginx: { listen_https: false })

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is false with the key present' do
      allow(File).to receive(:exist?).with('example.key').and_return(true)

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is false with the cert present' do
      mock_cert = OpenSSL::X509::Certificate.new
      allow(mock_cert).to receive(:not_after).and_return(Time.now + 600)
      allow(File).to receive(:exist?).with('example.crt').and_return(true)
      allow(File).to receive(:read).with('example.crt').and_return(nil)
      allow(OpenSSL::X509::Certificate).to receive(:new).and_return(mock_cert)

      expect(subject.should_auto_enable?).to be_falsey
    end

    it 'is true when files present, but we provisioned them before' do
      stub_gitlab_rb(letsencrypt: { auto_enabled: true })

      allow(File).to receive(:exist?).with('example.key').and_return(true)
      allow(File).to receive(:exist?).with('example.crt').and_return(true)

      expect(subject.should_auto_enable?).to be_truthy
    end

    it 'is true when files present, but LE certificate is expired' do
      mock_cert = OpenSSL::X509::Certificate.new
      allow(mock_cert).to receive(:not_after).and_return(Time.now - 1)
      allow(mock_cert).to receive(:issuer).and_return(
        OpenSSL::X509::Name.parse(%(/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3)))
      allow(File).to receive(:exist?).with('example.key').and_return(true)
      allow(File).to receive(:exist?).with('example.crt').and_return(true)
      allow(File).to receive(:read).with('example.crt').and_return(nil)
      allow(OpenSSL::X509::Certificate).to receive(:new).and_return(mock_cert)

      expect(subject.should_auto_enable?).to be_truthy
    end

    it 'is false when files present, but non-LE certificate is expired' do
      mock_cert = OpenSSL::X509::Certificate.new
      allow(mock_cert).to receive(:not_after).and_return(Time.now - 1)
      allow(mock_cert).to receive(:issuer).and_return(
        OpenSSL::X509::Name.parse('/C=US/O=Example Corporation/CN=Example'))
      allow(File).to receive(:exist?).with('example.key').and_return(true)
      allow(File).to receive(:exist?).with('example.crt').and_return(true)
      allow(File).to receive(:read).with('example.crt').and_return(nil)
      allow(OpenSSL::X509::Certificate).to receive(:new).and_return(mock_cert)

      expect(subject.should_auto_enable?).to be_falsey
    end
  end

  context '.save_auto_enabled' do
    it 'does nothing if not auto_enabled' do
      expect(SecretsHelper).not_to receive(:load_gitlab_secrets)

      subject.save_auto_enabled
    end

    context 'auto_enabled' do
      before do
        stub_gitlab_rb(letsencrypt: { auto_enabled: true })
        allow(SecretsHelper).to receive(:load_gitlab_secrets).and_return({})
        allow(SecretsHelper).to receive(:write_to_gitlab_secrets)
      end

      it 'writes when secret is absent' do
        expect(SecretsHelper).to receive(:write_to_gitlab_secrets)

        subject.save_auto_enabled
      end

      it 'does not write if secret is already true' do
        allow(SecretsHelper).to receive(:load_gitlab_secrets)
          .and_return('letsencrypt' => { 'auto_enabled' => true })
        expect(SecretsHelper).not_to receive(:write_to_gitlab_secrets)

        subject.save_auto_enabled
      end
    end
  end
end
