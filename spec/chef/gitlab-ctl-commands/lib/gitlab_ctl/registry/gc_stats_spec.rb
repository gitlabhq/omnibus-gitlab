require 'optparse'

require_relative '../../../../../../files/gitlab-ctl-commands/lib/gitlab_ctl/registry/gc_stats'

RSpec.describe GitlabCtl::Registry::GcStats do
  describe '.parse_options!' do
    before do
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
      allow(Kernel).to receive(:puts)
    end

    it 'throws an error when unknown option is specified' do
      expect { GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats --unknown), OptionParser.new, {}) }.to raise_error(OptionParser::InvalidOption, /unknown/)
    end

    it 'parses format option correctly with json' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -f json), OptionParser.new, options)

      expect(options[:format]).to eq('json')
      expect(options[:format_flag]).to eq('--format')
    end

    it 'parses format option correctly with text' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -f text), OptionParser.new, options)

      expect(options[:format]).to eq('text')
      expect(options[:format_flag]).to eq('--format')
    end

    it 'throws an error when format is invalid' do
      expect { GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -f xml), OptionParser.new, {}) }.to raise_error(OptionParser::InvalidArgument, /Invalid format/)
    end

    it 'parses limit option correctly' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -l 5), OptionParser.new, options)

      expect(options[:limit]).to eq('5')
      expect(options[:limit_flag]).to eq('--limit')
    end

    it 'parses both format and limit options correctly' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -f json -l 10), OptionParser.new, options)

      expect(options[:format]).to eq('json')
      expect(options[:format_flag]).to eq('--format')
      expect(options[:limit]).to eq('10')
      expect(options[:limit_flag]).to eq('--limit')
    end

    it 'sets needs_stop to false' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats), OptionParser.new, options)

      expect(options[:needs_stop]).to eq(false)
    end

    it 'sets needs_read_only to false' do
      options = {}
      GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats), OptionParser.new, options)

      expect(options[:needs_read_only]).to eq(false)
    end

    it 'returns nil when gc-stats is not in args' do
      options = {}
      result = GitlabCtl::Registry::GcStats.parse_options!(%w(other-command), OptionParser.new, options)

      expect(result).to be_nil
    end

    it 'exits when help option is specified' do
      expect { GitlabCtl::Registry::GcStats.parse_options!(%w(gc-stats -h), OptionParser.new, {}) }.to raise_error(/Kernel.exit\(0\)/)
    end
  end
end
