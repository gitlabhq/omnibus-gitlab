$LOAD_PATH << File.join(__dir__, '../../../../../../files/gitlab-ctl-commands/lib')
require 'gitlab_ctl'
require 'optparse'

require_relative '../../../../../../files/gitlab-ctl-commands/lib/gitlab_ctl/registry/database'

RSpec.describe GitlabCtl::Registry::Database do
  describe '.parse_options!' do
    let(:migrate_options) { { subcommand: 'up' } }
    let(:ctl) {}

    before do
      allow(GitlabCtl::Registry::Migrate).to receive(:parse_options!).and_return(:migrate_options)
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    shared_examples 'unknown option is specified' do
      it 'throws an error' do
        expect { GitlabCtl::Registry::Database.parse_options!(ctl, %W(registry-database #{command} --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    it 'throws an error when command is not specified' do
      expect { GitlabCtl::Registry::Database.parse_options!(ctl, %w(registry-database)) }.to raise_error(OptionParser::ParseError, /registry-database command is not specified./)
    end

    it 'throws an error when unknown command is specified' do
      expect { GitlabCtl::Registry::Database.parse_options!(ctl, %w(registry-database unknown-subcommand)) }.to raise_error(OptionParser::ParseError, /Unknown registry-database command: unknown-subcommand/)
    end

    shared_examples 'parses command options' do
      it 'throws an error when an unknown option is specified' do
        expect { GitlabCtl::Registry::Database.parse_options!(ctl, %W(registry-database #{command} --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    context 'when command is migrate' do
      let(:command) { 'migrate' }

      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses command options'

      it 'parses subcommand correctly' do
        received = GitlabCtl::Registry::Database.parse_options!(ctl, %W(registry-database #{command}))
        expect(received).to have_key(:command)
      end
    end

    context 'when command is import' do
      let(:command) { 'import' }

      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses command options'
    end
  end

  describe '.registry_dir' do
    context 'when public attributes contain registry dir' do
      before do
        allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({ 'registry' => { 'dir' => '/custom/registry' } })
      end

      it 'returns the configured registry directory' do
        expect(described_class.registry_dir).to eq('/custom/registry')
      end
    end

    context 'when public attributes are empty' do
      before do
        allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({})
      end

      it 'returns the default registry directory' do
        expect(described_class.registry_dir).to eq('/var/opt/gitlab/registry')
      end
    end

    context 'when public attributes file does not exist' do
      before do
        allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_raise(GitlabCtl::Errors::NodeError, "Node attributes JSON file not found")
      end

      it 'returns the default registry directory' do
        expect(described_class.registry_dir).to eq('/var/opt/gitlab/registry')
      end
    end
  end

  describe '.execute' do
    context "when service is disabled" do
      before do
        allow(described_class).to receive(:registry_dir).and_return('/var/opt/gitlab/registry')
        allow(described_class).to receive(:enabled?).and_return(false)
        allow(described_class).to receive(:log)
      end

      it 'changes to the registry directory before executing' do
        expect(Dir).to receive(:chdir).with('/var/opt/gitlab/registry')
        described_class.execute({})
      end
    end
  end

  describe '.set_command' do
    let(:options) { { command: 'migrate', subcommand: 'up' } }
    let(:expected_base_command) do
      [
        '/opt/gitlab/embedded/bin/registry',
        'database',
        'migrate',
        'up',
        '/var/opt/gitlab/registry/config.yml'
      ]
    end

    before do
      allow(described_class).to receive(:continue?)
      # Mock Etc.getpwuid to return root user
      allow(Etc).to receive(:getpwuid).and_return(double(name: 'root'))
    end

    context 'when running as root' do
      context 'with default registry user configuration' do
        before do
          allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({})
        end

        it 'applies privilege drop using chpst' do
          result = described_class.set_command(options)
          expected_command = [
            '/opt/gitlab/embedded/bin/chpst',
            '-u', 'registry:registry'
          ] + expected_base_command

          expect(result).to eq(expected_command)
        end
      end

      context 'with custom registry user configuration' do
        before do
          allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(
            {
              'registry' => {
                'username' => 'custom-registry',
                'group' => 'custom-group'
              }
            }
          )
        end

        it 'applies privilege drop using custom user and group' do
          result = described_class.set_command(options)
          expected_command = [
            '/opt/gitlab/embedded/bin/chpst',
            '-u', 'custom-registry:custom-group'
          ] + expected_base_command

          expect(result).to eq(expected_command)
        end
      end
    end

    context 'when running as registry user' do
      before do
        # Mock Etc.getpwuid to return registry user
        allow(Etc).to receive(:getpwuid).and_return(double(name: 'registry'))
        allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({})
      end

      it 'does not apply privilege drop' do
        result = described_class.set_command(options)
        expect(result).to eq(expected_base_command)
        expect(result).not_to include('/opt/gitlab/embedded/bin/chpst')
      end
    end
  end
end
