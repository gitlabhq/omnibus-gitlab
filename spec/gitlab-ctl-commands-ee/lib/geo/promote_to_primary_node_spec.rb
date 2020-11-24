require 'spec_helper'
require 'fileutils'
require 'geo/promote_to_primary_node'
require 'geo/promote_db'
require 'geo/promotion_preflight_checks'
require 'gitlab_ctl/util'

RSpec.describe Geo::PromoteToPrimaryNode, '#execute' do
  let(:options) { { skip_preflight_checks: true } }

  let(:instance) { double(base_path: '/opt/gitlab/embedded', data_path: '/var/opt/gitlab/postgresql/data') }

  subject(:command) { described_class.new(instance, options) }

  let(:config_path) { Dir.mktmpdir }
  let(:gitlab_config_path) { File.join(config_path, 'gitlab.rb') }

  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)

    allow(command).to receive(:run_command).with(any_args)
  end

  after do
    FileUtils.rm_rf(config_path)
  end

  describe '#promote_postgresql_to_primary' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:toggle_geo_roles).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    it 'promotes the database' do
      expect_any_instance_of(Geo::PromoteDb).to receive(:execute)

      command.execute
    end
  end

  describe '#run_preflight_checks' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:toggle_geo_roles).and_return(true)
      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    context 'when `--skip-preflight-checks` is passed' do
      it 'does not run execute promotion preflight checks' do
        expect_any_instance_of(Geo::PromotionPreflightChecks).not_to receive(:execute)

        command.execute
      end
    end

    context 'when `--skip-preflight-checks` is not passed' do
      let(:options) { { confirm_primary_is_down: true } }

      before do
        allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
          :execute).and_return(true)
      end

      it 'runs preflight checks' do
        expect_any_instance_of(Geo::PromotionPreflightChecks).to receive(:execute)

        command.execute
      end

      it 'passes given options to preflight checks command' do
        expect(Geo::PromotionPreflightChecks).to receive(:new).with(
          '/opt/gitlab/embedded', options).and_call_original

        command.execute
      end
    end
  end

  describe '#toggle_geo_roles' do
    let(:gitlab_cluster_config_path) { File.join(config_path, 'gitlab-cluster.json') }

    before do
      stub_const('GitlabClusterHelper::CONFIG_PATH', config_path)
      stub_const('GitlabClusterHelper::JSON_FILE', gitlab_cluster_config_path)

      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:run_preflight_checks).and_return(true)
      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    context 'when the cluster configuration file does not exist' do
      it 'creates the file with the Geo primary role enabled and secondary role disabled' do
        command.execute

        expect(File.exist?(gitlab_cluster_config_path)).to eq(true)
        expect(read_file_content(gitlab_cluster_config_path)).to eq("primary" => true, "secondary" => false)
      end
    end

    context 'when the cluster configuration file exists' do
      it 'disables the Geo secondary role' do
        write_file_content(gitlab_cluster_config_path, primary: false, secondary: true)

        command.execute

        expect(read_file_content(gitlab_cluster_config_path)).to eq("primary" => true, "secondary" => false)
      end
    end

    def read_file_content(fullpath)
      JSON.parse(File.read(fullpath))
    end

    def write_file_content(fullpath, content)
      File.open(fullpath, 'w') do |f|
        f.write(content.to_json)
        f.chmod(0600)
      end
    end
  end

  context 'when preflight checks pass' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
        :execute).and_return(true)

      allow(command).to receive(:toggle_geo_roles).and_return(true)
      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)
    end

    context 'when running in force mode' do
      let(:options) { { force: true } }

      it 'does not ask for final confirmation' do
        expect { command.execute }.not_to output(
          /WARNING\: Secondary will now be promoted to primary./).to_stdout
      end
    end

    context 'when not running in force mode' do
      let(:options) { { force: false } }

      it 'asks for confirmation' do
        expect { command.execute }.to output(
          /WARNING\: Secondary will now be promoted to primary./).to_stdout
      end

      context 'when final confirmation is given' do
        it 'calls all the subcommands' do
          expect(command).to receive(:toggle_geo_roles)
          expect(command).to receive(:promote_postgresql_to_primary)
          expect(command).to receive(:reconfigure)
          expect(command).to receive(:promote_to_primary)
          expect(command).to receive(:success_message)

          command.execute
        end
      end
    end
  end

  context 'when preflight checks fail' do
    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      allow(STDIN).to receive(:gets).and_return('n')

      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)

      allow_any_instance_of(Geo::PromotionPreflightChecks).to receive(
        :execute).and_raise(SystemExit)
    end

    context 'when running in force mode' do
      let(:options) { { force: true } }

      it 'asks for confirmation' do
        expect { command.execute }.to output(
          /Are you sure you want to proceed?/
        ).to_stdout
      end

      it 'exits with 1 if user denies' do
        allow(STDIN).to receive(:gets).and_return('n')

        expect { command.execute }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'calls all the subcommands if user affirms' do
        allow(STDIN).to receive(:gets).and_return('y')

        is_expected.to receive(:toggle_geo_roles)
        is_expected.to receive(:promote_postgresql_to_primary)
        is_expected.to receive(:reconfigure)
        is_expected.to receive(:promote_to_primary)
        is_expected.to receive(:success_message)

        command.execute
      end
    end

    context 'when not running in force mode' do
      let(:options) { { force: false } }

      it 'exits with 1' do
        expect { command.execute }.to raise_error(SystemExit)
      end
    end
  end

  context 'when writing to the cluster configuration file fail' do
    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:run_preflight_checks).and_return(true)

      allow_any_instance_of(GitlabClusterHelper)
        .to receive(:write_to_file!).and_return(false)
    end

    it 'exits with 1' do
      expect { command.execute }.to raise_error(SystemExit)
    end
  end

  context 'when writing to the cluster configuration file succeed' do
    before do
      allow(STDIN).to receive(:gets).and_return('y')

      allow(command).to receive(:promote_postgresql_to_primary).and_return(true)
      allow(command).to receive(:reconfigure).and_return(true)
      allow(command).to receive(:promote_to_primary).and_return(true)
      allow(command).to receive(:success_message).and_return(true)

      allow_any_instance_of(GitlabClusterHelper)
        .to receive(:write_to_file!).and_return(true)
    end

    it 'calls all the subcommands' do
      expect(command).to receive(:promote_postgresql_to_primary)
      expect(command).to receive(:reconfigure)
      expect(command).to receive(:promote_to_primary)
      expect(command).to receive(:success_message)

      command.execute
    end
  end
end
