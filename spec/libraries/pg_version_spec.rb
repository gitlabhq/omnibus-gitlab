require 'chef_helper'

describe PGVersion do
  context '.parse' do
    it 'returns a PGVersion class when provided a value' do
      expect(PGVersion.parse('string')).to be_a(described_class)
    end

    it 'returns nil when not passed a value' do
      expect(PGVersion.parse(nil)).to be_nil
    end
  end

  context 'postgres 9.6' do
    it '.valid? validates version strings' do
      expect(PGVersion.new('9.6.0').valid?).to be true
      expect(PGVersion.new('9.6').valid?).to be true
      expect(PGVersion.new('9').valid?).to be false
      expect(PGVersion.new('9.6.0.0').valid?).to be false
      expect(PGVersion.new('i9').valid?).to be false
      expect(PGVersion.new('i9.6').valid?).to be false
      expect(PGVersion.new('9.6.0i').valid?).to be false
      expect(PGVersion.new('i9.6.0').valid?).to be false
    end

    it 'parses the correct version parts from a MAJOR only version' do
      version = PGVersion.new('9.6')

      expect(version.major).to eq '9.6'
      expect(version.minor).to be_nil
    end

    it 'parses the correct major version from a full version' do
      version = PGVersion.new('9.6.10')

      expect(version.major).to eq '9.6'
      expect(version.minor).to eq '10'
    end
  end

  context 'postgres 10+' do
    it '.valid? validates version strings' do
      expect(PGVersion.new('10.0.0').valid?).to be true
      expect(PGVersion.new('11.0').valid?).to be true
      expect(PGVersion.new('10').valid?).to be true
      expect(PGVersion.new('10.0.0.0').valid?).to be false
      expect(PGVersion.new('i10').valid?).to be false
      expect(PGVersion.new('i11.0').valid?).to be false
      expect(PGVersion.new('10.0.0i').valid?).to be false
      expect(PGVersion.new('i10.0.0').valid?).to be false
    end

    it 'parses the correct version parts from a MAJOR only version' do
      version = PGVersion.new('10')
      version_new = PGVersion.new('12')

      expect(version.major).to eq '10'
      expect(version.minor).to be_nil
      expect(version_new.major).to eq '12'
      expect(version_new.minor).to be_nil
    end

    it 'parses the correct major version from a full version' do
      version = PGVersion.new('10.5')
      version_new = PGVersion.new('12.122')

      expect(version.major).to eq '10'
      expect(version.minor).to eq '5'
      expect(version_new.major).to eq '12'
      expect(version_new.minor).to eq '122'
    end

    it 'ignores patch version' do
      version = PGVersion.new('10.5.3')
      version_new = PGVersion.new('12.122.3')

      expect(version.major).to eq '10'
      expect(version.minor).to eq '5'
      expect(version_new.major).to eq '12'
      expect(version_new.minor).to eq '122'
    end
  end
end
