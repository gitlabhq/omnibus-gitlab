require 'spec_helper'

RSpec.describe Gitlab::ConfigMash do
  subject(:mash) { described_class.new }

  describe '.auto_vivify?' do
    subject { described_class }

    it 'returns true when inside auto_vivify block' do
      subject.auto_vivify do
        expect(subject.auto_vivify?).to be_truthy
      end
    end

    it 'returns false when not in auto_vivify block' do
      expect(subject.auto_vivify?).to be_falsey
    end
  end

  describe '#[]' do
    it 'behaves like a normal Mash by default' do
      mash['param1'] = 'value1'
      expect(mash['param1']).to eq 'value1'
      expect(mash['param2']).to be_nil
      expect { mash['param2']['nested'] }.to raise_error(NoMethodError, /nil:NilClass/)
    end

    it 'allows nested undefined reads when in an auto-vivify block' do
      mash['param1'] = 'value1'
      expect(mash['param1']).to eq 'value1'
      expect(mash['param2']).to be_nil

      Gitlab::ConfigMash.auto_vivify do
        expect(mash['param2']).not_to be_nil
        expect { mash['param2']['nested'] }.not_to raise_error
        mash['param3']['enable'] = true
        expect(mash['param3']['enable']).to eq true
      end

      # confirm it is turned off after the block
      expect(mash['param4']).to be_nil
    end
  end

  describe 'convert_value' do
    it 'returns passed value when its a ConfigMash' do
      another_mash = Gitlab::ConfigMash.new

      converted = mash.convert_value(another_mash)

      expect(converted).to be_a(Gitlab::ConfigMash)
      expect(converted).to eq(another_mash)
    end

    it 'returns a ConfigMash with the same data when passed a Hash' do
      hash = { 'key' => 'value' }

      converted = mash.convert_value(hash)

      expect(converted).to be_a(Gitlab::ConfigMash)
      expect(converted.keys).to match_array('key')
      expect(converted.values).to match_array('value')
    end
  end
end
