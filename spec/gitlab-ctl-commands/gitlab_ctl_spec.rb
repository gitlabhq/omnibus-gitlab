require 'omnibus-ctl'

require 'chef_helper'

describe 'gitlab-ctl' do
  before(:all) do
    @ctl_dir = "#{File.dirname(__FILE__)}/../../files/gitlab-ctl-commands"
  end

  it 'should be able to load all files' do
    expect do
      ctl = Omnibus::Ctl.new('testing-ctl')
      ctl.load_files(@ctl_dir)
    end.to_not raise_error
  end
end
