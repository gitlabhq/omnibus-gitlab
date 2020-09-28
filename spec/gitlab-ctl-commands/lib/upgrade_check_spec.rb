require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl/upgrade_check'

RSpec.describe GitlabCtl::UpgradeCheck do
  let(:latest) { '13.1.3' }
  let(:previous_major) { '12.5.10' }
  let(:previous_major_latest) { '12.10.13' }
  let(:current_major) { '13.0.8' }
  let(:old) { '11.5.11' }

  context 'not an upgrade' do
    it 'returns true' do
      expect(described_class.valid?(nil, latest)).to be true
    end
  end

  context 'valid upgrade paths' do
    it 'returns true for an upgrade from the current major version' do
      expect(described_class.valid?(current_major, latest)).to be true
    end
  end

  context 'invalid upgrade paths' do
    it 'returns false for an upgrade from 11.5 to the latest' do
      expect(described_class.valid?(old, latest)).to be false
    end

    it 'returns false for an upgrade from 12.5 to the latest' do
      expect(described_class.valid?(previous_major, latest)).to be false
    end

    it 'returns false upgrading from previous_major_latest to the latest' do
      expect(described_class.valid?(previous_major_latest, latest)).to be false
    end
  end
end
