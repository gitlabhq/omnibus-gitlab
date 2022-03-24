# frozen_string_literal: true

require 'chef_helper'
require 'geo/promote_db'

RSpec.describe 'gitlab-ctl promote-db' do
  let(:klass) { Geo::PromoteDb }
  let(:command_name) { 'promote-db' }
  let(:command_script) { 'promote_db' }

  include_context 'ctl'

  it_behaves_like 'gitlab geo promotion commands', 'promote-db'

  # rubocop:disable Style/MutableConstant, Lint/ConstantDefinitionInBlock
  it 'prints the deprecation message' do
    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = []

    expect_any_instance_of(klass).to receive(:execute)

    expect { ctl.send(command_script) }.to output(
      /WARNING: As of GitLab 14.5, this command is deprecated/).to_stdout

    ARGV = oldargv
  end
  # rubocop:enable Style/MutableConstant, Lint/ConstantDefinitionInBlock
end
