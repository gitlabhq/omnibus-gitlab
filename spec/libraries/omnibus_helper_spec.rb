require 'chef_helper'
require_relative '../../files/gitlab-cookbooks/gitlab/libraries/omnibus_helper.rb'

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  subject { described_class.new(chef_run.node) }

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
end
