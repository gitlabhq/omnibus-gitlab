require 'spec_helper'
$LOAD_PATH << File.join(__dir__, '../../../../files/gitlab-ctl-commands/lib')

require 'postgresql/replication'

describe PostgreSQL::Replication do
  let(:ctl) { spy('gitlab ctl') }
  let(:util) { spy('gitlab ctl util', error?: false) }
  let(:attributes) { spy('node attributes spy') }

  subject { described_class.new(ctl) }

  before do
    stub_const('GitlabCtl::Util', util)

    allow(util).to receive(:get_node_attributes)
      .and_return(attributes)
  end

  it 'asks for the password' do
    expect(subject).to receive(:ask_password).and_return('pass').once

    subject.set_password!
  end

  it 'sets a password' do
    allow(subject).to receive(:ask_password).and_return('mypass')

    subject.set_password!

    expect(util).to have_received(:run_command)
      .with(%r{WITH ENCRYPTED PASSWORD 'mypass'})
  end

  it 'sets a password for user defined in `sql_replication_user` attribute' do
    allow(subject).to receive(:ask_password).and_return('mypass')
    allow(attributes).to receive(:to_s).and_return('myuser')

    subject.set_password!

    expect(util).to have_received(:run_command)
      .with(%r{ALTER USER myuser WITH ENCRYPTED PASSWORD 'mypass'})
  end

  it 'raises an error if replication user is not configured' do
    allow(subject).to receive(:ask_password).and_return('mypass')
    allow(attributes).to receive(:dig).and_return(nil)

    expect { subject.set_password! }.to raise_error(ArgumentError)
  end
end
