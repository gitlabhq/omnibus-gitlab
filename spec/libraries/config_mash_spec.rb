require 'spec_helper'
require_relative '../../files/gitlab-cookbooks/package/libraries/config_mash'

RSpec.describe Gitlab::ConfigMash do
  let(:mash) { Gitlab::ConfigMash.new }

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
