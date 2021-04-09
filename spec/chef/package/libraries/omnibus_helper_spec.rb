# frozen_string_literal: true

require 'chef_helper'

RSpec.describe OmnibusHelper do
  cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  subject(:omnibus_helper) { described_class.new(chef_run.node) }

  describe '.resource_available?' do
    it 'returns false for a resource that exists but has not been loaded in runtime' do
      expect(omnibus_helper.resource_available?('runit_service[geo-logcursor]')).to be_falsey
    end

    it 'returns true for a resource that exists and is loaded in runtime' do
      expect(omnibus_helper.resource_available?('runit_service[logrotated]'))
    end
  end
end
