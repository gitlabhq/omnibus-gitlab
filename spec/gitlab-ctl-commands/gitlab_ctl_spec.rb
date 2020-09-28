require 'spec_helper'
require 'omnibus-ctl'

RSpec.describe 'gitlab-ctl' do
  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl/lib/gitlab_ctl'
    ) do
      require_relative('../../files/gitlab-ctl-commands/lib/gitlab_ctl')
    end
  end

  let(:ctl_dir) { "#{File.dirname(__FILE__)}/../../files/gitlab-ctl-commands" }

  it 'should be able to load all files' do
    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = [] # rubocop:disable Style/MutableConstant
    expect do
      ctl = Omnibus::Ctl.new('testing-ctl')
      ctl.load_files(@ctl_dir)
    end.not_to raise_error
    ARGV = oldargv
  end
end
