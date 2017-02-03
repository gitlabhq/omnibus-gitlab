require 'omnibus-ctl'

require 'chef_helper'

module Kernel
  alias old_require require
  def require(path)
    fake_paths = {
      '/opt/testing-ctl/embedded/service/omnibus-ctl/lib/gitlab_ctl' => '../../files/gitlab-ctl-commands/lib/gitlab_ctl'
    }
    if fake_paths.keys.include?(path)
      require_relative(fake_paths[path])
    else
      old_require(path)
    end
  end
end

describe 'gitlab-ctl' do
  before(:all) do
    @ctl_dir = "#{File.dirname(__FILE__)}/../../files/gitlab-ctl-commands"
  end

  it 'should be able to load all files' do
    # ARGV contains the commands that were passed to rspec, which are
    # invalid for the omnibus-ctl commands
    oldargv = ARGV
    ARGV = []
    expect do
      ctl = Omnibus::Ctl.new('testing-ctl')
      ctl.load_files(@ctl_dir)
    end.to_not raise_error
    ARGV = oldargv
  end
end
