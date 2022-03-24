# frozen_string_literal: true

require 'chef_helper'

RSpec.describe NodeHelper do
  let(:chef_run) { converge_config }
  subject { described_class }

  describe '.consume_cluster_attributes' do
    it 'merges new attributes into node as override level' do
      new_attrs = ::Gitlab::ConfigMash.new(geo_primary: true)

      subject.consume_cluster_attributes(chef_run.node, new_attrs)

      expect(chef_run.node.attributes).to include(geo_primary: true)
      expect(chef_run.node.override).to include(geo_primary: true)
    end

    it 'merges overwritting existing attributes into node as override level' do
      allow(Gitlab).to receive(:[]).and_call_original
      stub_gitlab_rb(package: { custom: true })

      expect(chef_run.node.attributes['package']['custom']).to be true

      new_attrs = ::Gitlab::ConfigMash.new(package: { custom: false })
      subject.consume_cluster_attributes(chef_run.node, new_attrs)

      expect(chef_run.node.attributes['package']['custom']).to be false
      expect(chef_run.node.override['package']['custom']).to be false
    end
  end
end
