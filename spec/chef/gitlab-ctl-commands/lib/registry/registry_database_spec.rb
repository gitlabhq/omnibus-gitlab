require 'optparse'
require_relative('../../../../../files/gitlab-ctl-commands/lib/registry/registry_database')

RSpec.describe RegistryDatabase do
  describe '.parse_options!' do
    let(:migrate_options) { { subcommand: 'up' } }
    let(:ctl) {}

    before do
      allow(Migrate).to receive(:parse_options!).and_return(:migrate_options)
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    shared_examples 'unknown option is specified' do
      it 'throws an error' do
        expect { RegistryDatabase.parse_options!(ctl, %W(registry-database #{command} --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    it 'throws an error when command is not specified' do
      expect { RegistryDatabase.parse_options!(ctl, %w(registry-database)) }.to raise_error(OptionParser::ParseError, /registry-database command is not specified./)
    end

    it 'throws an error when unknown command is specified' do
      expect { RegistryDatabase.parse_options!(ctl, %w(registry-database unknown-subcommand)) }.to raise_error(OptionParser::ParseError, /Unknown registry-database command: unknown-subcommand/)
    end

    shared_examples 'parses command options' do
      it 'throws an error when an unknown option is specified' do
        expect { RegistryDatabase.parse_options!(ctl, %W(registry-database #{command} --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    context 'when command is migrate' do
      let(:command) { 'migrate' }

      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses command options'

      it 'parses subcommand correctly' do
        received = RegistryDatabase.parse_options!(ctl, %W(registry-database #{command}))
        expect(received).to have_key(:command)
      end
    end

    context 'when command is import' do
      let(:command) { 'import' }

      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses command options'
    end
  end
end
