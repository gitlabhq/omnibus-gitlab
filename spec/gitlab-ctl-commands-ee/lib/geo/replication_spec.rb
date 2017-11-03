$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
require 'geo/replication'

describe Geo::Replication, '#execute' do
  let(:command) { spy('command spy', error?: false) }
  let(:ctl) { spy('gitlab ctl spy') }
  let(:options) { { now: true } }

  subject { described_class.new(ctl, options) }

  before do
    allow(STDOUT).to receive(:puts)

    stub_const('GitlabCtl::Util', command)
  end

  it 'replicates geo database' do
    expect(subject).to receive(:ask_pass).and_return('password')
    expect(subject).to receive(:create_gitlab_backup!)
    expect(subject).to receive(:create_recovery_file!)
    expect(subject).to receive(:create_pgpass_file!)

    subject.execute

    expect(command).to have_received(:run_command)
      .with(%r{/embedded/bin/pg_basebackup}, anything)
  end

  context 'when there is TTY available' do
    before do
      allow(STDIN).to receive(:tty?).and_return(true)
    end

    it 'asks for database password in an internative mode' do
      expect(subject).to receive(:create_gitlab_backup!)
      expect(subject).to receive(:create_recovery_file!)
      expect(subject).to receive(:create_pgpass_file!)

      expect(STDIN).to receive(:getpass).and_return('password')

      subject.execute
    end
  end

  context 'when there is no TTY available' do
    before do
      allow(STDIN).to receive(:tty?).and_return(false)
    end

    it 'asks for a database password in a non-interactive mode' do
      expect(subject).to receive(:create_gitlab_backup!)
      expect(subject).to receive(:create_recovery_file!)
      expect(subject).to receive(:create_pgpass_file!)
      expect(STDIN).to receive(:gets)

      subject.execute
    end
  end
end
