require 'spec_helper'
require 'optparse'

require_relative('../../../files/gitlab-ctl-commands/lib/praefect')

RSpec.describe Praefect do
  describe '.parse_options!' do
    before do
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    it 'throws an error when command is not specified' do
      expect { Praefect.parse_options!(%w(praefect)) }.to raise_error(OptionParser::ParseError, /Praefect command is not specified/)
    end

    it 'throws an error when unknown command is specified' do
      expect { Praefect.parse_options!(%w(praefect unknown-command)) }.to raise_error(OptionParser::ParseError, /Unknown Praefect command: unknown-command/)
    end

    it 'throws an error when unknown option is specified' do
      expect { Praefect.parse_options!(%w(praefect remove-repository --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
    end

    it 'throws an error when an argument for --virtual-storage-name is not specified' do
      expect { Praefect.parse_options!(%w(praefect remove-repository --virtual-storage-name)) }.to raise_error(OptionParser::MissingArgument, /virtual-storage-name/)
    end

    it 'throws an error when --virtual-storage-name is not specified' do
      expect { Praefect.parse_options!(%w(praefect remove-repository)) }.to raise_error(OptionParser::ParseError, /Option --virtual-storage-name must be specified/)
    end

    it 'throws an error when an argument for --repository-relative-path is not specified' do
      expect { Praefect.parse_options!(%w(praefect remove-repository --repository-relative-path)) }.to raise_error(OptionParser::MissingArgument, /repository-relative-path/)
    end

    it 'throws an error when --repository-relative-path is not specified' do
      expect { Praefect.parse_options!(%w(praefect remove-repository --virtual-storage-name name)) }.to raise_error(OptionParser::ParseError, /Option --repository-relative-path must be specified/)
    end

    it 'successfully parses correct params' do
      expected_options = { command: 'remove-repository', virtual_storage_name: 'name', repository_relative_path: 'path' }
      expect(Praefect.parse_options!(%w(praefect remove-repository --virtual-storage-name name --repository-relative-path path))).to eq(expected_options)
    end

    context 'when help option is passed' do
      it 'shows help message and exit for global help option' do
        expect(Kernel).to receive(:puts) do |msg|
          expect(msg.to_s).to match(/gitlab-ctl praefect command/)
        end

        expect { Praefect.parse_options!(%w(praefect -h)) }.to raise_error('Kernel.exit(0)')
      end

      ['remove-repository'].each do |cmd|
        it "shows help message and exit for #{cmd} help option" do
          expect(Kernel).to receive(:puts) do |msg|
            expect(msg.to_s).to match(/gitlab-ctl praefect remove-repository/)
          end

          expect { Praefect.parse_options!(%W(praefect #{cmd} -h)) }.to raise_error('Kernel.exit(0)')
        end
      end
    end
  end

  describe '#execute' do
    context 'when package is not installed correctly' do
      it 'aborts the execution if a path does not exit' do
        allow(File).to receive(:exists?).twice.and_return(false)
        expect(Kernel).to receive(:abort).and_raise('aborted')

        expect { Praefect.execute({}) }.to raise_error('aborted')
      end
    end

    it 'executes the command' do
      allow(File).to receive(:exist?).and_return(true)
      expect(Kernel).not_to receive(:abort)

      expect(Kernel).to receive(:system).with(
        Praefect::EXEC_PATH, '-config', 'dir/config.toml', 'cmd',
        '-virtual-storage', 'storage-name', '-repository', 'repository-path'
      ).and_return('result!')
      expect(Kernel).not_to receive(:exit!)

      options = {
        virtual_storage_name: 'storage-name',
        repository_relative_path: 'repository-path',
        command: 'cmd',
        dir: 'dir'
      }
      Praefect.execute(options)
    end
  end
end
