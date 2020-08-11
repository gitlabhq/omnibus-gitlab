require 'spec_helper'
require 'omnibus-ctl'

RSpec.describe 'gitlab-ctl replicate-geo-database' do
  subject { Omnibus::Ctl.new('testing-ctl') }

  let(:required_arguments) do
    %w(--host=gitlab-primary.geo
       --slot-name=gitlab_primary_geo)
  end

  before do
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).and_call_original
    allow_any_instance_of(Omnibus::Ctl).to receive(:require).with(
      '/opt/testing-ctl/embedded/service/omnibus-ctl-ee/lib/geo/replication'
    ) do
      require_relative('../../files/gitlab-ctl-commands-ee/lib/geo/replication')
    end

    subject.load_file('files/gitlab-ctl-commands-ee/replicate_geo_database.rb')
  end

  it 'appends a geo replication command' do
    expect(subject.get_all_commands_hash).to include('replicate-geo-database')
  end

  describe "#replicate_geo_database" do
    it 'executes the geo replication command' do
      stub_command_arguments(required_arguments)

      expect(Geo::Replication).to receive(:new).and_call_original
        .with(subject, hash_including(host: 'gitlab-primary.geo',
                                      slot_name: 'gitlab_primary_geo'))

      expect_any_instance_of(Geo::Replication).to receive(:execute)

      replicate_geo_database
    end

    it 'applies defaults to optional arguments' do
      stub_command_arguments(required_arguments)

      expect(Geo::Replication).to receive(:new).and_call_original
        .with(subject, hash_including(host: 'gitlab-primary.geo',
                                      slot_name: 'gitlab_primary_geo',
                                      user: 'gitlab_replicator',
                                      port: 5432,
                                      password: nil,
                                      now: false,
                                      force: false,
                                      skip_backup: false,
                                      skip_replication_slot: false,
                                      backup_timeout: 1800,
                                      sslmode: 'verify-ca',
                                      sslcompression: 0,
                                      recovery_target_timeline: 'latest',
                                      db_name: 'gitlabhq_production'))

      expect_any_instance_of(Geo::Replication).to receive(:execute)

      replicate_geo_database
    end

    it 'requires the host argument' do
      stub_command_arguments(%w(--slot-name=gitlab_primary_geo))

      expect(Geo::Replication).not_to receive(:new)

      # Important to catch this SystemExit or else RSpec exits
      expect { subject.replicate_geo_database }.to raise_error(SystemExit).and(
        output(/missing argument: host/).to_stdout
      )
    end

    it 'requires the slot-name argument' do
      stub_command_arguments(%w(--host=gitlab-primary.geo))

      expect(Geo::Replication).not_to receive(:new)

      # Important to catch this SystemExit or else RSpec exits
      expect { subject.replicate_geo_database }.to raise_error(SystemExit).and(
        output(/missing argument: --slot-name/).to_stdout
      )
    end

    context 'with SSL compression enabled' do
      it 'enables SSL compression' do
        stub_command_arguments(
          required_arguments +
            %w(--sslmode=disable
               --sslcompression=1
               --no-wait))

        expect(Geo::Replication).to receive(:new).and_call_original
          .with(subject, hash_including(host: 'gitlab-primary.geo',
                                        slot_name: 'gitlab_primary_geo',
                                        sslmode: 'disable',
                                        sslcompression: 1,
                                        now: true))

        expect_any_instance_of(Geo::Replication).to receive(:execute)

        replicate_geo_database
      end
    end

    context 'with db_name specified' do
      it 'sets the db_name option' do
        stub_command_arguments(
          required_arguments +
            %w(--db-name=custom_db_name))

        expect(Geo::Replication).to receive(:new).and_call_original
          .with(subject, hash_including(host: 'gitlab-primary.geo',
                                        slot_name: 'gitlab_primary_geo',
                                        db_name: 'custom_db_name'))

        expect_any_instance_of(Geo::Replication).to receive(:execute)

        replicate_geo_database
      end
    end
  end

  def stub_command_arguments(arguments)
    expect_any_instance_of(Omnibus::Ctl::GeoReplicationCommand)
      .to receive(:arguments).and_return(arguments)
  end

  def replicate_geo_database
    # GeoReplicationCommand is designed to `exit 1` when there is a problem
    # during option parsing. Tests that trigger this exit will also silently
    # exit RSpec immediately, *and* they will *not* fail.
    #
    # So if a test expects a successful call, we *must* catch at least
    # SystemExit for the test to be valid. And since other errors are always
    # possible, and should also fail the test, we don't need to specify
    # SystemExit here.
    #
    # In short, this is necessary for a failable test.
    expect { subject.replicate_geo_database }.not_to raise_error
  end
end
