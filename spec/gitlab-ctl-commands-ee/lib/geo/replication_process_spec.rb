require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands-ee/lib'
$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'geo/replication_process'
require 'gitlab_ctl/util'

describe Geo::ReplicationProcess do
  let(:error_text) { 'AN ERROR' }
  let(:good_status) { double('Command status', error?: false) }
  let(:bad_status) { double('Command status', error?: true, stdout: error_text) }
  let(:pause_cmd) { %r{gitlab-psql .* -c 'SELECT pg_wal_replay_pause\(\);'} }
  let(:resume_cmd) { %r{gitlab-psql .* -c 'SELECT pg_wal_replay_resume\(\);'} }
  let(:instance) { double(base_path: '/opt/gitlab/embedded', data_path: '/var/opt/gitlab/postgresql/data') }
  let(:db_name) { 'gitlab_db_name' }
  let(:options) do
    {
      db_name: db_name
    }
  end

  subject { described_class.new(instance, options) }

  describe '#pause' do
    it 'logs a message if the rake task throws an error' do
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-rake geo:replication:pause/).and_return(bad_status)
      expect(GitlabCtl::Util).to receive(:run_command).with(pause_cmd).and_return(good_status)

      expect do
        subject.pause
      end.to output(/#{error_text}/).to_stdout
    end

    it 'raises an exception if unable to pause replication' do
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-rake geo:replication:pause/).and_return(good_status)
      expect(GitlabCtl::Util).to receive(:run_command).with(pause_cmd).and_return(bad_status)

      expect do
        subject.pause
      end.to raise_error(/Unable to pause postgres replication/)
    end

    it 'provides the requested database from the options' do
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-rake geo:replication:pause/).and_return(good_status)
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-psql -d #{db_name}/).and_return(good_status)

      subject.pause
    end
  end

  describe '#resume' do
    it 'raises an exception if unable to resume pg replication' do
      expect(GitlabCtl::Util).to receive(:run_command).with(resume_cmd).and_return(bad_status)

      expect do
        subject.resume
      end.to raise_error(/Unable to resume postgres replication/)
    end

    it 'raises an error if rake task to resume fails' do
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-rake geo:replication:resume/).and_return(bad_status)
      expect(GitlabCtl::Util).to receive(:run_command).with(resume_cmd).and_return(good_status)

      expect do
        subject.resume
      end.to raise_error(/Unable to resume replication from primary/)
    end

    it 'provides the requested database from the options' do
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-rake geo:replication:resume/).and_return(good_status)
      expect(GitlabCtl::Util).to receive(:run_command).with(/gitlab-psql -d #{db_name}/).and_return(good_status)

      subject.resume
    end
  end
end
