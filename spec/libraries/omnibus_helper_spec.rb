require 'chef_helper'
require_relative '../../files/gitlab-cookbooks/gitlab/libraries/omnibus_helper.rb'

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  let(:node) { chef_run.node }

  subject { described_class.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#user_exists?' do
    it 'returns true when user exists' do
      expect(subject.user_exists?('root')).to be_truthy
    end

    it 'returns false when user does not exist' do
      expect(subject.user_exists?('nonexistentuser')).to be_falsey
    end
  end

  describe '#group_exists?' do
    it 'returns true when group exists' do
      expect(subject.group_exists?('root')).to be_truthy
    end

    it 'returns false when group does not exist' do
      expect(subject.group_exists?('nonexistentgroup')).to be_falsey
    end
  end

  describe '#not_listening?' do
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
end
