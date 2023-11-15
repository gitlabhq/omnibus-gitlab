require 'optparse'

require_relative('../../../../../files/gitlab-ctl-commands/lib/registry/migrate')

RSpec.describe Migrate do
  describe '.parse_options!' do
    before do
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    shared_examples 'unknown option is specified' do
      it 'throws an error' do
        expect { Migrate.parse_options!(%W(migrate #{command} --unknown), {}) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    it 'throws an error when subcommand is not specified' do
      expect { Migrate.parse_options!(%w(migrate), {}) }.to raise_error(OptionParser::ParseError, /migrate subcommand is not specified./)
    end

    it 'throws an error when unknown subcommand is specified' do
      expect { Migrate.parse_options!(%w(migrate unknown-subcommand), {}) }.to raise_error(OptionParser::ParseError, /Unknown migrate subcommand: unknown-subcommand/)
    end

    shared_examples 'parses subcommand options' do
      it 'throws an error when an unknown option is specified' do
        expect { Migrate.parse_options!(%W(migrate #{command} --unknown), {}) }.to raise_error(OptionParser::InvalidOption, /unknown/)
      end
    end

    shared_examples 'parses limit option' do
      it 'throws an error when --limit is not a number' do
        expect { Migrate.parse_options!(%W(migrate #{command} --limit not-a-number), {}) }.to raise_error(OptionParser::ParseError, /--limit option must be a positive number/)
      end

      it 'throws an error when --limit is a negative number' do
        expect { Migrate.parse_options!(%W(migrate #{command} --limit -5), {}) }.to raise_error(OptionParser::ParseError, /--limit option must be a positive number/)
      end

      it 'throws an error when --limit is zero' do
        expect { Migrate.parse_options!(%W(migrate #{command} --limit 0), {}) }.to raise_error(OptionParser::ParseError, /--limit option must be a positive number/)
      end
    end

    shared_examples 'parses dry_run option' do
      it 'parses dry-run correctly' do
        expected_options = { subcommand: command, dry_run: '-d' }

        expect(Migrate.parse_options!(%W(migrate #{command} -d), {})).to eq(expected_options)
      end
    end

    context 'when subcommand is up' do
      let(:command) { 'up' }

      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses subcommand options'
      it_behaves_like 'parses limit option'
      it_behaves_like 'parses dry_run option'

      it 'parses subcommand correctly' do
        expected_options = { subcommand: 'up', limit: '5', skip_post_deploy: '-s', needs_stop: true }

        expect(Migrate.parse_options!(%W(migrate #{command} -s -l 5), {})).to eq(expected_options)
      end
    end

    context 'when subcommand is down' do
      let(:command) { 'down' }

      it_behaves_like 'parses subcommand options'
      it_behaves_like 'unknown option is specified'
      it_behaves_like 'parses limit option'
      it_behaves_like 'parses dry_run option'

      it 'parses subcommand correctly' do
        expected_options = { subcommand: 'down', needs_stop: true }

        expect(Migrate.parse_options!(%W(migrate #{command}), {})).to eq(expected_options)
      end

      it 'parses subcommand correctly with options' do
        expected_options = { subcommand: 'down', force: '-f', limit: '10', needs_stop: true }

        expect(Migrate.parse_options!(%W(migrate #{command} -f -l 10), {})).to eq(expected_options)
      end
    end

    context 'when subcommand is status' do
      let(:command) { 'status' }

      it_behaves_like 'parses subcommand options'
      it_behaves_like 'unknown option is specified'

      it 'parses subcommand correctly' do
        expected_options = { subcommand: 'status', needs_stop: false }

        expect(Migrate.parse_options!(%W(migrate #{command}), {})).to eq(expected_options)
      end

      it 'parses subcommand correctly with options' do
        expected_options = { subcommand: 'status', skip_post_deploy: '-s', up_to_date: '-u', needs_stop: false }

        expect(Migrate.parse_options!(%W(migrate #{command} -s -u), {})).to eq(expected_options)
      end
    end

    context 'when subcommand is version' do
      let(:command) { 'version' }

      it_behaves_like 'parses subcommand options'
      it_behaves_like 'unknown option is specified'

      it 'parses subcommand correctly' do
        expected_options = { subcommand: 'version', needs_stop: false }

        expect(Migrate.parse_options!(%W(migrate #{command}), {})).to eq(expected_options)
      end
    end
  end
end
