require 'chef_helper'

describe 'account' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(account))
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_package::account_create') }

    it 'creates user' do
      expect(chef_run).to create_user('foobar').with_username('foo')
      expect(chef_run).to create_group('foobar').with_group_name('bar')
    end
  end

  context 'remove' do
    let(:chef_run) { runner.converge('test_package::account_remove') }

    it 'remove user' do
      expect(chef_run).to remove_user('foo')
      expect(chef_run).to remove_group('bar')
    end
  end
end
