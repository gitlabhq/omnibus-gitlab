require 'spec_helper'
require 'optparse'

require_relative('../../../../files/gitlab-ctl-commands/lib/praefect')

RSpec.describe Praefect do
  describe '.parse_options!' do
    before do
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    shared_examples 'unknown option is specified' do
      it 'throws an error' do
        expect { Praefect.parse_options!(%W(praefect #{command} --unknown)) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    it 'throws an error when command is not specified' do
      expect { Praefect.parse_options!(%w(praefect)) }.to raise_error(OptionParser::ParseError, /Praefect command is not specified/)
    end

    it 'throws an error when unknown command is specified' do
      expect { Praefect.parse_options!(%w(praefect unknown-command)) }.to raise_error(OptionParser::ParseError, /Unknown Praefect command: unknown-command/)
    end

    shared_examples 'parses repository options' do
      it 'throws an error when an argument for --virtual-storage-name is not specified' do
        expect { Praefect.parse_options!(%W(praefect #{command} --dir dir --virtual-storage-name)) }.to raise_error(OptionParser::MissingArgument, /virtual-storage-name/)
      end

      it 'throws an error when --virtual-storage-name is not specified' do
        expect { Praefect.parse_options!(%W(praefect #{command} --dir dir)) }.to raise_error(OptionParser::ParseError, /Option --virtual-storage-name must be specified/)
      end

      it 'throws an error when an argument for --repository-relative-path is not specified' do
        expect { Praefect.parse_options!(%W(praefect #{command} --dir dir --repository-relative-path)) }.to raise_error(OptionParser::MissingArgument, /repository-relative-path/)
      end

      it 'throws an error when --repository-relative-path is not specified' do
        expect { Praefect.parse_options!(%W(praefect #{command} --dir dir --virtual-storage-name name)) }.to raise_error(OptionParser::ParseError, /Option --repository-relative-path must be specified/)
      end

      it 'successfully parses correct params' do
        expected_options = { command: command, dir: 'dir', virtual_storage_name: 'name', repository_relative_path: 'path' }

        expect(Praefect.parse_options!(%W(praefect #{command} --dir dir --virtual-storage-name name --repository-relative-path path))).to eq(expected_options)
      end
    end

    context 'when command is remove-repository' do
      let(:command) { 'remove-repository' }

      it_behaves_like 'parses repository options'
      it_behaves_like 'unknown option is specified'

      it 'successfully parses apply' do
        expect(Praefect.parse_options!(%W(praefect #{command}
                                          --dir dir
                                          --virtual-storage-name name
                                          --repository-relative-path path
                                          --apply))).to include(apply: true)

        expect(Praefect.parse_options!(%W(praefect #{command}
                                          --dir dir
                                          --virtual-storage-name name
                                          --repository-relative-path path
                                          --apply something))).to include(apply: true)

        expect(Praefect.parse_options!(%W(praefect #{command}
                                          --dir dir
                                          --virtual-storage-name name
                                          --repository-relative-path path))).not_to include(:apply)
      end
    end

    context 'when command is check' do
      let(:command) { 'check' }

      it_behaves_like 'unknown option is specified'
    end

    context 'when command is track-repository' do
      let(:command) { 'track-repository' }

      it_behaves_like 'parses repository options'
      it_behaves_like 'unknown option is specified'

      it 'successfully parses authoritative-storage' do
        expected_options = { command: command,
                             dir: 'dir',
                             virtual_storage_name: 'name',
                             repository_relative_path: 'path',
                             authoritative_storage: 'storage-1',
                             replicate_immediately: true }

        expect(Praefect.parse_options!(%W(praefect #{command}
                                          --dir dir
                                          --virtual-storage-name name
                                          --repository-relative-path path
                                          --authoritative-storage storage-1
                                          --replicate-immediately))).to eq(expected_options)
      end
    end

    context 'when help option is passed' do
      it 'shows help message and exit for global help option' do
        expect(Kernel).to receive(:puts) do |msg|
          expect(msg.to_s).to match(/gitlab-ctl praefect command/)
        end

        expect { Praefect.parse_options!(%w(praefect -h)) }.to raise_error('Kernel.exit(0)')
      end

      ['remove-repository', 'track-repository'].each do |cmd|
        it "shows help message and exit for #{cmd} help option" do
          expect(Kernel).to receive(:puts) do |msg|
            expect(msg.to_s).to match(/gitlab-ctl praefect #{cmd}/)
          end

          expect { Praefect.parse_options!(%W(praefect #{cmd} -h)) }.to raise_error('Kernel.exit(0)')
        end
      end
    end
  end

  describe '#execute' do
    let(:repository_options) { { virtual_storage_name: 'storage-name', repository_relative_path: 'repository-path' } }

    context 'when package is not installed correctly' do
      it 'aborts the execution if a path does not exit' do
        allow(File).to receive(:exists?).twice.and_return(false)
        expect(Kernel).to receive(:abort).and_raise('aborted')

        expect { Praefect.execute({}) }.to raise_error('aborted')
      end
    end

    shared_examples 'executes the command' do
      it 'successfully executes' do
        allow(File).to receive(:exist?).and_return(true)
        expect(Kernel).not_to receive(:abort)
        args = [
          Praefect::EXEC_PATH, '-config', 'dir/config.toml', command,
        ]

        args += command_args

        expect(Kernel).to receive(:system).with(*args).and_return('result!')
        expect(Kernel).not_to receive(:exit!)

        common_options = {
          command: command,
          dir: 'dir'
        }

        Praefect.execute(common_options.merge(command_options))
      end
    end

    context 'check command' do
      let(:command) { 'check' }
      let(:command_args) { [] }
      let(:command_options) { {} }

      it_behaves_like 'executes the command'
    end

    context 'remove-repository command' do
      let(:command) { 'list-untracked-repositories' }
      let(:command_args) { [] }
      let(:command_options) { {} }

      it_behaves_like 'executes the command'
    end

    context 'repository commands' do
      let(:command_args) { ['-virtual-storage', 'storage-name', '-repository', 'repository-path'] }
      let(:command_options) { repository_options }

      context 'remove-repository command' do
        let(:command) { 'remove-repository' }

        it_behaves_like 'executes the command'
      end

      context 'track-repository command' do
        let(:command) { 'track-repository' }
        let(:command_args) { ['-virtual-storage', 'storage-name', '-repository', 'repository-path', '-authoritative-storage', 'storage-1'] }
        let(:command_options) { repository_options.merge(authoritative_storage: 'storage-1') }

        it_behaves_like 'executes the command'

        context 'with replicate-immediately' do
          let(:command_args) do
            ['-virtual-storage', 'storage-name',
             '-repository', 'repository-path',
             '-authoritative-storage', 'storage-1',
             '-replicate-immediately']
          end
          let(:command_options) { repository_options.merge(authoritative_storage: 'storage-1', replicate_immediately: true) }

          it_behaves_like 'executes the command'
        end
      end
    end
  end
end
