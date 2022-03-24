require 'spec_helper'
require 'geo/promote'
require 'geo/promote_db'
require 'gitlab_ctl/util'

require_relative('../../../../../files/gitlab-ctl-commands-ee/lib/patroni')

RSpec.describe Geo::Promote, '#execute' do
  let(:base_path) { '/opt/gitlab/embedded' }
  let(:ctl) { double(base_path: base_path, data_path: '/var/opt/gitlab/postgresql/data') }
  let(:config_path) { Dir.mktmpdir }
  let(:gitlab_cluster_config_path) { File.join(config_path, 'gitlab-cluster.json') }
  let(:options) { { force: false } }

  subject(:command) { described_class.new(ctl, options) }

  before do
    stub_const('GitlabCluster::CONFIG_PATH', config_path)
    stub_const('GitlabCluster::JSON_FILE', gitlab_cluster_config_path)

    allow($stdin).to receive(:gets).and_return('y')
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)

    allow(ctl).to receive(:log).with(any_args)
    allow(ctl).to receive(:service_enabled?).and_return(false)
    allow(command).to receive(:run_command).with(any_args)
  end

  around do |example|
    example.run
  rescue SystemExit
  end

  after do
    FileUtils.rm_rf(config_path)
  end

  describe '#execute' do
    context 'when not running in force mode' do
      it 'asks for confirmation' do
        expect { command.execute }.to output(/Are you sure you want to proceed\?/).to_stdout
      end
    end

    context 'when running in force mode' do
      let(:options) { { force: true } }

      it 'does not ask for final confirmation' do
        expect { command.execute }.to_not output(/Are you sure you want to proceed\?/).to_stdout
      end
    end

    context 'when there are no services to promote' do
      before do
        allow(ctl).to receive(:service_enabled?).and_return(false)
      end

      it 'prints a message' do
        expect { command.execute }.to output(
          /No actions are required to promote this node./).to_stdout
      end

      it 'returns 0 as exit code' do
        expect { command.execute }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context 'when puma is enabled' do
      before do
        stub_service_enabled('puma')
      end

      shared_examples 'promote secondary site to primary site' do
        context 'on a primary node' do
          it 'does not try to promote the secondary site to primary site' do
            stub_primary_node

            allow(command).to receive(:run_reconfigure)
            allow(command).to receive(:restart_services)

            expect(command).not_to receive(:run_command).with("#{base_path}/bin/gitlab-rake geo:set_secondary_as_primary", live: true)

            command.execute
          end
        end

        context 'on a secondary node' do
          before do
            stub_secondary_node
            allow(command).to receive(:run_reconfigure)
          end

          it 'promotes the secondary site to primary site' do
            allow(command).to receive(:restart_services)

            expect(command).to receive(:run_command).with("#{base_path}/bin/gitlab-rake geo:set_secondary_as_primary", live: true).once.and_return(double(error?: false))

            command.execute
          end

          it 'restarts the puma service' do
            allow(command).to receive(:promote_to_primary)

            expect(ctl).to receive(:run_sv_command_for_service).with('restart', 'puma').once.and_return(double(zero?: true))

            command.execute
          end
        end

        context 'on a misconfigured node' do
          it 'aborts promotion with an error message' do
            stub_misconfigured_node

            expect { command.execute }.to output(/Unable to detect the role of this Geo node/).to_stdout
          end
        end
      end

      context 'on a single-server secondary site' do
        before do
          stub_single_server_secondary_site
        end

        it 'toggles the Geo primary/secondary roles' do
          allow(command).to receive(:run_reconfigure)
          allow(command).to receive(:promote_to_primary)
          allow(command).to receive(:restart_services)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq("primary" => true, "secondary" => false)
        end

        it 'runs reconfigure' do
          allow(command).to receive(:toggle_geo_services)
          allow(command).to receive(:promote_to_primary)
          allow(command).to receive(:restart_services)

          expect(ctl).to receive(:run_chef).with(reconfigure_cmd).once.and_return(double(success?: true))

          command.execute
        end

        include_examples 'promote secondary site to primary site'
      end

      context 'on a multiple-server secondary site' do
        before do
          stub_multiple_server_secondary_site
        end

        include_examples 'promote secondary site to primary site'

        it 'disables Geo secondary settings' do
          allow(command).to receive(:run_reconfigure)
          allow(command).to receive(:promote_to_primary)
          allow(command).to receive(:restart_services)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq("geo_secondary" => { "enable" => false })
        end

        it 'runs reconfigure' do
          allow(command).to receive(:promote_to_primary)
          allow(command).to receive(:restart_services)

          expect(ctl).to receive(:run_chef).with(reconfigure_cmd).once.and_return(double(success?: true))

          command.execute
        end
      end
    end

    context 'when gitaly is enabled' do
      before do
        stub_service_enabled('gitaly')
      end

      it 'restarts the gitaly service' do
        allow(command).to receive(:toggle_geo_services)
        allow(command).to receive(:promote_to_primary)
        allow(command).to receive(:run_reconfigure)

        expect(ctl).to receive(:run_sv_command_for_service).with('restart', 'gitaly').once.and_return(double(zero?: true))

        command.execute
      end
    end

    context 'when praefect is enabled' do
      before do
        stub_service_enabled('praefect')
      end

      it 'restarts the praefect service' do
        allow(command).to receive(:toggle_geo_services)
        allow(command).to receive(:promote_to_primary)
        allow(command).to receive(:run_reconfigure)

        expect(ctl).to receive(:run_sv_command_for_service).with('restart', 'praefect').once.and_return(double(zero?: true))

        command.execute
      end
    end

    context 'when workhorse is enabled' do
      before do
        stub_service_enabled('gitlab-workhorse')
      end

      it 'restarts the workhorse service' do
        allow(command).to receive(:toggle_geo_services)
        allow(command).to receive(:promote_to_primary)
        allow(command).to receive(:run_reconfigure)

        expect(ctl).to receive(:run_sv_command_for_service).with('restart', 'gitlab-workhorse').once.and_return(double(zero?: true))

        command.execute
      end
    end

    shared_examples 'single-server secondary site' do
      context 'on a single-server secondary site' do
        before do
          stub_single_server_secondary_site
        end

        it 'toggles the Geo primary/secondary roles' do
          allow(command).to receive(:run_reconfigure)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq("primary" => true, "secondary" => false)
        end

        it 'runs reconfigure' do
          expect(ctl).to receive(:run_chef).with(reconfigure_cmd).once.and_return(double(success?: true))

          command.execute
        end
      end
    end

    shared_examples 'multiple-server secondary site' do |settings|
      context 'on a multiple-server secondary site' do
        before do
          stub_multiple_server_secondary_site
        end

        it 'disables Geo secondary settings' do
          allow(command).to receive(:run_reconfigure)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq(settings)
        end
      end
    end

    context 'when sidekiq is enabled' do
      before do
        stub_service_enabled('sidekiq')
      end

      include_examples 'single-server secondary site'
      include_examples 'multiple-server secondary site', "geo_secondary" => { "enable" => false }
    end

    context 'when geo-logcursor is enabled' do
      before do
        allow(ctl).to receive(:service_enabled?).with('geo-logcursor').and_return(true)
      end

      include_examples 'single-server secondary site'
      include_examples 'multiple-server secondary site', "geo_logcursor" => { "enable" => false }
    end

    context 'when geo-postgresql is enabled' do
      before do
        allow(ctl).to receive(:service_enabled?).with('geo-postgresql').and_return(true)
      end

      include_examples 'single-server secondary site'
      include_examples 'multiple-server secondary site', "geo_postgresql" => { "enable" => false }
    end

    context 'when postgresql is enabled' do
      before do
        stub_service_enabled('postgresql')
      end

      context 'when PostgreSQL is in recovery mode' do
        before do
          stub_pg_is_in_recovery
        end

        it 'promotes database to begin read-write operations' do
          allow(command).to receive(:run_reconfigure)

          expect_any_instance_of(Geo::PromoteDb).to receive(:execute).once.and_return(true)

          command.execute
        end
      end

      context 'when PostgreSQL is not in recovery mode' do
        before do
          stub_pg_is_not_in_recovery
        end

        it 'does not promote the PostgreSQL database' do
          allow(command).to receive(:run_reconfigure)

          expect_any_instance_of(Geo::PromoteDb).not_to receive(:execute)

          command.execute
        end
      end

      it 'runs reconfigure' do
        allow(command).to receive(:promote_database)

        expect(ctl).to receive(:run_chef).with(reconfigure_cmd).once.and_return(double(success?: true))

        command.execute
      end
    end

    context 'when patroni is enabled' do
      before do
        stub_service_enabled('patroni')
      end

      shared_examples 'promotes a Patroni leader' do
        context 'when PostgreSQL is in recovery mode' do
          before do
            stub_pg_is_in_recovery
          end

          it 'promotes database to begin read-write operations' do
            allow(command).to receive(:disable_patroni_standby_cluster)
            allow(command).to receive(:run_reconfigure)

            expect_any_instance_of(Geo::PromoteDb).to receive(:execute).once.and_return(true)

            command.execute
          end
        end

        context 'when PostgreSQL is not in recovery mode' do
          before do
            stub_pg_is_not_in_recovery
          end

          it 'does not promote the PostgreSQL database' do
            allow(command).to receive(:disable_patroni_standby_cluster)
            allow(command).to receive(:run_reconfigure)

            expect_any_instance_of(Geo::PromoteDb).not_to receive(:execute)

            command.execute
          end
        end

        it 'disables Patroni Standby cluster settings' do
          allow(command).to receive(:promote_postgresql_read_write)
          allow(command).to receive(:run_reconfigure)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq("patroni" => { "standby_cluster" => { "enable" => false } })
        end

        it 'pauses Patroni, runs reconfigure and resume Patroni' do
          allow(command).to receive(:promote_postgresql_read_write)
          allow(command).to receive(:disable_patroni_standby_cluster)

          expect(command).to receive(:run_command).with(patroni_pause_cmd).twice.and_return(double(success?: true))
          expect(ctl).to receive(:run_chef).with(reconfigure_cmd).twice.and_return(double(success?: true))
          expect(command).to receive(:run_command).with(patroni_resume_cmd).twice.and_return(double(success?: true))

          command.execute
        end
      end

      context 'on a Patroni standby leader' do
        before do
          allow(Patroni::Client).to receive(:new).and_return(double(standby_leader?: true, leader?: false, replica?: false))
        end

        include_examples 'promotes a Patroni leader'
      end

      context 'on a Patroni leader' do
        before do
          allow(Patroni::Client).to receive(:new).and_return(double(standby_leader?: false, leader?: true, replica?: false))
        end

        include_examples 'promotes a Patroni leader'
      end

      context 'on a Patroni replica' do
        before do
          allow(Patroni::Client).to receive(:new).and_return(double(standby_leader?: false, leader?: false, replica?: true))
        end

        it 'does not promote the PostgreSQL database' do
          allow(command).to receive(:run_reconfigure)

          expect_any_instance_of(Geo::PromoteDb).not_to receive(:execute)

          command.execute
        end

        it 'disables Patroni Standby cluster settings' do
          allow(command).to receive(:promote_postgresql_read_write)
          allow(command).to receive(:run_reconfigure)

          command.execute

          expect(read_file_content(gitlab_cluster_config_path)).to eq("patroni" => { "standby_cluster" => { "enable" => false } })
        end

        it 'runs reconfigure' do
          allow(command).to receive(:promote_postgresql_read_write)
          allow(command).to receive(:disable_patroni_standby_cluster)

          expect(command).not_to receive(:run_command).with(patroni_pause_cmd)
          expect(ctl).to receive(:run_chef).with(reconfigure_cmd).twice.and_return(double(success?: true))
          expect(command).not_to receive(:run_command).with(patroni_resume_cmd)

          command.execute
        end
      end
    end

    context 'when promotion succeeds' do
      before do
        allow(command).to receive(:ask_for_confirmation)
        allow(command).to receive(:check_running_services)
        allow(command).to receive(:promote_database)
        allow(command).to receive(:toggle_geo_services)
        allow(command).to receive(:promote_to_primary)
        allow(command).to receive(:run_reconfigure)
        allow(command).to receive(:restart_services)
      end

      it 'prints a success message' do
        expect { command.execute }.to output(
          /You successfully promoted the current node! It might take some time to reload the services, and for the changes to take effect./).to_stdout
      end
    end

    let(:patroni_pause_cmd) { "#{base_path}/bin/gitlab-ctl patroni pause" }
    let(:patroni_resume_cmd) { "#{base_path}/bin/gitlab-ctl patroni resume" }
    let(:pg_is_in_recovery_cmd) { "#{base_path}/bin/gitlab-psql -c \"SELECT pg_is_in_recovery();\" -q -t" }
    let(:reconfigure_cmd) { "#{base_path}/embedded/cookbooks/dna.json" }

    def stub_service_enabled(service)
      allow(ctl).to receive(:service_enabled?).with(service).and_return(true)
    end

    def stub_primary_node
      allow(command).to receive(:run_command).with("#{base_path}/bin/gitlab-rake geo:site:role", live: true).and_return(double(error?: false, stdout: 'primary'))
    end

    def stub_secondary_node
      allow(command).to receive(:run_command).with("#{base_path}/bin/gitlab-rake geo:site:role", live: true).and_return(double(error?: false, stdout: 'secondary'))
    end

    def stub_misconfigured_node
      allow(command).to receive(:run_command).with("#{base_path}/bin/gitlab-rake geo:site:role", live: true).and_return(double(error?: true, stdout: 'misconfigured'))
    end

    def stub_single_server_secondary_site
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return('roles' => { 'geo-secondary' => { 'enable' => true } })
    end

    def stub_multiple_server_secondary_site
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return('roles' => {})
    end

    def stub_pg_is_in_recovery
      allow(command).to receive(:run_command).with(pg_is_in_recovery_cmd, anything).and_return(double(error?: false, stdout: 't'))
    end

    def stub_pg_is_not_in_recovery
      allow(command).to receive(:run_command).with(pg_is_in_recovery_cmd, anything).and_return(double(error?: false, stdout: 'f'))
    end

    def read_file_content(fullpath)
      JSON.parse(File.read(fullpath))
    end
  end
end
