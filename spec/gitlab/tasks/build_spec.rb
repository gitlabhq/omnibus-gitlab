require 'chef_helper'

describe 'build:package', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/build'
  end

  before :each do
    task.reenable
  end

  it 'should default to log level info without arguments' do
    allow(Build).to receive(:exec)
    expect(Build).to receive(:exec).with('gitlab', 'info')
    task.invoke
  end

  it 'should allow different log levels' do
    allow(Build).to receive(:exec)
    expect(Build).to receive(:exec).with('gitlab', 'fakelevel')
    task.invoke('fakelevel')
  end
end
