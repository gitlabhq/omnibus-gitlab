require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl/upgrade_check'

RSpec.describe GitlabCtl::UpgradeCheck do
  using RSpec::Parameterized::TableSyntax

  context 'not an upgrade' do
    it 'returns true' do
      expect(described_class.valid?(nil)).to be true
    end
  end

  context 'when following valid upgrade paths' do
    where(:old_version, :min_version) do
      '15.11.0' | '15.11'
      '15.11.0' | '15.11'
      '15.11.5' | '15.11'
      '16.3.0' | '16.3'
      '16.3.3' | '16.3'
      '17.1.0' | '16.3'
    end

    with_them do
      it "returns true" do
        stub_env_var('MIN_VERSION', min_version)
        expect(described_class.valid?(old_version)).to be true
      end
    end
  end

  context 'when following invalid upgrade paths' do
    where(:old_version, :min_version) do
      '15.11.0' | '16.3'
      '16.2.0' | '16.3'
      '16.2.4' | '16.3'
      '16.9.0' | '16.10'
    end

    with_them do
      it "returns false" do
        stub_env_var('MIN_VERSION', min_version)
        expect(described_class.valid?(old_version)).to be false
      end
    end
  end
end
