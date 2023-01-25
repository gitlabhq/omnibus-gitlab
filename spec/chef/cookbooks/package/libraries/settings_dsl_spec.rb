require 'chef_helper'

RSpec.describe SettingsDSL::Utils do
  subject { described_class }

  describe '.hyphenated_form' do
    it 'returns original string if no underscore exists' do
      expect(subject.hyphenated_form('foo-bar')).to eq('foo-bar')
    end

    it 'returns string with underscores replaced by hyphens' do
      expect(subject.hyphenated_form('foo_bar')).to eq('foo-bar')
    end
  end

  describe '.underscored_form' do
    it 'returns original string if no hyphen exists' do
      expect(subject.underscored_form('foo_bar')).to eq('foo_bar')
    end

    it 'returns string with hyphens replaced by underscores' do
      expect(subject.underscored_form('foo-bar')).to eq('foo_bar')
    end
  end
end
