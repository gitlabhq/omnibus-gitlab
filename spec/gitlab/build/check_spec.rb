require 'spec_helper'
require 'gitlab/build/check'

describe Build::Check do
  describe 'is_ee?' do
    describe 'with environment variables' do
      it 'when ee=true' do
        stub_is_ee_env(true)
        expect(described_class.is_ee?).to be_truthy
      end

      it 'when ee=false' do
        stub_is_ee(false)
        expect(described_class.is_ee?).to be_falsy
      end

      it 'when env variable is not set' do
        stub_is_ee_version(false)
        expect(described_class.is_ee?).to be_falsy
      end
    end

    describe 'without environment variables' do
      it 'checks the VERSION file' do
        stub_is_ee_version(true)
        expect(described_class.is_ee?).to be_truthy
      end
    end
  end
  describe 'add tag methods' do
    describe 'add_nightly_tag?' do
      it 'returns true if it is a nightly build' do
        stub_env_var('NIGHTLY', 'true')
        expect(described_class.add_nightly_tag?).to be_truthy
      end

      it 'returns false if it is not a nightly build' do
        expect(described_class.add_nightly_tag?).to be_falsey
      end
    end

    describe 'add_rc_tag?' do
      it 'returns true if it is an rc release' do
        # This will be the case if latest_tag is eg. 9.3.0+rc6.ce.0
        # or 9.3.0+ce.0
        allow(Build::Info).to receive(:latest_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(true)
        expect(described_class.add_rc_tag?).to be_truthy
      end

      it 'returns true if it is not an rc release' do
        allow(Build::Info).to receive(:latest_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(false)
        expect(described_class.add_rc_tag?).to be_falsey
      end
    end

    describe 'add_latest_tag?' do
      it 'returns true if it is a stable release' do
        # This will be the case if latest_tag is eg. 9.3.0+ce.0
        # It will not be the case if the tag is 9.3.0+rc6.ce.0
        allow(Build::Info).to receive(:latest_stable_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(true)
        expect(described_class.add_latest_tag?).to be_truthy
      end

      it 'returns true if it is not a stable release' do
        allow(Build::Info).to receive(:latest_stable_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(false)
        expect(described_class.add_latest_tag?).to be_falsey
      end
    end
  end

  describe '.is_patch_release?' do
    it 'returns true for patch release' do
      allow(Build::Info).to receive(:semver_version).and_return("10.0.3")
      expect(described_class.is_patch_release?).to be_truthy
    end

    it 'returns false for major/minor release' do
      allow(Build::Info).to receive(:semver_version).and_return("10.0.0")
      expect(described_class.is_patch_release?).to be_falsey
    end
  end
end
