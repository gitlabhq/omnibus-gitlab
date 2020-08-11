require 'spec_helper'
require 'omnibus-ctl'

RSpec.describe 'gitlab-ctl geo-replication' do
  let(:toggle_command) { double(Geo::ReplicationToggleCommand) }

  subject { Omnibus::Ctl.new('testing-ctl') }

  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/replication_process'
    ) do
      require_relative('../../files/gitlab-ctl-commands-ee/lib/geo/replication_process')
    end
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/replication_toggle_command'
    ) do
      require_relative('../../files/gitlab-ctl-commands-ee/lib/geo/replication_toggle_command')
    end

    subject.load_file('files/gitlab-ctl-commands-ee/geo_replication.rb')
  end

  it 'appends the geo replication pause and resume commands' do
    expect(subject.get_all_commands_hash).to include('geo-replication-pause')
    expect(subject.get_all_commands_hash).to include('geo-replication-resume')
  end

  describe 'pause' do
    it 'calls pause' do
      expect(Geo::ReplicationToggleCommand).to receive(:new).with(anything, 'pause', anything).and_return(toggle_command)
      expect(toggle_command).to receive(:execute!)

      subject.geo_replication_pause
    end
  end

  describe 'resume' do
    it 'calls resume' do
      expect(Geo::ReplicationToggleCommand).to receive(:new).with(anything, 'resume', anything).and_return(toggle_command)
      expect(toggle_command).to receive(:execute!)

      subject.geo_replication_resume
    end
  end
end
