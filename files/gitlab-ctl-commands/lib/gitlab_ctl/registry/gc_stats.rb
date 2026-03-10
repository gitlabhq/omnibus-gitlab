require 'optparse'

module GitlabCtl
  module Registry
    module GcStats
      CMD_NAME = 'gc-stats'.freeze

      USAGE = <<~EOS.freeze
      Show online garbage collection health statistics

      Usage:
        gitlab-ctl registry-database gc-stats [options]

      Options:
        -f, --format FORMAT   Output format: 'text' (default) or 'json'
        -l, --limit INT       Maximum number of sample entries to display per category, pass 0 to show all entries (default: 10)
        -h, --help            Help for gc-stats
      EOS

      def self.parse_options!(args, parser, options)
        return unless args.include? CMD_NAME

        loop do
          break if args.shift == CMD_NAME
        end

        parser.on('-h', '--help', 'Usage help') do
          Kernel.puts USAGE
          Kernel.exit 0
        end

        parser.on('-f', '--format FORMAT', 'Output format: text or json') do |format|
          raise OptionParser::InvalidArgument, "Invalid format '#{format}'. Must be 'text' or 'json'" unless %w[text json].include?(format)

          options[:format] = format
          options[:format_flag] = "--format"
        end

        parser.on('-l', '--limit LIMIT', 'Limit the number of sample items') do |limit|
          options[:limit] = limit
          options[:limit_flag] = "--limit"
        end

        parser.order!(args)

        options[:needs_stop] = false
        options[:needs_read_only] = false

        options
      end
    end
  end
end
