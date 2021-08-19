# frozen_string_literal: true

require 'chef_helper'

RSpec.describe Gitlab do
  describe 'merge_cluster_attribute!' do
    subject { described_class }

    it 'merges a single provided attribute with Gitlab config' do
      subject.merge_cluster_attribute!('primary', false)

      expect(Gitlab['primary']).to eq(false)
    end

    it 'merges a attribute in a nested path with Gitlab config' do
      subject.merge_cluster_attribute!('patroni', 'standby_cluster', 'enable', true)

      expect(Gitlab['patroni']['standby_cluster']['enable']).to eq(true)
    end

    it 'does not merge the attribute if the value is nil' do
      subject.merge_cluster_attribute!('foo', 'bar', nil)

      expect(Gitlab['foo']).to be_nil
    end
  end
end
