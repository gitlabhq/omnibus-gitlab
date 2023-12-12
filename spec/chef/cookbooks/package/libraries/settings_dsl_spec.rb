require 'chef_helper'

RSpec.describe SettingsDSL::Utils do
  subject { described_class }

  describe '.service_name' do
    it 'returns hyphenated form of service name' do
      expect(subject.service_name('foo-bar')).to eq('foo-bar')
      expect(subject.service_name('foo_bar')).to eq('foo-bar')
    end
  end

  describe '.node_attribute_key' do
    it 'returns underscored form of service name' do
      expect(subject.node_attribute_key('foo-bar')).to eq('foo_bar')
      expect(subject.node_attribute_key('foo_bar')).to eq('foo_bar')
    end
  end

  describe 'secrets generation' do
    let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    describe 'default secrets' do
      context 'by default' do
        it 'generates default secrets' do
          expect(GitlabRails).to receive(:parse_secrets)

          chef_run
        end
      end

      context 'when explicitly disabled' do
        before do
          stub_gitlab_rb(
            package: {
              generate_default_secrets: false
            }
          )
        end

        it 'does not generate default secrets' do
          expect(GitlabRails).not_to receive(:parse_secrets)

          chef_run
        end
      end
    end

    describe 'gitlab-secrets.json file' do
      let(:file) { double(:file, puts: true, chmod: true) }

      before do
        allow(::File).to receive(:directory?).and_call_original
        allow(::File).to receive(:directory?).with('/etc/gitlab').and_return(true)
        allow(::File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600).and_yield(file).once
      end

      context 'by default' do
        it 'generates gitlab-secrets.json file' do
          expect(::File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600)

          chef_run
        end
      end

      context 'when explicitly disabled' do
        before do
          stub_gitlab_rb(
            package: {
              generate_secrets_json_file: false
            }
          )

          allow(LoggingHelper).to receive(:warning).and_call_original
        end

        it 'does not generate gitlab-secrets.json file' do
          expect(::File).not_to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600)

          chef_run
        end

        it 'generates warning about secrets not persisting' do
          expect(LoggingHelper).to receive(:warning).with(/You've enabled generating default secrets but have disabled writing them to \/etc\/gitlab\/gitlab-secrets.json file/)

          chef_run
        end
      end
    end
  end
end
