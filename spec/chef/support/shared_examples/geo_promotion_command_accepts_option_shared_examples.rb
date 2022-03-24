require 'spec_helper'

RSpec.shared_examples 'geo promotion command accepts option' do |passed_option, expected_option|
  it 'accepts given option' do
    allow_any_instance_of(klass).to receive(:execute).and_return(true)

    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = [passed_option] # rubocop:disable Style/MutableConstant

    expect(klass).to receive(:new).with(
      anything, expected_option).and_call_original

    ctl.send(command_script, ARGV)

    ARGV = oldargv
  end
end
