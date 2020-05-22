require 'spec_helper'
require 'omnibus-ctl'

RSpec.shared_examples 'gitlab geo commands' do |command_name, klass, command_script|
  subject(:ctl) { Omnibus::Ctl.new('testing-ctl') }

  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      "/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/#{command_script}"
    ) do
      require_relative("../../../files/gitlab-ctl-commands-ee/lib/geo/#{command_script}")
    end

    ctl.load_file("files/gitlab-ctl-commands-ee/#{command_script}.rb")
  end

  it 'appends a geo replication command' do
    expect(subject.get_all_commands_hash).to include(command_name)
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
