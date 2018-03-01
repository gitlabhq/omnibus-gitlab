require 'spec_helper'
require_relative '../../files/gitlab-cookbooks/package/libraries/config/gitlab'

describe Gitlab do
  context 'when using an attribute_block' do
    it 'sets top level attributes to the provided root' do
      Gitlab.attribute_block('gitlab') do
        expect(Gitlab.attribute('test_attribute')[:parent]).to eq 'gitlab'
      end
      expect(Gitlab['test_attribute']).not_to be_nil
      expect(Gitlab.hyphenate_config_keys['gitlab']).to include('test-attribute')
    end
  end

  it 'sets top level attributes when no parent is provided' do
    Gitlab.attribute('test_attribute')
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.hyphenate_config_keys).to include('test-attribute')
  end

  it 'properly defines roles' do
    role = Gitlab.role('test_node')
    expect(Gitlab['test_node_role']).not_to be_nil
    expect(Gitlab.hyphenate_config_keys['roles']).to include('test-node')
    expect(role).to include(manage_services: true)
  end

  it 'supports overriding role default configuration' do
    role = Gitlab.role('test_node', manage_services: false)
    expect(Gitlab['test_node_role']).not_to be_nil
    expect(role).to include(manage_services: false)
  end

  it 'supports overriding attribute default configuration' do
    attribute = Gitlab.attribute('test_attribute', parent: 'example', priority: 40, enable: false, default: '')
    expect(Gitlab['test_attribute']).to eq('')
    expect(attribute).to include(parent: 'example', priority: 40, enable: false)
  end

  it 'disables ee attributes when EE is not enabled' do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('edition').and_return(:ce)
    expect(Gitlab.ee_attribute('test_attribute')[:ee]).to eq true
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.hyphenate_config_keys).not_to include('test-attribute')
  end

  it 'enables ee attributes when EE is enabled' do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('edition').and_return(:ee)
    expect(Gitlab.ee_attribute('test_attribute')[:ee]).to eq true
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.hyphenate_config_keys).to include('test-attribute')
  end

  it 'sorts attributes by sequence' do
    Gitlab.attribute('last', priority: 99)
    Gitlab.attribute('other1')
    Gitlab.attribute('first', priority: -99)
    Gitlab.attribute('other2')

    expect(Gitlab.send(:sorted_settings).first[0]).to eq 'first'
    expect(Gitlab.send(:sorted_settings).last[0]).to eq 'last'
  end

  it 'filters ee settings when sorting' do
    Gitlab.attribute('test_attribute1')
    Gitlab.attribute('test_attribute2', ee: true)
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('edition').and_return(:ce)
    expect(Gitlab.send(:sorted_settings).map(&:first)).to include('test_attribute1')
    expect(Gitlab.send(:sorted_settings).map(&:first)).not_to include('test_attribute2')
  end

  it 'allows passing a block to the attribute use method' do
    attribute = Gitlab.attribute('test_attribute').use { 'test' }
    expect(attribute.handler).to eq('test')
  end
end
