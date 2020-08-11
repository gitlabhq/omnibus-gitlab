require 'chef_helper'

RSpec.describe OmnibusHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }

  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#user_exists?' do
    it 'returns true when user exists' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("id -u root").and_return(true)
      expect(subject.user_exists?('root')).to be_truthy
    end

    it 'returns false when user does not exist' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("id -u nonexistentuser").and_return(false)
      expect(subject.user_exists?('nonexistentuser')).to be_falsey
    end
  end

  describe '#group_exists?' do
    it 'returns true when group exists' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("getent group root").and_return(true)
      expect(subject.group_exists?('root')).to be_truthy
    end

    it 'returns false when group does not exist' do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with("getent group nonexistentgroup").and_return(false)
      expect(subject.group_exists?('nonexistentgroup')).to be_falsey
    end
  end

  describe '#not_listening?' do
    let(:chef_run) { converge_config }
    context 'when Redis is disabled' do
      before do
        stub_gitlab_rb(
          redis: { enable: false }
        )
      end

      it 'returns true when service is disabled' do
        expect(subject.not_listening?('redis')).to be_truthy
      end
    end

    context 'when Redis is enabled' do
      before do
        stub_gitlab_rb(
          redis: { enable: true }
        )
      end

      it 'returns true when service is down' do
        stub_service_failure_status('redis', true)

        expect(subject.not_listening?('redis')).to be_truthy
      end

      it 'returns false when service is up' do
        stub_service_failure_status('redis', false)

        expect(subject.not_listening?('redis')).to be_falsey
      end
    end
  end

  describe '#service_enabled?' do
    context 'services are enabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = true
        chef_run.node.normal['new_service']['enable'] = true
        chef_run.node.normal['monitoring']['another_service']['enable'] = true
      end

      it 'should return true' do
        expect(subject.service_enabled?('old_service')).to be_truthy
        expect(subject.service_enabled?('new_service')).to be_truthy
        expect(subject.service_enabled?('another_service')).to be_truthy
      end
    end

    context 'services are disabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = false
        chef_run.node.normal['new_service']['enable'] = false
        chef_run.node.normal['monitoring']['another_service']['enable'] = false
      end

      it 'should return false' do
        expect(subject.service_enabled?('old_service')).to be_falsey
        expect(subject.service_enabled?('new_service')).to be_falsey
        expect(subject.service_enabled?('another_service')).to be_falsey
      end
    end

    context 'sidekiq-cluster service migration' do
      context 'when sidekiq-cluster is enabled through the old configuration' do
        before do
          chef_run.node.normal['gitlab']['sidekiq-cluster']['enable'] = true
          chef_run.node.normal['gitlab']['sidekiq']['enable'] = true
          chef_run.node.normal['gitlab']['sidekiq']['cluster'] = false
        end

        it 'reports both sidekiq and sidekiq-cluster as enabled' do
          expect(subject.service_enabled?('sidekiq')).to be_truthy
          expect(subject.service_enabled?('sidekiq-cluster')).to be_truthy
        end
      end

      context 'when sidekiq-cluster is enabled through the sidekiq configuration' do
        before do
          chef_run.node.normal['gitlab']['sidekiq']['enable'] = false
          chef_run.node.normal['gitlab']['sidekiq-cluster']['enable'] = true
          chef_run.node.normal['gitlab']['sidekiq']['cluster'] = true
        end

        it 'reports only the sidekiq service as enabled' do
          expect(subject.service_enabled?('sidekiq')).to be_truthy
          expect(subject.service_enabled?('sidekiq-cluster')).to be_falsy
        end
      end
    end
  end

  describe '#is_managed_and_offline?' do
    context 'services are disabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = false
        chef_run.node.normal['new_service']['enable'] = false
      end

      it 'returns false' do
        expect(subject.is_managed_and_offline?('old_service')).to be_falsey
        expect(subject.is_managed_and_offline?('new_service')).to be_falsey
      end
    end

    context 'services are enabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = true
        chef_run.node.normal['new_service']['enable'] = true
      end

      it 'returns true when services are offline' do
        stub_service_failure_status('old_service', true)
        stub_service_failure_status('new_service', true)

        expect(subject.is_managed_and_offline?('old_service')).to be_truthy
        expect(subject.is_managed_and_offline?('new_service')).to be_truthy
      end

      it 'returns false when services are online ' do
        stub_service_failure_status('old_service', false)
        stub_service_failure_status('new_service', false)

        expect(subject.is_managed_and_offline?('old_service')).to be_falsey
        expect(subject.is_managed_and_offline?('new_service')).to be_falsey
      end
    end
  end

  describe '#is_deprecated_os?' do
    before do
      allow(OmnibusHelper).to receive(:deprecated_os_list).and_return({ "raspbian-8.0" => "GitLab 11.8" })
    end

    it 'detects deprecated OS correctly' do
      allow_any_instance_of(Ohai::System).to receive(:data).and_return({ "platform" => "raspbian", "platform_version" => "8.0" })

      expect(LoggingHelper).to receive(:deprecation).with(/Your OS, raspbian-8.0, will be deprecated soon/)
      OmnibusHelper.is_deprecated_os?
    end

    it 'does not detects valid OS as deprecated' do
      allow_any_instance_of(Ohai::System).to receive(:data).and_return({ "platform" => "ubuntu", "platform_version" => "16.04.3" })
      expect(LoggingHelper).not_to receive(:deprecation)
      OmnibusHelper.is_deprecated_os?
    end
  end

  describe '#is_deprecated_praefect_config?' do
    before do
      chef_run.node.normal['praefect'] = config
    end

    context 'deprecated config' do
      let(:config) do
        {
          storage_nodes: [
            { storage: 'praefect1', address: 'tcp://node1.internal' },
            { storage: 'praefect2', address: 'tcp://node2.internal' }
          ]
        }
      end

      it 'detects deprecated config correctly' do
        expect(LoggingHelper).to receive(:deprecation)
          .with(/Specifying Praefect storage nodes as an array is deprecated/)

        subject.is_deprecated_praefect_config?
      end
    end

    context 'valid config' do
      let(:config) do
        {
          storage_nodes: {
            'praefect1' => { address: 'tcp://node1.internal' },
            'praefect2' => { address: 'tcp://node2.internal' }
          }
        }
      end

      it 'does not detect a valid config as deprecated' do
        expect(LoggingHelper).not_to receive(:deprecation)

        subject.is_deprecated_praefect_config?
      end
    end
  end

  describe '#check_locale' do
    let(:error_message) { "Identified encoding is not UTF-8. GitLab requires UTF-8 encoding to function properly. Please check your locale settings." }

    describe 'using LC_ALL variable' do
      it 'does not raise a warning when set to a UTF-8 locale even if others are not' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return('en_US.UTF-8')
        allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_SG ISO-8859-1')
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_SG ISO-8859-1')
        allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

        expect(LoggingHelper).not_to receive(:warning).with("Environment variable .* specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

        described_class.check_locale
      end

      it 'raises warning when LC_ALL is non-UTF-8' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return('en_SG ISO-8859-1')

        expect(LoggingHelper).to receive(:warning).with("Environment variable LC_ALL specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

        described_class.check_locale
      end
    end

    describe 'using LC_CTYPE variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
      end

      it 'raises warning when LC_CTYPE is non-UTF-8' do
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_SG ISO-8859-1')

        expect(LoggingHelper).to receive(:warning).with("Environment variable LC_CTYPE specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

        described_class.check_locale
      end
    end

    describe 'using LC_COLLATE variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
        allow(ENV).to receive(:[]).with('LC_CTYPE').and_return(nil)
      end

      it 'raises warning when LC_COLLATE is non-UTF-8' do
        allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_SG ISO-8859-1')

        expect(LoggingHelper).to receive(:warning).with("Environment variable LC_COLLATE specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

        described_class.check_locale
      end
    end

    describe 'using LANG variable' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LC_ALL').and_return(nil)
      end

      context 'without LC_CTYPE and LC_COLLATE' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return(nil)
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return(nil)
        end

        it 'raises warning when LANG is non-UTF-8' do
          allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

          expect(LoggingHelper).to receive(:warning).with("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

          described_class.check_locale
        end
      end

      context 'with only LC_CTYPE set to UTF-8' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_US.UTF-8')
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return(nil)
        end

        it 'raises warning when LANG is non-UTF-8' do
          allow(ENV).to receive(:[]).with('LANG').and_return('en_SG ISO-8859-1')

          expect(LoggingHelper).to receive(:warning).with("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

          described_class.check_locale
        end
      end

      context 'with both LC_CTYPE and LC_COLLATE set to UTF-8' do
        before do
          allow(ENV).to receive(:[]).with('LC_CTYPE').and_return('en_US.UTF-8')
          allow(ENV).to receive(:[]).with('LC_COLLATE').and_return('en_US.UTF-8')
        end

        it 'does not raise a warning even if LANG is not UTF-8' do
          expect(LoggingHelper).not_to receive(:warning).with("Environment variable LANG specifies a non-UTF-8 locale. GitLab requires UTF-8 encoding to function properly. Please check your locale settings.")

          described_class.check_locale
        end
      end
    end
  end

  describe '#sidekiq_cluster_name' do
    let(:chef_run) { converge_config }

    it "returns 'sidekiq' if the service was enabled through sidekiq configuration" do
      stub_gitlab_rb(sidekiq: { cluster: true })

      expect(subject.sidekiq_cluster_service_name).to eq('sidekiq')
    end

    it "returns 'sidekiq-cluster' if the service was enabled through old configuration" do
      stub_gitlab_rb(sidekiq_cluster: { enable: true, queue_groups: ['*'] })

      expect(subject.sidekiq_cluster_service_name).to eq('sidekiq-cluster')
    end
  end
end
