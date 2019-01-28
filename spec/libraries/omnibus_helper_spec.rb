require 'chef_helper'

describe OmnibusHelper do
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
      end

      it 'should return true' do
        expect(subject.service_enabled?('old_service')).to be_truthy
        expect(subject.service_enabled?('new_service')).to be_truthy
      end
    end

    context 'services are disabled' do
      before do
        chef_run.node.normal['gitlab']['old_service']['enable'] = false
        chef_run.node.normal['new_service']['enable'] = false
      end

      it 'should return false' do
        expect(subject.service_enabled?('old_service')).to be_falsey
        expect(subject.service_enabled?('new_service')).to be_falsey
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
end
