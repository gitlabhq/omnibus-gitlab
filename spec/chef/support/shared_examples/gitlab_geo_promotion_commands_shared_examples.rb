require 'spec_helper'

RSpec.shared_examples 'gitlab geo promotion commands' do
  it 'appends a geo replication command' do
    expect(ctl.get_all_commands_hash).to include(command_name)
  end

  it 'executes the command when called' do
    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = [] # rubocop:disable Style/MutableConstant

    expect_any_instance_of(klass).to receive(:execute)

    ctl.send(command_script)

    ARGV = oldargv
  end
end
