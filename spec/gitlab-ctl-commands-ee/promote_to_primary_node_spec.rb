require 'spec_helper'
require 'omnibus-ctl'

describe 'gitlab-ctl promote-to-primary-node' do
  subject(:ctl) { Omnibus::Ctl.new('testing-ctl') }

  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/promote_to_primary'
    ) do
      require_relative('../../files/gitlab-ctl-commands-ee/lib/geo/promote_to_primary')
    end

    ctl.load_file('files/gitlab-ctl-commands-ee/promote_to_primary_node.rb')
  end

  it 'appends a geo replication command' do
    expect(subject.get_all_commands_hash).to include('promote-to-primary-node')
  end

  it 'executes the command when called' do
    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = [] # rubocop:disable Style/MutableConstant

    expect_any_instance_of(Geo::PromoteToPrimary).to receive(:execute)

    ctl.promote_to_primary_node

    ARGV = oldargv
  end
end
